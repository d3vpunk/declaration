#!/bin/bash

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

set -euo pipefail

fetch_gateway() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        /sbin/ip route | grep default | awk '{print $3}'
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        /sbin/route -n get default | grep 'gateway' | awk '{print $2}'
    else
        echo "Unsupported operating system"
        return 1
    fi
}

url_encode() {
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case "$c" in
            [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
}


base_url="https://d.d3vpunk.com/register-day"
#base_url="https://localhost/register-day"
query_params=""


# Build query parameters
for arg in "$@"; do
    if [[ "$arg" == *"="* ]]; then
        key="${arg%%=*}"
        value="${arg#*=}"
        encoded_value=$(url_encode "$value")
        query_params="${query_params:+$query_params&}${key}=${encoded_value}"
    else
        echo "Warning: Skipping invalid parameter: $arg"
    fi
done

final_url="${base_url}${query_params:+?$query_params}"

target_gateway="172.16.16.1"
#target_gateway="192.168.178.1"
gateway=$(fetch_gateway)

if [ $? -ne 0 ]; then
    echo "Failed to fetch gateway. Exiting."
    exit 1
fi

if [[ "$gateway" == "$target_gateway" ]]; then
    echo "Default gateway matches target. Calling endpoint!"
    echo "URL: $final_url"
    response=$(curl -s -w "\n%{http_code}" "$final_url")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [[ "$http_code" == "200" ]]; then
        echo "Successfully called endpoint. Response: $body"
    else
        echo "Failed to call endpoint. HTTP status: $http_code, Response: $body"
    fi
else
    echo "Default gateway ($gateway) does not match target ($target_gateway). Exiting."
fi
