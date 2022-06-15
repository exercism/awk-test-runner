FROM ubuntu:22.04

# Specifically use bats 1.7.0
# Remove git when we're done with it.
# Test runner needs jq.

RUN apt-get update                                   && \
    apt-get install -y gawk jq git                   && \
    git clone https://github.com/bats-core/bats-core && \
    cd bats-core                                     && \
    git checkout v1.7.0                              && \
    bash ./install.sh /usr/local                     && \
    cd ..                                            && \
    rm -rf ./bats-core                               && \
    apt-get remove -y git                            && \
    apt-get purge --auto-remove -y                   && \
    apt-get clean                                    && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/test-runner
COPY . .
ENV BATS_RUN_SKIPPED=true
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
