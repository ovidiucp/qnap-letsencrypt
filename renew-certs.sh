#! /bin/sh

# Store the contents of the directory containing the certificates. We
# use the filename and the timestamp when they were created, in the
# form filename@timestamp.

dir=$(dirname $0)
echo Script dir is $dir

old=$(cd /etc/config/apache/ssl; ls -alF --time-style="+%Y-%m-%d-%H-%M-%S" *.pem | awk '{printf "%s@%s\n", $7, $6}')

docker rm qnap-letsencrypt; \
(cd $dir; docker build -t qnap-letsencrypt:latest .) && \
docker run --name qnap-letsencrypt \
       -v $HOME/.acme.sh:/root/.acme.sh \
       -v /etc/config/apache/ssl:/etc/config/apache/ssl \
       -v /etc/stunnel:/etc/stunnel \
       --env-file $dir/config.txt \
       qnap-letsencrypt

new=$(cd /etc/config/apache/ssl; ls -alF --time-style="+%Y-%m-%d-%H-%M-%S" *.pem | awk '{printf "%s@%s\n", $7, $6}')

if [ "$new" != "$old" ]; then
    echo Rewriting /etc/stunnel/stunnel.pem
    mv /etc/stunnel/stunnel.pem /etc/stunnel/stunnel.pem.old
    cat /etc/config/apache/ssl/key.pem \
        /etc/config/apache/ssl/cert.pem \
        >/etc/stunnel/stunnel.pem

    echo Certificate has been renewed, restarting.
    /etc/init.d/stunnel.sh restart

    # Create certificates for the Plex server
    openssl pkcs12 \
	-export -out /etc/config/apache/ssl/cert.p12 \
	-certpbe AES-256-CBC \
	-keypbe AES-256-CBC \
	-macalg SHA256 \
	-inkey /etc/config/apache/ssl/key.pem \
	-in /etc/config/apache/ssl/cert.pem \
	-certfile /etc/config/apache/ssl/fullchain.pem \
	-passout pass:fS9C64w6Txne
    # Restart the plex Web Apache server so that it uses the new certificate. 
    /share/ZFS530_DATA/.qpkg/PlexMediaServer/plex.sh restart
fi
