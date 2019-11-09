#!/bin/bash

cp ./gen-status-msg /usr/bin
chmod +x /usr/bin/gen-status-msg

cp ./startup-notify.service /etc/systemd/system
systemctl daemon-reload
