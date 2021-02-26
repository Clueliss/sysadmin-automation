install:
	install etc/zfs-backup.service /etc/systemd/system
	install etc/zfs-backup.timer /etc/systemd/system
	install src/zfs-backup.sh /usr/local/bin
	chmod +x /usr/local/bin/zfs-backup.sh

uninstall:
	rm /etc/systemd/system/zfs-backup.service
	rm /etc/systemd/system/zfs-backup.timer
	rm /usr/local/bin/zfs-backup.sh
