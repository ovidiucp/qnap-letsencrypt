#! /bin/sh

# cd ~ovidiu/src/letsencrypt

# Store the contents of the directory containing the certificates. We
# use the filename and the timestamp when they were created, in the
# form filename@timestamp.

old=$(cd /etc/config/apache/ssl; ls -alF --time-style="+%Y-%m-%d-%H-%M-%S" *.pem | awk '{printf "%s@%s\n", $7, $6}')

docker build -t qnap-letsencrypt:latest . && \
docker rm qnap-letsencrypt; \
docker run --name qnap-letsencrypt \
       -v /acme:/root \
       -v /etc/config/apache/ssl:/etc/config/apache/ssl \
       --env-file config.txt \
       qnap-letsencrypt

new=$(cd /etc/config/apache/ssl; ls -alF --time-style="+%Y-%m-%d-%H-%M-%S" *.pem | awk '{printf "%s@%s\n", $7, $6}')

if [ "$new" != "$old" ]; then
    echo Certificate has been renewed, restarting.
    /etc/init.d/stunnel.sh restart
fi
