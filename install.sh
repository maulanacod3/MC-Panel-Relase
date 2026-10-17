#!/usr/bin/env bash
# ==============================================================================
# MC-Panel (MCode Server & App Control Panel) Universal Installer
# Supported OS: 
#   - Ubuntu 20.04 / 22.04 / 24.04
#   - Debian 10 / 11 / 12
#   - AlmaLinux 8 / 9
#   - Rocky Linux 8 / 9
#   - CentOS 7 / 8 / 9 Stream & RHEL 8 / 9
# ==============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}${BOLD} 🚀 Installing MC-Panel Universal Server Manager ${NC}"
echo -e "${CYAN}======================================================${NC}"

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}[ERROR] Installer must be run as root (sudo).${NC}"
    exit 1
fi

# Options / Flags
INSTALL_MYSQL=${INSTALL_MYSQL:-true}

for arg in "$@"; do
    case "$arg" in
        --no-mysql|--without-mysql)
            INSTALL_MYSQL=false
            ;;
        --with-mysql)
            INSTALL_MYSQL=true
            ;;
    esac
done

# Detect Operating System Family
OS_FAMILY=""
OS_NAME=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME="$NAME $VERSION_ID"
    case "$ID" in
        ubuntu|debian|linuxmint|pop)
            OS_FAMILY="debian"
            ;;
        almalinux|rocky|centos|rhel|ol|fedora)
            OS_FAMILY="rhel"
            ;;
        *)
            if [[ "$ID_LIKE" =~ (debian|ubuntu) ]]; then
                OS_FAMILY="debian"
            elif [[ "$ID_LIKE" =~ (rhel|fedora|centos) ]]; then
                OS_FAMILY="rhel"
            else
                OS_FAMILY="unknown"
            fi
            ;;
    esac
else
    echo -e "${RED}[ERROR] Unable to detect OS from /etc/os-release.${NC}"
    exit 1
fi

echo -e "${CYAN}[*] Detected OS   : ${GREEN}${OS_NAME} (${OS_FAMILY})${NC}"
echo -e "${CYAN}[*] Install MySQL : $([ "$INSTALL_MYSQL" = "true" ] && echo -e "${GREEN}Yes (Default)${NC}" || echo -e "${YELLOW}No (Skipped by option)${NC})"

echo -e "${YELLOW}[1/5] Updating system packages & installing core stacks...${NC}"

if [ "$OS_FAMILY" = "debian" ]; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y

    MYSQL_PKGS=""
    if [ "$INSTALL_MYSQL" = "true" ]; then
        # Detect available MySQL/MariaDB package
        MYSQL_PKG="default-mysql-server"
        if apt-cache show default-mysql-server >/dev/null 2>&1; then
            MYSQL_PKG="default-mysql-server"
        elif apt-cache show mariadb-server >/dev/null 2>&1; then
            MYSQL_PKG="mariadb-server"
        elif apt-cache show mysql-server >/dev/null 2>&1; then
            MYSQL_PKG="mysql-server"
        fi
        MYSQL_PKGS="${MYSQL_PKG}"
        echo -e "MySQL/MariaDB will be installed (${GREEN}${MYSQL_PKG}${NC})."
    else
        echo -e "${YELLOW}[!] Skipping MySQL/MariaDB installation (user option: --no-mysql / INSTALL_MYSQL=false).${NC}"
    fi

    echo -e "Installing Debian/Ubuntu packages..."
    apt-get install -y curl wget git unzip nginx certbot python3-certbot-nginx ufw postgresql postgresql-contrib ${MYSQL_PKGS} php-fpm php-cli php-mysql php-pgsql php-mbstring php-xml php-curl php-zip php-bcmath php-gd php-sqlite3 || {
        echo -e "${YELLOW}Retrying with essential packages...${NC}"
        apt-get install -y curl wget git unzip nginx certbot ufw postgresql ${MYSQL_PKGS} php-fpm php-cli php-mysql php-pgsql php-mbstring
    }

