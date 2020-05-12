#!/bin/bash

rm /usr/bin/fix-docker

systemctl disable fix-docker.service
rm /etc/systemd/system/fix-docker.service
