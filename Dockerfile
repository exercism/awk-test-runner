FROM ubuntu:24.04

# Ubuntu 24.04 'noble numbat' gets us:
# gawk v5.2.1           https://launchpad.net/ubuntu/noble/+source/gawk
# jq   v1.7.1           https://launchpad.net/ubuntu/noble/+source/jq
# bats v1.10.0          https://launchpad.net/ubuntu/noble/+source/bats

RUN apt-get update                                                              && \
    apt-get install --assume-yes --no-install-recommends gawk jq bats locales   && \
    sed --in-place '/en_US.UTF-8/s/^# //g' /etc/locale.gen                      && \
    locale-gen                                                                  && \
    apt-get purge --auto-remove --assume-yes                                    && \
    apt-get clean                                                               && \
    rm --recursive --force /var/lib/apt/lists/*

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /opt/test-runner
COPY . .
ENV BATS_RUN_SKIPPED=true
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
