install:
	install -d /etc/systemd/system
	install etc/zfs-backup.service /etc/systemd/system
	install etc/zfs-backup.timer /etc/systemd/system

	install -d /usr/local/bin
	install src/zfs-backup.sh /usr/local/bin
	chmod +x /usr/local/bin/zfs-backup.sh

uninstall:
	systemctl disable zfs-backup.timer --now
	systemctl disable zfs-backup.service --now

	rm /etc/systemd/system/zfs-backup.service
	rm /etc/systemd/system/zfs-backup.timer
	rm /usr/local/bin/zfs-backup.sh
