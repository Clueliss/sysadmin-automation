#!/bin/bash

dnf copr enable vaughan/drive-google
dnf install drive-google

cp ./google-drive-sync.* /etc/systemd/system
chown root:root /etc/systemd/system/google-drive-sync.*
restorecon /etc/systemd/system/google-drive-sync.*
