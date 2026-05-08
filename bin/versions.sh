#!/usr/bin/env sh

# Build the Docker image
docker build --rm --tag exercism/awk-test-runner .

# Print tool versions inside Docker
docker run --rm -it --entrypoint /bin/bash exercism/awk-test-runner -c 'for i in awk bats bash jq; do "$i" --version | head -n1; done'
