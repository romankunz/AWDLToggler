#!/usr/bin/env bash

set -euo pipefail

while true; do
    if ifconfig awdl0 |grep -q "<UP"; then
        (set -x; sudo ifconfig awdl0 down)
    fi

    sleep 1
done
