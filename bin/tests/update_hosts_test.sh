#!/usr/bin/env bash

set -e

: "${TEST_HOSTS_FILE:=$(mktemp)}"
: "${TEST_COREFILE:=$(mktemp)}"
: "${TEST_NEOFS_CHAIN_CONFIG:=$(mktemp)}"

: "${TEMP_ENV_FILE:=$(mktemp)}"

: "${BASE_HOSTS_FILE:=/etc/hosts}"
: "${BASE_COREFILE:=services/coredns/Corefile}"
: "${BASE_NEOFS_CHAIN_CONFIG:=services/ir/cfg/config.yml}"
: "${BASE_ENV_FILE:=.env}"

cleanup() {
  rm -f "$TEST_HOSTS_FILE" "$TEST_COREFILE" "$TEST_NEOFS_CHAIN_CONFIG"
  cp "$TEMP_ENV_FILE" "$BASE_ENV_FILE"
}

run_update_hosts() {
    HOSTS_FILE="$TEST_HOSTS_FILE" COREFILE="$TEST_COREFILE" NEOFS_CHAIN_CONFIG="$TEST_NEOFS_CHAIN_CONFIG" ./bin/update_hosts.sh > /dev/null
}

check_test() {
  local expected_output="$1"
  local test_output="$2"
  local test_case="$3"

  if [[ "$expected_output" == "$test_output" ]]; then
    echo "Test case '$test_case' passed."
  else
    echo "Test case '$test_case' failed."
    echo "Expected:"
    echo "$expected_output"
    echo "Got:"
    echo "$test_output"
    cleanup
    exit 1
  fi
}

prepare_environment() {
  cleanup
  :>"$TEST_HOSTS_FILE"
  :>"$TEST_COREFILE"
  :>"$TEST_NEOFS_CHAIN_CONFIG"
  sed -i 's/^IPV4_PREFIX=192\.168\.130/IPV4_PREFIX=192\.168\.100/' "$BASE_ENV_FILE"
}

empty_file_test() {
  local test_name="empty file"
  local empty_output
  local out
  echo "Running $test_name test..."
  prepare_environment

  run_update_hosts

  empty_output=$(cat "$TEST_HOSTS_FILE")
  out=$(make hosts)
  check_test "$out" "$empty_output" "$test_name hosts"
  
  empty_output=$(cat "$TEST_COREFILE")
  out=""
  check_test "$out" "$empty_output" "$test_name corefile"
  
  empty_output=$(cat "$TEST_NEOFS_CHAIN_CONFIG")
  out=""
  check_test "$out" "$empty_output" "$test_name config"
}

host_file_with_no_ips_test() {
  local test_name="host file with no IPs changes"
  local initial_hosts_content
  echo "Running $test_name test..."
  prepare_environment

  echo "127.0.0.1       localhost" > "$TEST_HOSTS_FILE"
  initial_hosts_content=$(cat "$TEST_HOSTS_FILE" && make hosts)

  run_update_hosts

  no_change_hosts_output=$(cat "$TEST_HOSTS_FILE")
  check_test "$initial_hosts_content" "$no_change_hosts_output" "$test_name"
}

