FROM ubuntu:24.04

# Ubuntu 24.04 'noble numbat' gets us:
# gawk v5.2.1           https://launchpad.net/ubuntu/noble/+source/gawk
# jq   v1.7.1           https://launchpad.net/ubuntu/noble/+source/jq
# bats v1.10.0          https://launchpad.net/ubuntu/noble/+source/bats

RUN apt-get update                    && \
    apt-get install -y gawk jq bats   && \
    apt-get purge --auto-remove -y    && \
    apt-get clean                     && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/test-runner
COPY . .
ENV BATS_RUN_SKIPPED=true
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