elif [ "$OS_FAMILY" = "rhel" ]; then
    PKG_MGR="dnf"
    if ! command -v dnf >/dev/null 2>&1; then
        PKG_MGR="yum"
    fi

    echo -e "Enabling EPEL repository on ${OS_NAME}..."
    $PKG_MGR install -y epel-release || true
    $PKG_MGR update -y --skip-broken || true

    RHEL_MYSQL_PKGS=""
    if [ "$INSTALL_MYSQL" = "true" ]; then
        RHEL_MYSQL_PKGS="mariadb-server mariadb"
        echo -e "MySQL/MariaDB will be installed (${GREEN}mariadb-server${NC})."
    else
        echo -e "${YELLOW}[!] Skipping MariaDB installation (user option: --no-mysql / INSTALL_MYSQL=false).${NC}"
    fi

    echo -e "Installing RHEL/AlmaLinux packages via ${PKG_MGR}..."
    $PKG_MGR install -y curl wget git unzip nginx certbot python3-certbot-nginx firewalld postgresql-server postgresql-contrib ${RHEL_MYSQL_PKGS} php-fpm php-cli php-mysqlnd php-pgsql php-mbstring php-xml php-gd php-bcmath php-zip php-json php-pdo || {
        echo -e "${YELLOW}Retrying with core packages...${NC}"
        $PKG_MGR install -y curl wget git unzip nginx certbot postgresql-server ${RHEL_MYSQL_PKGS} php-fpm php-cli php-mysqlnd php-pgsql
    }

    # Initialize PostgreSQL data cluster if not already done on RHEL/CentOS
    if [ ! -f /var/lib/pgsql/data/PG_VERSION ]; then
        echo -e "Initializing PostgreSQL database cluster..."
        postgresql-setup --initdb 2>/dev/null || postgresql-setup initdb 2>/dev/null || true
    fi

    # Enable and start underlying services on RHEL/CentOS
    SERVICES_TO_ENABLE="nginx postgresql php-fpm"
    if [ "$INSTALL_MYSQL" = "true" ]; then
        SERVICES_TO_ENABLE="$SERVICES_TO_ENABLE mariadb"
    fi
    systemctl enable --now ${SERVICES_TO_ENABLE} 2>/dev/null || true

else
    echo -e "${RED}[ERROR] Unsupported OS family. Please run on Ubuntu, Debian, AlmaLinux, Rocky, or CentOS.${NC}"
    exit 1
fi

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
After=network.target nginx.service postgresql.service mysql.service mariadb.service

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

echo -e "${YELLOW}[5/5] Configuring firewall ports (80, 443, 9090)...${NC}"
if command -v ufw >/dev/null 2>&1 && systemctl is-active --quiet ufw; then
    ufw allow 80/tcp || true
    ufw allow 443/tcp || true
    ufw allow 9090/tcp || true
elif command -v firewall-cmd >/dev/null 2>&1; then
    systemctl enable --now firewalld 2>/dev/null || true
    if systemctl is-active --quiet firewalld; then
        firewall-cmd --permanent --add-port=80/tcp 2>/dev/null || true
        firewall-cmd --permanent --add-port=443/tcp 2>/dev/null || true
        firewall-cmd --permanent --add-port=9090/tcp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
    fi
fi

# Detect Server IP
SERVER_IP=$(curl -s4 ifconfig.me || curl -s4 icanhazip.com || hostname -I | awk '{print $1}')

echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}${BOLD}  🎉 MC-Panel Installed Successfully on ${OS_NAME}! ${NC}"
echo -e "${CYAN}  Access URL   : ${BOLD}http://${SERVER_IP}:9090${NC}"
echo -e "${CYAN}  Default User : ${BOLD}admin${NC}"
echo -e "${CYAN}  Default Pass : ${BOLD}admin123${NC}"
echo -e "${CYAN}======================================================${NC}"
