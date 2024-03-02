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

function pft_count_loops_before_failure(){
    local issue_id="$1"
    local failure_trace_id="$2"
    grep -c -- '----------- LOOP' "${SCRIPT_DIR}/$issue_id/failure_trace_${failure_trace_id}.txt"
}

function pft_count_number_of_failures(){
    local issue_id="$1"
    ls -l "${SCRIPT_DIR}/$issue_id"/failure_trace_*.txt | wc -l
}

function pft_container_logs(){
    local container_id="$1"
    local container_type=$(docker container ls |
			       grep "$container_id" |
			       awk '{print $3}' |
			       sed -e 's/.*run-//' -e 's/\.sh//' -e 's/"//g')
    docker container exec -it "$container_id" bash -c "tail -f /var/log/pulsar/${container_type}.log"
}

function pft_download_pulsar_admin(){
    local input_tag="${1}"
    # this allows to catch pulsar_version from the 
    exec 3>&1
    local pulsar_version=$(
	cd $PULSAR_DEV_DIR
	local pulsar_tag="${input_tag:-$(gh release list --limit 1 | awk '{print $1}')}"
	local pulsar_version="${pulsar_tag/v}"
	if [[ $(ls -d /tmp/pulsar-* 2> /dev/null | grep -c "$pulsar_version") -eq 0 ]]; then
	    echo "Downloading $pulsar_tag" >&3
            gh release download "$pulsar_tag" --archive=tar.gz >&3
	    tar -xf "$PULSAR_DEV_DIR/pulsar-${pulsar_version}.tar.gz" -C /tmp
	    rm "$PULSAR_DEV_DIR/pulsar-${pulsar_version}.tar.gz"
	else
	    echo "Pulsar $pulsar_tag cached" >&3
	fi
	echo "$pulsar_version"
	  )
    # we keep adding to update to the latest pulsar release pulsar-admin
    echo "Adding pulsar-admin to PATH"
    export PATH="/tmp/pulsar-$pulsar_version/bin:$PATH"
    echo PATH=$PATH
    pulsar-admin -v
}

