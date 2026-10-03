#!/usr/bin/env bash
# ==============================================================================
# MC-Panel (MCode Server & App Control Panel) Installer
# Target OS: Ubuntu 20.04/22.04/24.04, Debian 11/12
# ==============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN} 🚀 Installing MC-Panel Server Manager ${NC}"
echo -e "${CYAN}======================================================${NC}"

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[ERROR] Installer must be run as root (sudo).${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/5] Updating system packages & installing core stacks...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y

# Detect available MySQL/MariaDB package (Debian uses default-mysql-server / mariadb-server, Ubuntu uses mysql-server)
MYSQL_PKG="default-mysql-server"
if apt-cache show default-mysql-server >/dev/null 2>&1; then
    MYSQL_PKG="default-mysql-server"
elif apt-cache show mariadb-server >/dev/null 2>&1; then
    MYSQL_PKG="mariadb-server"
elif apt-cache show mysql-server >/dev/null 2>&1; then
    MYSQL_PKG="mysql-server"
fi

echo -e "Installing core dependencies with Database Engine: ${GREEN}${MYSQL_PKG}${NC}..."
apt-get install -y curl wget git unzip nginx certbot python3-certbot-nginx ufw postgresql ${MYSQL_PKG} php-fpm php-cli php-mysql php-pgsql php-mbstring php-xml php-curl php-zip php-bcmath php-gd php-sqlite3 || {
    echo -e "${YELLOW}Retrying without optional sub-packages...${NC}"
    apt-get install -y curl wget git unzip nginx certbot ufw postgresql ${MYSQL_PKG} php-fpm php-cli php-mysql php-pgsql php-mbstring
}

echo -e "${YELLOW}[2/5] Creating /opt/mc-panel directory & stopping existing daemon if running...${NC}"
systemctl stop mc-panel 2>/dev/null || true
mkdir -p /opt/mc-panel /etc/mc-panel /var/www /opt/mc-examgo

echo -e "${YELLOW}[3/5] Downloading MC-Panel Linux Binary...${NC}"
ARCH=$(uname -m)
BINARY_NAME="mc-panel-linux-amd64"
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    BINARY_NAME="mc-panel-linux-arm64"
fi

DOWNLOAD_URL="https://github.com/maulanacod3/MC-Panel-Relase/releases/latest/download/${BINARY_NAME}"
echo -e "Downloading: ${DOWNLOAD_URL}..."
if ! curl -sSL -f -o /opt/mc-panel/mc-panel.new "${DOWNLOAD_URL}"; then
    echo -e "${YELLOW}Mencoba download dari tag v1.0.0...${NC}"
    curl -sSL -f -o /opt/mc-panel/mc-panel.new "https://github.com/maulanacod3/MC-Panel-Relase/releases/download/v1.0.0/${BINARY_NAME}"
fi

chmod +x /opt/mc-panel/mc-panel.new
mv -f /opt/mc-panel/mc-panel.new /opt/mc-panel/mc-panel
chmod +x /opt/mc-panel/mc-panel

echo -e "${YELLOW}[4/5] Setting up systemd service unit mc-panel.service...${NC}"
cat << 'EOF' > /etc/systemd/system/mc-panel.service
[Unit]
Description=MC-Panel Server & App Control Daemon
After=network.target nginx.service postgresql.service mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/mc-panel
ExecStart=/opt/mc-panel/mc-panel
Restart=always
RestartSec=5
LimitNOFILE=65535
Environment=MC_PANEL_PORT=9090
Environment=MC_PANEL_DB=/etc/mc-panel/mc-panel.db

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now mc-panel
systemctl restart mc-panel

echo -e "${YELLOW}[5/5] Enabling firewall ports (80, 443, 9090)...${NC}"
ufw allow 80/tcp || true
ufw allow 443/tcp || true
ufw allow 9090/tcp || true

echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}  🎉 MC-Panel Base Infrastructure Installed Successfully! ${NC}"
echo -e "${CYAN}  Access URL: http://YOUR_VPS_IP:9090                 ${NC}"
echo -e "${CYAN}  Default User: admin | Pass: admin123                 ${NC}"
echo -e "${CYAN}======================================================${NC}"
