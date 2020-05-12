#!/bin/bash

function pretty_print {
    sed 's/^/  /g'
}


echo "server $(cat /etc/hostname) is now online:"

systemd-analyze | pretty_print


echo ""
echo "pool status:"

zpool status | grep -E "state|errors" | sed 's/^[[:space:]]*/  /g'


echo ""
echo "filesystem mount status:"

zfs get mounted -t filesystem | pretty_print


echo ""
echo "following systemd units failed to start:"

systemctl --failed | pretty_print

