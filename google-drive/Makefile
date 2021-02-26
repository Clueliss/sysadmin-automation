install:
	dnf copr enable vaughan/drive-google -y
	dnf install drive-google -y

	install -d /etc/systemd/system
	install etc/google-drive-sync.timer /etc/systemd/system
	install etc/google-drive-sync.service /etc/systemd/system

uninstall:
	systemctl disable google-drive-sync.timer --now
	rm /etc/systemd/system/google-drive-sync.timer
	rm /etc/systemd/system/google-drive-sync.service

	dnf remove drive-google -y
