#!/bin/bash

REMOTE_IP="192.168.0.5"
REMOTE_MAC="00:1c:c0:1e:77:49"
LOCAL_POOL="pool0"
REMOTE_POOL="backup0"

latest_local_snapshot() {
    local fs="$1"
    zfs list -t snapshot -o name,creation | grep "$LOCAL_POOL/$fs@" | tail -n1 | awk '{ print $1 }'
}

latest_remote_snapshot() {
    local fs="$1"
    ssh "root@$REMOTE_IP" "zfs list -t snapshot -o name,creation" | grep "$REMOTE_POOL/$fs@" | tail -n1 | awk '{ print $1 }'
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
        zfs send -I "$rlsnap" "$lsnap" | ssh "root@$REMOTE_IP" zfs recv "$REMOTE_POOL/$fs"
    else
        zfs send "$lsnap" | ssh "root@$REMOTE_IP" zfs recv "$REMOTE_POOL/$fs"
    fi

    local ret=$?
    echo ""
    return $ret
}


wol "$REMOTE_MAC"

local success=0
for _ in {1..5}; do
    if ping -c 1 192.168.0.5; then
        success=1
        break
    fi
    sleep 120
done

if [[ $success == 1 ]]; then
    sync home/liss
    sync home/liss/google_drive
    sync home/rolf
    sync home/claudia
    sync pictures

    echo "backup completed, shutting down remote"
    ssh "root@$REMOTE_IP" "systemctl hibernate"
else
    echo "failed to bring up backup server"
    pb push "failed to bring up backup server"
fi
