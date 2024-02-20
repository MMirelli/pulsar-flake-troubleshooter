#!/bin/env bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DATA_DIR="${SCRIPT_DIR}/data"
#metric="${1:-sunitStateChn.*brk_sunit_state_chn_subscribe_ops_total}" 
failure_file="${1/.txt}"
expected_json="${failure_file}-expected.json"
actual_json="${failure_file}-actual.json"
{
    for metric in $(jq -r '.[] | "\(.dimensions[].metric).*\(.metrics[]|keys[0])"' "$actual_json"|sort|uniq); do
	echo "Diffing ${expected_json/${SCRIPT_DIR}\/} ${actual_json/${SCRIPT_DIR}\/} by $metric"
	diff <(grep "$metric" "$expected_json" | sort) <(grep "$metric" "$actual_json" | sort)
    done
} > ${failure_file}-diff.log
