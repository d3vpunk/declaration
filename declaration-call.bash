#!/bin/bash

fetch_gateway() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    ip route | grep default | awk '{print $3}' # Linux
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    netstat -nr | grep default | awk '{print $2}' # macOS
  else
    return 1
  fi
}

base_url="https://example.com/register-day"

query_params=""

for arg in "$@"; do
  key="${arg%%=*}"
  value="${arg#*=}"

  [ -z "$query_params" ] && query_params="?${key}=${value}" || query_params="${query_params}&${key}=${value}"
done

final_url="${base_url}${query_params}"

target_gateway="172.16.16.1"

gateway=$(fetch_gateway)

echo "Gateway: $gateway"

if [[ "$gateway" == "$target_gateway" ]]; then
  echo "Default gateway matches target. Calling endpoint."
  curl -s "$final_url"
  exit 0
else
  echo "Default gateway ($gateway) does not match target ($target_gateway). Exiting."
  exit 1
fi