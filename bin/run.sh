#!/usr/bin/env bash
# shellcheck disable=SC2164,SC2103

# Arguments:
# $1: exercise slug
# $2: path to solution directory
# $3: path to output directory
#
# Example:
# ./run.sh two-fer path/to/two-fer path/to/output/directory
# ./run.sh two-fer twofer output
#
# First runs the tests with bats and saves the TAP output,
# then parses that TAP file to produce the JSON file.

# the version of the test-runner interface:
# https://github.com/exercism/docs/blob/50bcff91e8871f08b9a69b76ccbd45e5a90493dd/building/tooling/test-runners/interface.md
INTERFACE_VERSION=2

main() {
    echo "Running exercise tests for AWK"

    local slug="$1"
    echo "Test slug: ${slug}"

    local solution_dir
    solution_dir="$(realpath "$2")"
    echo "Solution directory: ${solution_dir}"

    local output_dir
    output_dir="$(realpath "$3")"
    echo "Output directory: ${output_dir}"

    local output_file="$output_dir/results.out"
    local json_result_file="$output_dir/results.json"

    local -A test_bodies    # populated in get_test_bodies

    run_tests "$slug" "$solution_dir" "$output_file"
    build_report "$output_file" "$json_result_file"
}

run_tests() {
    # Run tests and pipe output to results.out file.

    local slug="$1"
    local solution_dir="$2"
    local output_file="$3"

    echo "Running tests."

    cd "$solution_dir"

    local test_file
    if [[ -f .meta/config.json ]]; then
        # production test runner
        test_file=$(jq -r '.files.test[0]' .meta/config.json)
    elif [[ -f .exercism/config.json ]]; then
        # local testing
        test_file=$(jq -r '.files.test[0]' .exercism/config.json)
    else
        test_file="test-${slug}.bats"
    fi

    echo "Test output:"

    bats --tap "$test_file" 2>&1 | tee "$output_file" || true

    get_test_bodies "$test_file"

    echo "Test run ended. Output saved in $output_file"

    cd -
}

get_test_bodies() {
    local test_file=$1
    local name line indent
    local state="out"
    local body=()
    test_bodies=()

    local start_test_re='^@test ['\''"](.+)['\''"] \{[[:blank:]]*$'
    local end_test_re='^\}[[:blank:]]*$'

    while IFS= read -r line; do
        case "$state" in
            out)
                if [[ $line =~ $start_test_re ]]; then
                    name=${BASH_REMATCH[1]}
                    body=()
                    state="in"
                fi
                ;;
            in)
                if [[ $line =~ $end_test_re ]]; then
                    test_bodies["$name"]=$(printf '%s\n' "${body[@]}")
                    state="out"
                elif [[ $line == *BATS_RUN_SKIPPED*skip* ]]; then
                    # skip the skips
                    continue
                elif ((${#body[@]} == 0)) && [[ $line == *([[:blank:]]) ]]; then
                    # ignore blank lines at the top of the test body
                    continue
                else
                    # We want to unindent the body: find the indentation of the first line.
                    ((${#body[@]} == 0)) && indent=${line%%[^[:blank:]]*}

                    body+=("${line#"$indent"}")
                fi
                ;;
        esac
    done < "$test_file"
}

build_report() {
    # Parse results.out and write result to results.json

    local output_file="$1"
    local json_result_file="$2"

    echo "Producing JSON report."

    readarray -t output < "$output_file"

    # first line in TAP output should be test plan: `1..10`
    if [[ ! ${output[0]} =~ ^([0-9]+)\.\.([0-9]+)$ ]]; then
        error "$output_file" "$json_result_file"
        return 1
    fi

    local first_test="${BASH_REMATCH[1]}"
    local last_test="${BASH_REMATCH[2]}"
    local test_count=$((last_test - first_test + 1))

    echo "Tried to run $test_count tests according to TAP plan."

    # process the rest of the TAP output
    local status="pass"
    local results test_body failed test_name
    local error_message

    for ((i = 1; i < ${#output[@]}; i++)); do
        if [[ ${output[i]} =~ ^"# "(.*) ]]; then
            error_message+="${BASH_REMATCH[1]}"$'\n'

        elif [[ ${output[i]} =~ ^(not )?ok\ [0-9]+\ (.*)$ ]]; then
            # start of new test
            # add _previous_ to results
            if [[ -n $test_name ]]; then
                if [[ -z $failed ]]; then
                    results+=("$(print_passed_test "$test_name" "$test_body")")
                else
                    status="fail"
                    results+=("$(print_failed_test "$test_name" "$error_message" "$test_body")")
                fi
            fi

            failed=${BASH_REMATCH[1]}
            test_name=${BASH_REMATCH[2]}
            test_body=${test_bodies[$test_name]:-}
            error_message=""
        fi
    done

    # last test
    if [[ -n $test_name ]]; then
        if [[ -z $failed ]]; then
            results+=("$(print_passed_test "$test_name" "$test_body")")
        else
            status="fail"
            results+=("$(print_failed_test "$test_name" "$error_message" "$test_body")")
        fi
    fi

    print_report "$status" "${results[@]}" > "$json_result_file"

    echo "Wrote report to $json_result_file"

    return 0
}

error() {
    # Store entire output to results.json file, in case of an error.

    local output_file="$1"
    local json_result_file="$2"

    echo "Failed to parse output."
    echo "This probably means there was an error running the tests."

    jq  --null-input \
        --argjson version "$INTERFACE_VERSION" \
        --arg status "error" \
        --arg message "$(< "$output_file")" \
        '{version: $version, status: $status, message: $message}'

    echo "Wrote error report to $json_result_file"
}

print_report() {
    # Print complete result JSON, given the overall status and a list of
    # already JSON-encoded test results.
    local status=$1
    shift
    local tests=("$@")
    jq  --null-input \
        --argjson version "$INTERFACE_VERSION" \
        --argjson tools "$(tool_versions)" \
        --arg status "$status" \
        --jsonargs \
        '{
            version: $version,
            status: $status,
            "test-environment": $tools,
            tests: $ARGS.positional
        }' \
        "${tests[@]}"
}

tool_versions() {
    # print versions of tools in the test environment
    jq  --null-input \
        --arg gawk "$(gawk --version | head -1)" \
        --arg bats "$(bats --version)" \
        --arg OS "$(. /etc/lsb-release; echo "$DISTRIB_DESCRIPTION")" \
        '$ARGS.named'
}

print_failed_test() {
    # Print result of failed test as JSON.
    jq  --null-input \
        --arg name "$1" \
        --arg message "$2" \
        --arg code "$3" \
        --arg status "fail" \
        '{name: $name, status: $status, test_code: $code, message: $message}'
}

print_passed_test() {
    # Print result of passed test as JSON.
    jq  --null-input \
        --arg name "$1" \
        --arg code "$2" \
        --arg status "pass" \
        '{name: $name, status: $status, test_code: $code}'
}

main "$@"
