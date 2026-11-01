FROM ubuntu:26.04@sha256:6a06111c3b0a8600feadb270aec771dc239bf407b25625f93f44ab00e11f4d3c

# gawk  5.3.2
# jq   v1.8.1
# bats v1.13.0

RUN apt-get update                                                              && \
    apt-get install --assume-yes --no-install-recommends gawk jq bats locales   && \
    sed --in-place '/en_US.UTF-8/s/^# //g' /etc/locale.gen                      && \
    locale-gen                                                                  && \
    apt-get purge --auto-remove --assume-yes                                    && \
    apt-get clean                                                               && \
    rm --recursive --force /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /opt/test-runner
COPY . .
ENV BATS_RUN_SKIPPED=true
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
