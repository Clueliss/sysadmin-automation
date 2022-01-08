#!/bin/bash

set -e
set -u

action="$1"
pod_name="$2"

pod_infra=$(podman pod inspect ${pod_name} | jq -re '.Containers | map(select(.Name | test(".*-infra"))) | .[0].Name')
pod_addr=$(podman container inspect ${pod_infra} | jq -re '.[0].NetworkSettings.IPAddress')

case "$action" in
    -r) firewall-cmd --zone podman --remove-source ${pod_addr}/32 ;;
    -c) firewall-cmd --zone podman --change-source ${pod_addr}/32 ;;
    *)  echo "invalid action, must be one of [-c, -r]"; exit 1 ;;
esac
