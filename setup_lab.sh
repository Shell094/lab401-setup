#!/bin/bash

# ============================================================
# EdUbuntu 26.04 Manual Setup Script
# ============================================================

set -euo pipefail

# Check Root
[[ $EUID -eq 0 ]] || { echo "ต้องรันด้วย root: sudo $0"; exit 1; }

echo "--- เริ่มต้นการติดตั้ง Software ---"

# 1-5. Standard Apps
apt update
apt install -y wireshark git vlc putty openssh-client openssh-server
systemctl start ssh.service
systemctl enable ssh.service

# 6. Visual Studio Code
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/keyrings/microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
apt update && apt install -y code

# 7. Google Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

# 8. Nodejs (Snap)
snap install node --classic --channel=24/stable

# 9-10. Python & Go
apt install -y python3 python3-pip python3-venv golang

# 11. Packet Tracer (ต้องการไฟล์ใน ~/Downloads)
# หมายเหตุ: ขั้นตอนนี้จะข้ามหากไม่พบไฟล์
if [ -f "$HOME/Downloads/CiscoPacketTracer_900_Ubuntu_64bit.deb" ]; then
    apt install -y libfuse2t64 libpcre2-dev
    apt install -y "$HOME/Downloads/CiscoPacketTracer_900_Ubuntu_64bit.deb"
fi

# 12. Fonts Setup
mkdir -p /usr/local/share/fonts/custom
if [ -d "$HOME/Downloads/Fonts" ]; then
    cp -r "$HOME/Downloads/Fonts/"* /usr/local/share/fonts/custom/
    fc-cache -f -v
fi

# 13. Language Settings (TH/US)
cat <<EOF > /etc/default/keyboard
XKBMODEL="pc105"
XKBLAYOUT="us,th"
XKBVARIANT=","
XKBOPTIONS="grp:alt_shift_toggle,terminate:ctrl_alt_bksp,grp_led:scroll"
BACKSPACE="guess"
EOF

# 14-15. Docker & Rootless Setup
apt install -y curl apt-transport-https ca-certificates software-properties-common uidmap dbus-user-session sssd
curl -fsSL https://get.docker.com | sh
usermod -aG docker $USER

# Setup Rootless Helper Scripts
cat <<'EOF' > /usr/local/bin/setup-docker-rootless.sh
#!/bin/bash
grep -q "^$PAM_USER:" /etc/subuid || echo "$PAM_USER:100000:65536" >> /etc/subuid
grep -q "^$PAM_USER:" /etc/subgid || echo "$PAM_USER:100000:65536" >> /etc/subgid
loginctl enable-linger "$PAM_USER"
EOF
chmod +x /usr/local/bin/setup-docker-rootless.sh

cat <<'EOF' > /usr/local/bin/add-to-docker.sh
#!/bin/bash
usermod -aG docker "$PAM_USER" 2>/dev/null
EOF
chmod +x /usr/local/bin/add-to-docker.sh

# PAM Config for Docker
echo "session optional pam_exec.so /usr/local/bin/setup-docker-rootless.sh" >> /etc/pam.d/common-session
echo "session optional pam_exec.so /usr/local/bin/add-to-docker.sh" >> /etc/pam.d/common-session

# 16-21. SSSD & LDAP Config
# (ตรวจสอบว่ามีไฟล์ coe-ldap-ca.crt ในโฟลเดอร์เดียวกับสคริปต์)
if [ -f "coe-ldap-ca.crt" ]; then
    cp coe-ldap-ca.crt /etc/ssl/certs/coe-ldap-ca.crt
fi

mkdir -p /etc/sssd/conf.d
cat <<'EOF' > /etc/sssd/conf.d/coe-ldap.conf
[sssd]
services = nss, pam
config_file_version = 2
domains = RMUTSV

[domain/RMUTSV]
id_provider = ldap
auth_provider = ldap
chpass_provider = none
sudo_provider = none
ldap_uri = ldap://172.16.81.1
ldap_search_base = dc=rmutsv,dc=ac,dc=th
ldap_user_search_base = ou=People,dc=rmutsv,dc=ac,dc=th
ldap_group_search_base = ou=Groups,dc=rmutsv,dc=ac,dc=th
ldap_schema = rfc2307
ldap_id_use_start_tls = true
ldap_tls_reqcert = demand
ldap_tls_cacert = /etc/ssl/certs/coe-ldap-ca.crt
ldap_user_object_class = posixAccount
ldap_user_name = uid
cache_credentials = true
enumerate = true

[nss]
filter_users = root,daemon,bin,sys

[pam]
offline_credentials_expiration = 7
EOF

chmod 600 /etc/sssd/conf.d/coe-ldap.conf
pam-auth-update --enable mkhomedir
systemctl enable --now sssd

# 22. Terminal Shortcut Fix (Ctrl+Alt+T)
mkdir -p /etc/dconf/db/local.d
cat <<EOF > /etc/dconf/db/local.d/01-terminal-shortcut
[org/gnome/settings-daemon/plugins/media-keys]
custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
name='Terminal'
command='ptyxis'
binding='<Ctrl><Alt>t'
EOF
dconf update

echo "--- การติดตั้งเสร็จสมบูรณ์ กรุณา Reboot ---"