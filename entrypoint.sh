#! /bin/sh

echo Email is $EMAIL
echo Dreamhost API key: $DH_API_KEY

echo
echo HOME is $HOME. Contents of $HOME
ls -alF $HOME

echo
echo Contents of /etc/config/apache/ssl:
ls -alF /etc/config/apache/ssl

echo Contents of $HOME/.acme.sh/
ls -alF $HOME/.acme.sh/

# Pass --test to use it with the staging servers.

$HOME/.acme.sh/acme.sh \
    --issue \
    --dns $DNSAPI \
    -d $HOST \
    --debug

RESULT=$?

echo acme.sh finished with code: $RESULT

if [ $RESULT -eq 0 ]; then
    echo Certificate is new, copying to /etc/config/apache/ssl
    $HOME/.acme.sh/acme.sh \
        --install-cert -d $HOST \
        --cert-file /etc/config/apache/ssl/cert.pem \
        --key-file /etc/config/apache/ssl/key.pem \
        --fullchain-file /etc/config/apache/ssl/fullchain.pem

    echo
    echo After certificate generation, contents of /etc/config/apache/ssl:
    ls -alF /etc/config/apache/ssl
else
    echo
    echo Certificate has not been generated, not doing anything.
fi
