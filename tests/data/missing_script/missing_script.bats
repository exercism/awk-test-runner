#!/usr/bin/env bash

bats_require_minimum_version 1.5.0

@test "say hello" {
  run -127 bash one_passing.sh
  [ "$status" -eq 0 ]
  [ "$output" == "Hello, World!" ]
}
