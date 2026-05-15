#!/bin/bash
# URL สำหรับดึงไฟล์สคริปต์: http://172.16.81.X/install.sh

# 1. ประกาศตัวแปร URL ของ Server กลาง (ปรับ IP ตามจริง)
SERVER_URL="http://172.16.81.1" 

echo "--- เริ่มดาวน์โหลดและติดตั้งระบบจาก Server ---"

# 2. ดาวน์โหลดไฟล์ CA Certificate (ข้อ 17)
sudo wget -O /etc/ssl/certs/coe-ldap-ca.crt $SERVER_URL/coe-ldap-ca.crt

# 3. ดาวน์โหลดและรันสคริปต์จัดการ Network (IP Static ตาม MAC)
wget -O network_setup.sh $SERVER_URL/network.sh
chmod +x network_setup.sh
sudo ./network_setup.sh

# 4. ดาวน์โหลดและรันสคริปต์ติดตั้ง Software ทั้งหมด (ข้อ 1-22)
wget -O software_setup.sh $SERVER_URL/setup_lab.sh
chmod +x software_setup.sh
sudo ./software_setup.sh

echo "--- ติดตั้งทุกอย่างเรียบร้อย กำลัง Reboot ---"
sleep 5
sudo reboot