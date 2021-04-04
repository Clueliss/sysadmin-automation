#!/bin/bash

REMOTE_IP="192.168.0.5"
REMOTE_MAC="00:1c:c0:1e:77:49"
REMOTE_USER="root"
LOCAL_POOL="pool0"
REMOTE_POOL="backup0"
DATASETS=("home/liss" "home/liss/google_drive" "home/claudia" "home/rolf" "pictures" "vm/docker/cache-backup")


latest_local_snapshot() {
    local fs="$1"
    zfs list -t snapshot -o name,creation | grep "$LOCAL_POOL/$fs@" | tail -n1 | awk '{ print $1 }'
}

latest_remote_snapshot() {
    local fs="$1"
    ssh "$REMOTE_USER@$REMOTE_IP" "zfs list -t snapshot -o name,creation" | grep "$REMOTE_POOL/$fs@" | tail -n1 | awk '{ print $1 }'
}

sync() {
    local fs="$1"
    local lsnap=$(latest_local_snapshot "$fs")
    local rsnap=$(latest_remote_snapshot "$fs")
    local rlsnap=$(echo $rsnap | sed "s|$REMOTE_POOL/|$LOCAL_POOL/|")

    echo "syncing $fs..."
    echo "latest on local:  '$lsnap'"
    echo "latest on remote: '$rsnap'"
    echo "using local base: '$rlsnap'"

    if [[ $rsnap != "" ]]; then
        zfs send -I "$rlsnap" "$lsnap" | ssh "$REMOTE_USER@$REMOTE_IP" zfs recv -F "$REMOTE_POOL/$fs"
    else
        zfs send "$lsnap" | ssh "$REMOTE_USER@$REMOTE_IP" zfs recv "$REMOTE_POOL/$fs"
    fi

    return $?
}

try_wake_up() {
    wol "$REMOTE_MAC"
    for _ in {1..5}; do
        if ping -c 1 "$REMOTE_IP"; then
            return 0
        fi
        sleep 120
    done

    return 1
}

ping -c 1 "$REMOTE_IP"
init_ping_success=$?

if [[ $init_ping_success != 0 ]]; then
    # server not online, try to bring up

    if ! try_wake_up; then
        echo "failed to bring up remote"
        pb push "failed to bring up remote backup server"
        exit 1
    fi
fi


for ds in "${DATASETS[@]}"; do
    sync "$ds"
done

echo "backup completed, shutting down remote"

if [[ $was_online != 0 ]]; then
    ssh "$REMOTE_USER@$REMOTE_IP" "systemctl hibernate"
fi
