#!/bin/sh
set -e

# List of CLI args and their env var mappings: "short long"
ARG_PAIRS="
C connection-string
S send-path
R receive-paths
n number-of-messages
b message-size-bytes
f frequency-metrics
m receive-mode
r receiver-count
e prefetch-count
t send-batch-count
s sender-count
d send-delay
i inflight-sends
j inflight-receives
v receive-batch-count
w receive-work-duration
"

ARGS=""

for pair in $ARG_PAIRS; do
    set -- $pair
    short=$1
    long=$2
    env_name=$(echo "$long" | tr '-' '_' | tr '[:lower:]' '[:upper:]')
    env_value=$(eval echo \$$env_name)
    # Prefer short flag if present, but allow both
    if [ -n "$env_value" ]; then
        ARGS="$ARGS -$short \"$env_value\""
    fi
done

# shellcheck disable=SC2086
eval exec dotnet ThroughputTest.dll $ARGS "$@"