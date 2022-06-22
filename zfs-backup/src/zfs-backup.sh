#!/bin/bash

set -euo pipefail

REMOTE_IP=""
REMOTE_MAC=""
LOCAL_POOL="nand0"
REMOTE_POOL="pool0"
REMOTE_FS_PREFIX="received"
DATASETS=("home" "container")


REMOTE_FS_BASE="${REMOTE_POOL}/${REMOTE_FS_PREFIX}"

latest_local_snapshot() {
    local fs="$1"
    zfs list -t snapshot -o name "$LOCAL_POOL/$fs" | tail -n+2 | tail -n1
}

latest_remote_snapshot() {
    local fs="$1"

    if [[ $REMOTE_IP == "localhost" ]]; then
        zfs list -t snapshot -o name "$REMOTE_FS_BASE/$fs"
    else
        ssh root@$REMOTE_IP zfs list -t snapshot -o name "$REMOTE_FS_BASE/$fs"
    fi | tail -n+2 | tail -n1
}

local_fs_has_children() {
    local fs="$1"

    [[ $(zfs list -t filesystem -o name | grep --count "$LOCAL_POOL/$fs") -gt 1 ]]
    return $?
}

sync() {
    local fs="$1"
    local lsnap=$(latest_local_snapshot "$fs")
    local rsnap=$(latest_remote_snapshot "$fs")
    local rlsnap=${rsnap/${REMOTE_FS_BASE}/${LOCAL_POOL}}

    echo "<6>syncing $fs..."
    echo "<7>latest on local:  '$lsnap'"
    echo "<7>latest on remote: '$rsnap'"
    echo "<7>using local base: '$rlsnap'"

    local additional_send_args=""

    if local_fs_has_children $fs; then
        additional_send_args="${additional_send_args} -R"
    fi

    if [[ -n $rsnap ]]; then
        additional_send_args="${additional_send_args} -I ${rlsnap}"
    fi

    echo "<7>additional send args: ${additional_send_args}"

    zfs send -b ${additional_send_args} "$lsnap" | if [[ $REMOTE_IP == "localhost" ]]; then
        zfs recv -vud "$REMOTE_FS_BASE"
    else
        ssh root@$REMOTE_IP zfs recv -vud "$REMOTE_FS_BASE"
    fi

    return $?
}

wake_remote() {
    wol $REMOTE_MAC

    for _ in {1..5}; do
        if ping -c 1 $REMOTE_IP; then
            return 0
            break
        fi
        sleep 120
    done
    return 1
}

if [[ $REMOTE_IP == "localhost" ]] || wake_remote; then
    for ds in "${DATASETS[@]}"; do
        sync "$ds"
    done

    echo "<6>backup completed, shutting down remote"

    if [[ $REMOTE_IP != "localhost" ]]; then
        ssh root@$REMOTE_IP "systemctl hibernate"
    fi
    exit 0
else
    echo "<3>failed to bring up backup server"
    exit 1
fi
