#! /bin/sh

# Renews this NAS's certificate (entrypoint.sh, in a container) and, when
# the web server does not serve it yet, installs it for apache_proxys,
# QuTS hero's HTTPS front, and for Plex where Plex is installed.

# busybox cron's PATH lacks Container Station's docker.
CS=$(/sbin/getcfg container-station Install_Path -f /etc/config/qpkg.conf)
PATH=$CS/bin:$PATH
ACME_HOME=/share/homes/admin/.acme.sh
SSL=/etc/config/apache/ssl
ST=/etc/config/stunnel
dir=$(cd "$(dirname "$0")" && pwd)

docker rm -f qnap-letsencrypt >/dev/null 2>&1
# BuildKit's zfs snapshotter can lose a layer's mount on QuTS hero; the
# classic builder, else the image already built, still serves, and the
# entrypoint is mounted so its latest version runs either way.
(cd "$dir" && DOCKER_BUILDKIT=0 docker build -q -t qnap-letsencrypt:latest .) \
    || docker image inspect qnap-letsencrypt:latest >/dev/null 2>&1 || exit 1
docker run --rm --name qnap-letsencrypt \
    -v $ACME_HOME:/root/.acme.sh -v $SSL:$SSL \
    -v "$dir/entrypoint.sh:/entrypoint.sh:ro" \
    --env-file "$dir/config.txt" qnap-letsencrypt

fp() { openssl x509 -noout -fingerprint -sha256 -in "$1" 2>/dev/null; }
if [ "$(fp $SSL/cert.pem)" = "$(fp $ST/stunnel.pem)" ]; then
    echo The web server already has the current certificate.
    exit 0
fi
openssl x509 -checkend 86400 -noout -in $SSL/cert.pem \
    || { echo "cert.pem expires within a day: not installing"; exit 1; }
[ "$(openssl pkey -in $SSL/key.pem -pubout | sha256sum)" = \
  "$(openssl x509 -in $SSL/cert.pem -noout -pubkey | sha256sum)" ] \
    || { echo "key.pem does not match cert.pem: not installing"; exit 1; }

umask 077
chmod 600 $SSL/key.pem
# Apache reads the chain from SSLCertificateFile, so the key and the full
# chain together; a graceful reload then picks them up.
cat $SSL/key.pem $SSL/fullchain.pem > $ST/stunnel.pem.new || exit 1
cp -p $ST/stunnel.pem $ST/stunnel.pem.old
mv $ST/stunnel.pem.new $ST/stunnel.pem
if ! /usr/local/apache/bin/apache_proxys -t -f /etc/apache-sys-proxy-ssl.conf; then
    mv $ST/stunnel.pem.old $ST/stunnel.pem
    echo "apache_proxys config test failed: kept the old certificate"
    exit 1
fi
/etc/init.d/stunnel.sh reload
echo Installed the new certificate and reloaded the web server.

# Plex reads a PKCS#12 copy, whose password is in a root-only file.
PLEX=$(/sbin/getcfg PlexMediaServer Install_Path -f /etc/config/qpkg.conf)
PASS_FILE=/share/homes/admin/.plex-p12-pass
if [ -n "$PLEX" ] && [ -x "$PLEX/plex.sh" ] && [ -r $PASS_FILE ]; then
    openssl pkcs12 \
        -export -out $SSL/cert.p12 \
        -certpbe AES-256-CBC \
        -keypbe AES-256-CBC \
        -macalg SHA256 \
        -inkey $SSL/key.pem \
        -in $SSL/cert.pem \
        -certfile $SSL/fullchain.pem \
        -passout file:$PASS_FILE
    "$PLEX/plex.sh" restart
fi
