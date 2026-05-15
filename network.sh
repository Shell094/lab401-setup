#!/bin/bash
# ============================================================
# Lab401 Static IP Setup — nmcli + MAC lookup
# Ubuntu Desktop 26.04 (EdUbuntu)
# ใช้งาน: sudo ./network.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC}    $*"; }
info() { echo -e "${CYAN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*"; }
die()  { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ============================================================
# MAC → hostname:ip
# ============================================================
declare -A HOST_MAP
HOST_MAP["f4:f1:9e:2c:5b:17"]="Lab401-PC01:172.16.1.101"
HOST_MAP["f4:f1:9e:2c:5b:39"]="Lab401-PC02:172.16.1.102"
HOST_MAP["f4:f1:9e:2c:5d:11"]="Lab401-PC03:172.16.1.103"
HOST_MAP["f4:f1:9e:2c:5b:09"]="Lab401-PC04:172.16.1.104"
HOST_MAP["f4:f1:9e:2c:5b:d5"]="Lab401-PC05:172.16.1.105"
HOST_MAP["f4:f1:9e:2c:5c:86"]="Lab401-PC06:172.16.1.106"
HOST_MAP["f4:f1:9e:2c:57:15"]="Lab401-PC07:172.16.1.107"
HOST_MAP["f4:f1:9e:2c:56:ae"]="Lab401-PC08:172.16.1.108"
HOST_MAP["f4:f1:9e:2c:5c:eb"]="Lab401-PC09:172.16.1.109"
HOST_MAP["f4:f1:9e:2c:5b:04"]="Lab401-PC10:172.16.1.110"
HOST_MAP["f4:f1:9e:2c:5c:bc"]="Lab401-PC11:172.16.1.111"
HOST_MAP["f4:f1:9e:2c:5b:89"]="Lab401-PC12:172.16.1.112"
HOST_MAP["f4:f1:9e:2c:55:fd"]="Lab401-PC13:172.16.1.113"
HOST_MAP["f4:f1:9e:2c:5c:6b"]="Lab401-PC14:172.16.1.114"
HOST_MAP["f4:f1:9e:2c:5b:21"]="Lab401-PC15:172.16.1.115"
HOST_MAP["f4:f1:9e:2c:5c:79"]="Lab401-PC16:172.16.1.116"
HOST_MAP["f4:f1:9e:2c:5b:1b"]="Lab401-PC17:172.16.1.117"
HOST_MAP["f4:f1:9e:2c:5a:fd"]="Lab401-PC18:172.16.1.118"
HOST_MAP["f4:f1:9e:2c:5b:16"]="Lab401-PC19:172.16.1.119"
HOST_MAP["f4:f1:9e:2c:56:7c"]="Lab401-PC20:172.16.1.120"
HOST_MAP["f4:f1:9e:2c:5d:03"]="Lab401-PC21:172.16.1.121"
HOST_MAP["f4:f1:9e:2c:5b:0f"]="Lab401-PC22:172.16.1.122"
HOST_MAP["f4:f1:9e:2c:5b:03"]="Lab401-PC23:172.16.1.123"
HOST_MAP["f4:f1:9e:2c:5b:7d"]="Lab401-PC24:172.16.1.124"
HOST_MAP["f4:f1:9e:2c:5b:2b"]="Lab401-PC25:172.16.1.125"
HOST_MAP["f4:f1:9e:2c:5b:b5"]="Lab401-PC26:172.16.1.126"
HOST_MAP["f4:f1:9e:2c:57:a2"]="Lab401-PC27:172.16.1.127"
HOST_MAP["f4:f1:9e:2c:5b:e5"]="Lab401-PC28:172.16.1.128"
HOST_MAP["f4:f1:9e:2c:5b:42"]="Lab401-PC29:172.16.1.129"
HOST_MAP["f4:f1:9e:2c:5b:23"]="Lab401-PC30:172.16.1.130"
HOST_MAP["f4:f1:9e:2c:5c:95"]="Lab401-PC31:172.16.1.131"
HOST_MAP["f4:f1:9e:2c:5b:34"]="Lab401-PC32:172.16.1.132"
HOST_MAP["f4:f1:9e:2c:5b:01"]="Lab401-PC33:172.16.1.133"
HOST_MAP["f4:f1:9e:2c:5d:71"]="Lab401-PC34:172.16.1.134"
HOST_MAP["f4:f1:9e:2c:5b:07"]="Lab401-PC35:172.16.1.135"
HOST_MAP["f4:f1:9e:2c:5b:26"]="Lab401-PC36:172.16.1.136"
HOST_MAP["f4:f1:9e:2c:5c:8a"]="Lab401-PC37:172.16.1.137"
HOST_MAP["f4:f1:9e:2c:5c:8f"]="Lab401-PC38:172.16.1.138"
HOST_MAP["f4:f1:9e:2c:5b:40"]="Lab401-PC39:172.16.1.139"
HOST_MAP["f4:f1:9e:2c:5b:2d"]="Lab401-PC40:172.16.1.140"

# ---------- Network settings ----------
GATEWAY="172.16.1.254"
DNS1="203.158.177.9"
DNS2="203.158.178.11"

# ============================================================
# ตรวจสอบสิทธิ์และ dependencies
# ============================================================
[[ $EUID -eq 0 ]] || die "ต้องรันด้วย root: sudo $0"
command -v nmcli &>/dev/null || die "ไม่พบ nmcli — NetworkManager ต้องติดตั้งก่อน"
systemctl is-active --quiet NetworkManager || die "NetworkManager ไม่ได้รัน"

# ============================================================
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║   Lab401 Static IP Setup (nmcli)         ║"
echo "║   Ubuntu Desktop 26.04 (EdUbuntu)        ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================================
# หา interface และ MAC address จริงของเครื่อง
# ============================================================
info "กำลังอ่าน MAC address..."

IFACE=""
MAC=""
HOSTNAME_NEW=""
IP_ADDR=""

for iface_candidate in $(ls /sys/class/net/ \
    | grep -Ev '^(lo|docker|veth|virbr|br-|tun|tap|wl)' | sort); do
    mac_raw=$(cat "/sys/class/net/${iface_candidate}/address" 2>/dev/null || true)
    [[ -z "$mac_raw" || "$mac_raw" == "00:00:00:00:00:00" ]] && continue
    mac_lower="${mac_raw,,}"
    if [[ -n "${HOST_MAP[$mac_lower]+_}" ]]; then
        IFACE="$iface_candidate"
        MAC="$mac_lower"
        HOSTNAME_NEW="${HOST_MAP[$mac_lower]%%:*}"
        IP_ADDR="${HOST_MAP[$mac_lower]##*:}"
        break
    fi
done

# ============================================================
# ถ้าไม่พบ MAC ใน HOST_MAP — ให้ผู้ใช้เลือก PC หมายเลข
# ============================================================
if [[ -z "$MAC" ]]; then
    err "ไม่พบ MAC address ที่ตรงกับ HOST_MAP!"
    echo ""
    echo -e "${YELLOW}MAC address ของเครื่องนี้:${NC}"

    IFACE_LIST=()
    MAC_LIST=()
    for iface_show in $(ls /sys/class/net/ \
        | grep -Ev '^(lo|docker|veth|virbr|br-|tun|tap|wl)' | sort); do
        m=$(cat "/sys/class/net/${iface_show}/address" 2>/dev/null || echo "N/A")
        echo "  $iface_show  →  $m"
        IFACE_LIST+=("$iface_show")
        MAC_LIST+=("$m")
    done
    echo ""

    if [[ ${#IFACE_LIST[@]} -gt 1 ]]; then
        echo "พบหลาย interface:"
        for i in "${!IFACE_LIST[@]}"; do
            echo "  [$((i+1))] ${IFACE_LIST[$i]}  (${MAC_LIST[$i]})"
        done
        read -rp "เลือก interface หมายเลข [1-${#IFACE_LIST[@]}]: " iface_choice
        iface_idx=$((iface_choice - 1))
    else
        iface_idx=0
    fi

    IFACE="${IFACE_LIST[$iface_idx]}"
    MAC="${MAC_LIST[$iface_idx],,}"

    echo ""
    echo -e "${CYAN}เลือก PC หมายเลขสำหรับเครื่องนี้:${NC}"
    echo "  (IP จะถูกกำหนดเป็น 172.16.1.1XX โดยอัตโนมัติ)"
    echo ""
    read -rp "ป้อนหมายเลข PC (1-40): " pc_num

    if ! [[ "$pc_num" =~ ^[0-9]+$ ]] || \
       [[ "$pc_num" -lt 1 ]] || [[ "$pc_num" -gt 40 ]]; then
        die "หมายเลข PC ไม่ถูกต้อง (ต้องอยู่ระหว่าง 1-40)"
    fi

    pc_num_padded=$(printf "%02d" "$pc_num")
    HOSTNAME_NEW="Lab401-PC${pc_num_padded}"
    IP_ADDR="172.16.1.$((100 + pc_num))"

    for existing_mac in "${!HOST_MAP[@]}"; do
        existing_ip="${HOST_MAP[$existing_mac]##*:}"
        if [[ "$existing_ip" == "$IP_ADDR" ]]; then
            warn "IP $IP_ADDR ถูก assign ให้ MAC $existing_mac ใน HOST_MAP แล้ว"
            read -rp "ยังต้องการใช้ IP นี้? (y/N): " force_confirm
            [[ "${force_confirm,,}" == "y" ]] || die "ยกเลิก"
            break
        fi
    done

    HOST_MAP["$MAC"]="${HOSTNAME_NEW}:${IP_ADDR}"

    SCRIPT_PATH="$(realpath "$0")"
    if [[ -w "$SCRIPT_PATH" ]]; then
        sed -i "/# ---------- Network settings ----------/i \
HOST_MAP[\"$MAC\"]=\"${HOSTNAME_NEW}:${IP_ADDR}\"" "$SCRIPT_PATH"
        ok "บันทึก MAC → $HOSTNAME_NEW:$IP_ADDR ลงในสคริปต์แล้ว"
    else
        warn "ไม่สามารถแก้ไขสคริปต์ได้ (read-only) — MAC จะไม่ถูกบันทึกถาวร"
    fi
fi

ok "พบเครื่อง!"
echo ""
echo -e "${YELLOW}─── ข้อมูลเครื่องนี้ ──────────────────────${NC}"
echo "  Interface : $IFACE"
echo "  MAC       : $MAC"
echo "  Hostname  : $HOSTNAME_NEW"
echo "  IP        : $IP_ADDR/24"
echo "  Gateway   : $GATEWAY"
echo "  DNS       : $DNS1, $DNS2"
echo -e "${YELLOW}──────────────────────────────────────────${NC}"
echo ""
read -rp "ยืนยันตั้งค่า? (y/N): " confirm
[[ "${confirm,,}" == "y" ]] || { warn "ยกเลิก"; exit 0; }

# ============================================================
# ตั้ง Hostname
# ============================================================
info "ตั้ง hostname → $HOSTNAME_NEW"
hostnamectl set-hostname "$HOSTNAME_NEW"
sed -i '/^127\.0\.1\.1/d' /etc/hosts
echo "127.0.1.1  $HOSTNAME_NEW" >> /etc/hosts
ok "Hostname: $(hostname)"

# ============================================================
# ตั้ง Static IP ด้วย nmcli
# ============================================================
info "ตั้งค่า Static IP ด้วย nmcli..."

CON_NAME=$(nmcli -t -f NAME,DEVICE connection show \
    | grep ":${IFACE}$" | cut -d: -f1 | head -1 || true)

if [[ -z "$CON_NAME" ]]; then
    CON_NAME="lab401-${IFACE}"
    warn "ไม่พบ connection — สร้างใหม่: $CON_NAME"
    nmcli connection add \
        type ethernet \
        con-name "$CON_NAME" \
        ifname   "$IFACE"
fi

info "แก้ไข connection: $CON_NAME"
nmcli connection modify "$CON_NAME" \
    ipv4.method    manual \
    ipv4.addresses "${IP_ADDR}/24" \
    ipv4.gateway   "$GATEWAY" \
    ipv4.dns       "${DNS1},${DNS2}" \
    ipv4.dns-search "" \
    ipv6.method    disabled

nmcli connection down "$CON_NAME" 2>/dev/null || true
sleep 1
nmcli connection up "$CON_NAME"
ok "Static IP ตั้งค่าเรียบร้อย"

# ============================================================
# ทดสอบ
# ============================================================
info "ทดสอบ network..."
sleep 3
echo ""
echo "─── ผลการทดสอบ ────────────────────────────"
ping -c 2 -W 2 "$GATEWAY" &>/dev/null \
    && ok "Ping Gateway ($GATEWAY) ✓" \
    || warn "Ping Gateway ล้มเหลว"
ping -c 2 -W 2 8.8.8.8 &>/dev/null \
    && ok "Ping Internet (8.8.8.8) ✓" \
    || warn "Ping Internet ล้มเหลว"

# ============================================================
# สรุป
# ============================================================
echo ""
echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         Setup เสร็จสมบูรณ์            ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC} Hostname : ${GREEN}$HOSTNAME_NEW${NC}"
echo -e "${CYAN}║${NC} IP       : ${GREEN}$IP_ADDR/24${NC}"
echo -e "${CYAN}║${NC} Gateway  : ${GREEN}$GATEWAY${NC}"
echo -e "${CYAN}║${NC} MAC      : ${GREEN}$MAC${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""
warn "แนะนำให้ reboot: sudo reboot"
