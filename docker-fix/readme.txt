# mv docker-fix.sh /usr/bin/docker-fix
# chmod +x /usr/bin/docker-fix
# restorecon /usr/bin/docker-fix


add 'ExecStartPre=/usr/bin/docker-fix' to [Service] Section of docker.service
