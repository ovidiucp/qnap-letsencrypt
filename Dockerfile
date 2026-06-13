FROM ubuntu:24.04

RUN (apt-get update; \
    apt-get install -y curl ; \
    )

ADD entrypoint.sh /entrypoint.sh

ENV EMAIL=youremail@mydomain.com

RUN curl https://get.acme.sh | sh -s email=$EMAIL

ENTRYPOINT ["/entrypoint.sh" ]
