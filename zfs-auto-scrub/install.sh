#!/bin/bash

cp ./zfs-scrub* /etc/systemd/system
systemctl daemon-reload
