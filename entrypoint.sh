#! /bin/sh

# Issues or renews $HOST's certificate from Let's Encrypt through acme.sh's
# DNS API, and installs it under /etc/config/apache/ssl. Never print the
# DNS API key: docker keeps this output in the container's log.

echo Email is $EMAIL

# acme.sh's own default authority is ZeroSSL; ZeroSSL left the DNS
# authorization pending with a day's retry-after, so name Let's Encrypt.
# DreamHost's DNS can take minutes to serve a new TXT record, past
# acme.sh's default wait, so wait 10 minutes before validation.
$HOME/.acme.sh/acme.sh \
    --issue \
    --server letsencrypt \
    --dns $DNSAPI \
    --dnssleep 600 \
    -d $HOST \
    --log

RESULT=$?

echo acme.sh finished with code: $RESULT

if [ $RESULT -eq 0 ]; then
    echo Certificate is new, copying to /etc/config/apache/ssl
    $HOME/.acme.sh/acme.sh \
        --install-cert -d $HOST \
        --cert-file /etc/config/apache/ssl/cert.pem \
        --key-file /etc/config/apache/ssl/key.pem \
        --fullchain-file /etc/config/apache/ssl/fullchain.pem
else
    echo
    echo Certificate has not been generated, not doing anything.
fi
