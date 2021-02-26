install:
	install -d /etc/systemd/system
	install etc/startup-notify.service /etc/systemd/system

	install -d /usr/local/sbin
	install src/gen-status-msg.sh /usr/local/sbin/gen-status-msg

uninstall:
	systemctl disable startup-notify.service --now
	rm /etc/systemd/system/startup-notify.service
	rm /usr/local/sbin/gen-status-msg
