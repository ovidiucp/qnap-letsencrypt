FROM ubuntu:22.04
MAINTAINER Ovidiu Predescu <ovidiu@jollyturns.com>

RUN (apt-get update; \
    apt-get install -y curl cron; \
    )

ADD entrypoint.sh /entrypoint.sh

ENV EMAIL=youremail@mydomain.com

RUN curl https://get.acme.sh | sh -s email=$EMAIL

ENTRYPOINT ["/entrypoint.sh" ]
