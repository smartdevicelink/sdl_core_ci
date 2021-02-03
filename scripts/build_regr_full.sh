#!/usr/bin/env bash

_in_file=$1
_out_file=$2

function show_help() {
  echo "Bash script to create full regression test set"
  echo
  echo "Usage: build_full_regr.sh SOURCE_LIST_OF_TEST_SETS REGRESSION_TEST_SET"
  echo
  exit 0
}

function process_test_set() {
  local test_set=$1
  if [ ! -f $test_set ]; then
    echo "File not found:" $test_set
    return
  fi
  local rows=$(sed -E '/^;/d' $test_set)
  while read -r row; do
    local script=$(echo $row | awk '{print $1}')
    local issue=$(echo $row | awk '{print $2}')
    echo $script >> $_out_file
  done <<< "$rows"
}

function process_source_list() {
  while IFS= read -r line; do
    process_test_set $line
  done < "$_in_file"
  sort -u $_out_file -o $_out_file
}

if [ $# -eq 0 ]; then
  show_help
fi

if [ -z $_in_file ]; then
  echo "Source list of test sets was not specified"
  exit 1
fi

if [ ! -f $_in_file ]; then
  echo "File with source list of test sets was not found"
  exit 1
fi

if [ -z $_out_file ]; then
  echo "Regression test set file was not specified"
  exit 1
fi

if [ -f $_out_file ]; then
  rm -f $_out_file
  echo "Existing regression test set file was deleted"
fi

echo "Process started"

process_source_list

echo "Process finished"
