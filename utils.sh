#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
if [[ -z $PULSAR_DEV_DIR ]]; then
    echo "Please set PULSAR_DEV_DIR and try again"
    exit 1
fi

function pft_run_test_until_fails(){
    local issue_id="$1"
    (
	cd $PULSAR_DEV_DIR
	issue_title_json=$(gh issue view "$issue_id" --json title)
	test_file_name=$(jq -r '.title' <(echo $issue_title_json) | 
			sed -e 's/Flaky-test: //' -e 's/\..*//')
	test_name=$(jq -r '.title' <(echo $issue_title_json) | 
			sed -e 's/Flaky-test: //' -e 's/.*\.//')
	echo "Issue $issue_id is about $test_name in ${test_file_name}.java"
    )
}
