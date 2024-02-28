#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
if [[ -z $PULSAR_DEV_DIR ]]; then
    echo "Please set PULSAR_DEV_DIR and try again"
    exit 1
fi

# pft_run_test_until_fails <pulsar_flaky_test_issue_id>
function pft_run_flaky_until_fails_by_issue_id(){
    local issue_id="$1"
    mkdir --parents "${SCRIPT_DIR}/$issue_id"
    (
	cd $PULSAR_DEV_DIR
	local issue_title_json=$(gh issue view "$issue_id" --json title)
	local test_file_name=$(jq -r '.title' <(echo $issue_title_json) | 
				   sed -e 's/Flaky-test: //' -e 's/\..*//')
	local test_name=$(jq -r '.title' <(echo $issue_title_json) | 
			      sed -e 's/Flaky-test: //' -e 's/.*\.//')
	local full_test_name=$(find "$PULSAR_DEV_DIR" -name "${test_file_name}.java" -type f)
	local test_root=$(echo "${full_test_name}" |
			      sed -e "s#${PULSAR_DEV_DIR}##" -e "s#/# #g" |
			      awk '{print $1}')
	local count_of_failure_traces=$(ls -l "${SCRIPT_DIR}/$issue_id"/failure_trace_*.txt 2> /dev/null | wc -l)
	if [[ -z $count_of_failure_traces ]]; then
	    count_of_failure_traces=0
	fi
	{
	    echo "Issue $issue_id is due to failure in ${test_file_name}#$test_name" 

	    if [[ $test_root == tests ]]; then
		echo "mvn install -DskipTests -Pdocker,-main"
		mvn install -DskipTests -Pdocker,-main
		echo "ptbx_until_test_fails -f tests/pom.xml test -DintegrationTests -Dtest=${test_file_name}#${test_name}"
		ptbx_until_test_fails -f tests/pom.xml test -DintegrationTests -Dtest="${test_file_name}#${test_name}"
	    else
		echo "ptbx_until_test_fails -Pcore-modules -pl $test_root -Dtest=${test_file_name}#${test_name}"
		ptbx_until_test_fails -Pcore-modules -pl "$test_root" -Dtest="${test_file_name}#${test_name}"
	    fi
	} |  tee -a "${SCRIPT_DIR}/$issue_id/failure_trace_$((count_of_failure_traces + 1)).txt"
    )
}
