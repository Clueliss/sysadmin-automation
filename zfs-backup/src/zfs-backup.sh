#!/bin/bash

set -uo pipefail

source /etc/zfs-backup.conf

REMOTE_FS_BASE="${REMOTE_POOL}/${REMOTE_FS_PREFIX}"

list_local_snapshots() {
    local fs="$1"
    zfs list -t snapshot -o name "$LOCAL_POOL/$fs" | tail -n+2 | grep -E "$SNAPSHOT_PATTERN"
}

list_remote_snapshots() {
    local fs="$1"

    if [[ $REMOTE_IP == "localhost" ]]; then
        zfs list -t snapshot -o name "$REMOTE_FS_BASE/$fs"
    else
        ssh root@$REMOTE_IP zfs list -t snapshot -o name "$REMOTE_FS_BASE/$fs"
    fi | tail -n+2 | grep -E "$SNAPSHOT_PATTERN"
}

latest_common_snapshot() {
    local local_snapshots="$1"
    local remote_snapshots="$2"

    grep -x -f <(echo "$local_snapshots" | sed "s|$LOCAL_POOL/||") <(echo "$remote_snapshots" | sed "s|$REMOTE_FS_BASE/||") | tail -n1
}

local_fs_has_children() {
    local fs="$1"

    [[ $(zfs list -t filesystem -o name | grep --count "$LOCAL_POOL/$fs") -gt 1 ]]
    return $?
}

sync() {
    local fs="$1"

    local local_snaps=$(list_local_snapshots "$fs")
    local remote_snaps=$(list_remote_snapshots "$fs")

    local latest_common_snap=$(latest_common_snapshot "$local_snaps" "$remote_snaps")

    echo "<6>beginning sync of filesystem $fs"
    echo "<7>latest snapshot on local:  '$(echo "$local_snaps" | tail -n1)'"
    echo "<7>latest snapshot on remote: '$(echo "$remote_snaps" | tail -n1)'"
    echo "<7>latest common snapshot:    '$latest_common_snap'"

    if [[ -n $latest_common_snap ]]; then
        local base_arg="-i $LOCAL_POOL/$latest_common_snap"
        local to_send=$(echo "$local_snaps" | sed "0,\|$latest_common_snap|d")
    else
        local base_arg=""
        local to_send=$local_snaps
    fi

    if [[ -z $to_send ]]; then
        echo "<6>no snapshots to send, skipping filesystem $fs"
        return 0
    fi

    if local_fs_has_children "$fs"; then
        local recursive_arg="-R"
        echo "<7>sending recursively"
    else
        local recursive_arg=""
    fi

    for snap in $to_send; do
        echo "<7>sending snapshot $snap with args: $recursive_arg $base_arg"

        zfs send -b $recursive_arg $base_arg "$snap" | if [[ $REMOTE_IP == "localhost" ]]; then
            zfs recv -vud "$REMOTE_FS_BASE"
        else
            ssh root@$REMOTE_IP zfs recv -vud "$REMOTE_FS_BASE"
        fi

        if [[ $? -ne 0 ]]; then
            echo "<4>send error, sync of filesystem $fs failed"
            return 1
        fi

        base_arg="-i $snap"
    done

    echo "<6>sync of filesystem $fs successful"
    return 0
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
