all:

install:
	install -d /etc/systemd/system
	install etc/fix-docker.service /etc/systemd/system

	install -d /usr/local/sbin
	install src/fix-docker.sh /usr/local/sbin/fix-docker

uninstall:
	systemctl disable fix-docker.service --now
	rm /etc/systemd/system/fix-docker.service
	rm /usr/local/sbin/fix-docker
