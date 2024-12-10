#! /bin/sh

# cd ~ovidiu/src/letsencrypt

# Store the contents of the directory containing the certificates. We
# use the filename and the timestamp when they were created, in the
# form filename@timestamp.

old=$(cd /etc/config/apache/ssl; ls -alF --time-style="+%Y-%m-%d-%H-%M-%S" *.pem | awk '{printf "%s@%s\n", $7, $6}')

docker rm qnap-letsencrypt; \
docker build -t qnap-letsencrypt:latest . && \
docker rm qnap-letsencrypt; \
docker run --name qnap-letsencrypt \
       -v $HOME/.acme.sh:/root/.acme.sh \
       -v /etc/config/apache/ssl:/etc/config/apache/ssl \
       --env-file config.txt \
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
fi
