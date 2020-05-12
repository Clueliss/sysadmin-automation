all:

install:
	install -d /etc/systemd/system
	install etc/zfs-scrub@.timer /etc/systemd/system
	install etc/zfs-scrub@.service /etc/systemd/system

uninstall:
	rm /etc/systemd/system/zfs-scrub@.timer
	rm /etc/systemd/system/zfs-scrub@.service
