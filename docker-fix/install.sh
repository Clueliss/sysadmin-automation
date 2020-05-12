#!/bin/bash

set -e

cp ./fix-docker.sh /usr/bin/fix-docker

# set ownership and privileges
chown root:root /usr/bin/fix-docker
chmod +x /usr/bin/fix-docker

# restore selinux context
restorecon /usr/bin/fix-docker


cp ./fix-docker.service /etc/systemd/system

# set owner
chown root:root /etc/systemd/system/fix-docker.service

# restore selinux context
restorecon /etc/systemd/system/fix-docker.service

echo "success"
echo "service can now be enable via: 'systemctl enable fix-docker.service'"
