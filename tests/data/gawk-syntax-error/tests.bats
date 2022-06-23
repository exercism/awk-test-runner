#!/usr/bin/env bats
load bats-extra

@test "awk syntax error" {
    run gawk -f script.awk < /dev/null
    assert_success
}
