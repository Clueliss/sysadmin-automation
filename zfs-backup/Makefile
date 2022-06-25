install:
	install -d /etc/systemd/system
	install etc/zfs-backup.service /etc/systemd/system
	install etc/zfs-backup.timer /etc/systemd/system
	
	install etc/zfs-backup.conf /etc/zfs-backup.conf

	install -d /usr/local/sbin
	install src/zfs-backup.sh /usr/local/sbin/zfs-backup

uninstall:
	systemctl disable zfs-backup.timer --now
	systemctl disable zfs-backup.service --now

	rm /etc/systemd/system/zfs-backup.service
	rm /etc/systemd/system/zfs-backup.timer
	rm /etc/zfs-backup.conf
	rm /usr/local/sbin/zfs-backup
