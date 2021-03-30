#!/bin/bash

trap 'echo_and_exit1 "ERROR! Something went wrong" ${LINENO}' ERR
echo_and_exit1() { echo ; echo -e "${1} (${2}, ${BASH_SOURCE[0]})"; echo ; exit 1; }

echo ; echo "-- Checking NGINX status (1 time):";

service nginx status

echo ; echo "-- Healthcheck finished";