update_entries_in_hosts_test() {
  local expected_output
  local update_output
  echo "Running update entries in $BASE_HOSTS_FILE tests..."
  prepare_environment

  echo "192.168.100.61 ir01.neofs.devenv
127.0.0.1       localhost" > "$TEST_HOSTS_FILE"
  run_update_hosts
  expected_output="192.168.100.61 ir01.neofs.devenv
127.0.0.1       localhost
192.168.100.10 bastion.neofs.devenv
192.168.100.50 main-chain.neofs.devenv
192.168.100.53 coredns.neofs.devenv
192.168.100.81 http.neofs.devenv
192.168.100.102 k6_node.neofs.devenv
192.168.100.101 nats.neofs.devenv
192.168.100.83 rest.neofs.devenv
192.168.100.82 s3.neofs.devenv
192.168.100.82 *.s3.neofs.devenv
192.168.100.71 s01.neofs.devenv
192.168.100.72 s02.neofs.devenv
192.168.100.73 s03.neofs.devenv
192.168.100.74 s04.neofs.devenv"

update_output=$(cat "$TEST_HOSTS_FILE")
check_test "$expected_output" "$update_output" "update one entries in $BASE_HOSTS_FILE"

echo "127.0.0.1       localhost
192.168.130.10 bastion.neofs.devenv
192.168.130.50 main-chain.neofs.devenv
192.168.130.53 coredns.neofs.devenv
192.168.130.81 http.neofs.devenv
192.168.130.61 ir01.neofs.devenv
192.168.130.101 nats.neofs.devenv
192.168.130.83 rest.neofs.devenv
192.168.130.82 s3.neofs.devenv
192.168.130.82 *.s3.neofs.devenv
192.168.130.71 s01.neofs.devenv
192.168.130.72 s02.neofs.devenv
192.168.130.73 s03.neofs.devenv
192.168.130.74 s04.neofs.devenv" > "$TEST_HOSTS_FILE"
  run_update_hosts
  expected_output="127.0.0.1       localhost
192.168.100.10 bastion.neofs.devenv
192.168.100.50 main-chain.neofs.devenv
192.168.100.53 coredns.neofs.devenv
192.168.100.81 http.neofs.devenv
192.168.100.61 ir01.neofs.devenv
192.168.100.101 nats.neofs.devenv
192.168.100.83 rest.neofs.devenv
192.168.100.82 s3.neofs.devenv
192.168.100.82 *.s3.neofs.devenv
192.168.100.71 s01.neofs.devenv
192.168.100.72 s02.neofs.devenv
192.168.100.73 s03.neofs.devenv
192.168.100.74 s04.neofs.devenv
192.168.100.102 k6_node.neofs.devenv"

update_hosts_output=$(cat "$TEST_HOSTS_FILE")
check_test "$expected_output" "$update_hosts_output" "update all entries in $BASE_HOSTS_FILE"
}

update_corefile_test() {
  local expected_output
  local update_output
  echo "Running update $BASE_COREFILE file test..."
  prepare_environment
  echo ". {
    nns http://192.168.130.61:30333
    transfer {
       to *
    }
    log
    debug
}" > "$TEST_COREFILE"
  run_update_hosts
  expected_output=". {
    nns http://192.168.100.61:30333
    transfer {
       to *
    }
    log
    debug
}"
  update_output=$(cat "$TEST_COREFILE")
  check_test "$expected_output" "$update_output" "update $BASE_COREFILE file"
  }

update_configfile_test() {
  local expected_output
  local update_output
  echo "Running update $BASE_NEOFS_CHAIN_CONFIG file test..."
  prepare_environment
  echo "P2P:
    Addresses:
      - \":20333\"
      
  RPC:
    Addresses:
      - \"192.168.130.61:30333\"
      
  Prometheus:
    Addresses:
      - \":20001\"

  Pprof:
    Addresses:
      - \":20011\"" > "$TEST_NEOFS_CHAIN_CONFIG"
  run_update_hosts
  expected_output="P2P:
    Addresses:
      - \":20333\"
      
  RPC:
    Addresses:
      - \"192.168.130.61:30333\"
      
  Prometheus:
    Addresses:
      - \":20001\"

  Pprof:
    Addresses:
      - \":20011\""
  update_output=$(cat "$TEST_NEOFS_CHAIN_CONFIG")
  check_test "$expected_output" "$update_output" "update $BASE_NEOFS_CHAIN_CONFIG file"
} 

cp "$BASE_ENV_FILE" "$TEMP_ENV_FILE"

empty_file_test
host_file_with_no_ips_test
update_entries_in_hosts_test
update_corefile_test
update_configfile_test

cleanup

echo "All update_hosts.sh tests passed."

