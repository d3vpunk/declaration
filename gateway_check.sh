#!/bin/bash

set -euo pipefail

# Mock curl for testing
if [[ -n "${MOCK_CURL:-}" ]]; then
  curl() {
    echo "${MOCK_CURL}"
  }
fi

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "/tmp/gateway_check.log"
}

fetch_gateway() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        ip route | grep default | awk '{print $3}'
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        route -n get default | grep 'gateway' | awk '{print $2}'
    else
        log "Unsupported operating system"
        return 1
    fi
}

url_encode() {
    printf '%s' "$1" | jq -sRr @uri
}

base_url="https://d.d3vpunk.com/register-day"
query_params=""

# Build query parameters
for arg in "$@"; do
    if [[ "$arg" == *"="* ]]; then
        key="${arg%%=*}"
        value="${arg#*=}"
        encoded_value=$(url_encode "$value")
        query_params="${query_params:+$query_params&}${key}=${encoded_value}"
    else
        log "Warning: Skipping invalid parameter: $arg"
    fi
done

final_url="${base_url}${query_params:+?$query_params}"

target_gateway="172.16.16.1"
gateway=$(fetch_gateway)

if [ $? -ne 0 ]; then
    log "Failed to fetch gateway. Exiting."
    exit 1
fi

if [[ "$gateway" == "$target_gateway" ]]; then
    log "Default gateway matches target. Calling endpoint."
    response=$(curl -s -w "\n%{http_code}" "$final_url")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [[ "$http_code" == "200" ]]; then
        log "Successfully called endpoint. Response: $body"
    else
        log "Failed to call endpoint. HTTP status: $http_code, Response: $body"
    fi
else
    log "Default gateway ($gateway) does not match target ($target_gateway). Exiting."
fi