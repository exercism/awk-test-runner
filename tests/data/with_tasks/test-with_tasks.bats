#!/usr/bin/env bash

@test "say one" {
  ## task 1
  run bash with_tasks.sh one
  [ "$status" -eq 0 ]
  [ "$output" == "one" ]
}

@test "say two" {
  ## task 1
  run bash with_tasks.sh two
  [ "$status" -eq 0 ]
  [ "$output" == "two" ]
}

@test "say three" {
  ## task 2
  run bash with_tasks.sh three
  [ "$status" -eq 0 ]
  [ "$output" == "three" ]
}
