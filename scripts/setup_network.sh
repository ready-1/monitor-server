#!/bin/bash
#
# setup_network.sh - Comprehensive network setup after fresh Debian 12 install
# This script prepares the server for Ansible deployment by configuring static IP,
# SSH, and required network dependencies.
#
# Usage: ./setup_network.sh
#
# Optional: Create network-config.defaults file with variables:
# STATIC_IP="10.211.55.99"
# NETMASK="24"
# GATEWAY="10.211.55.1"
# DNS_SERVERS="1.1.1.1,8.8.8.8"
#
# Author: Ready-1 LLC
#

set -e  # Exit on any error

# Load configuration defaults if available
CONFIG_FILE="$(dirname "$0")/network-config.defaults"

# Network configuration (interactive with optional defaults file)
if [ -f "$CONFIG_FILE" ]; then
    echo "Loading defaults from $CONFIG_FILE..."
    source "$CONFIG_FILE" 2>/dev/null || true
else
    echo "No defaults file found at $CONFIG_FILE - proceeding with interactive setup"
fi

# Function to prompt with optional default
prompt_with_default() {
    local var_name="$1"
    local prompt_text="$2"
    local current_value="${!var_name}"

    if [ -n "$current_value" ]; then
        echo -n "$prompt_text [$current_value]: "
        read -r input
        if [ -z "$input" ]; then
            return 0  # Keep current value
        else
            eval "$var_name=\"$input\""
        fi
    else
        echo -n "$prompt_text: "
        read -r input
        eval "$var_name=\"$input\""
    fi
}

# Interactive network configuration
echo "Network Configuration (press Enter to keep defaults, or enter new values)"
echo "Leave blank to skip validation (will be tested later)"

prompt_with_default "STATIC_IP" "Enter static IP address"
prompt_with_default "NETMASK" "Enter netmask (default 24)"
[ -z "$NETMASK" ] && NETMASK="24"
prompt_with_default "GATEWAY" "Enter gateway IP"
prompt_with_default "DNS_SERVERS" "Enter DNS servers (comma-separated)"

echo "Network Configuration Summary:"
echo "  Static IP: $STATIC_IP/$NETMASK"
echo "  Gateway: $GATEWAY"
echo "  DNS Servers: $DNS_SERVERS"
echo "  SSH Public Key: ${SSH_PUBLIC_KEY:0:50}..."

echo "Configuration complete - ready for network setup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
echo_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
echo_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Trap for cleanup on error
cleanup() {
    if [ $? -ne 0 ]; then
        echo_error "Setup failed. System may be in inconsistent state."
        echo_warning "You may need to manually verify network connectivity before retrying."
        exit 1
    fi
}
trap cleanup EXIT

echo_info "Installing network dependencies..."

# Fix clock sync issues that can prevent apt from working
echo_info "Synchronizing system clock..."
apt install -y systemd-timesyncd
timedatectl set-ntp true

# Wait for NTP to sync
sleep 3

# Check if clock is now roughly synced (within a day)
CURRENT_TIME=$(date +%s)
EXPECTED_TIME=$(curl -s --max-time 5 http://worldtimeapi.org/api/timezone/America/Los_Angeles.txt 2>/dev/null | grep unixtime | cut -d'=' -f2 || echo "")

if [ -n "$EXPECTED_TIME" ]; then
    TIME_DIFF=$((CURRENT_TIME - EXPECTED_TIME))
    TIME_DIFF=${TIME_DIFF#-}  # Absolute value

    if [ "$TIME_DIFF" -gt 86400 ]; then
        echo_warning "System clock appears to be significantly off - will use relaxed apt validation"
        APT_OPTIONS="-o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false"
    else
        echo_success "System clock appears synchronized"
        APT_OPTIONS=""
    fi
else
    echo_warning "Could not verify clock sync - using relaxed apt validation"
    APT_OPTIONS="-o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false"
fi

# Update package lists with relaxed validation if needed
apt update $APT_OPTIONS

# Install complete netplan ecosystem
apt install -y $APT_OPTIONS \
    netplan.io \
    nplan \
    network-manager \
    iproute2 \
    dnsutils \
    curl \
    wget \
    openssh-server \
    openssh-client \
    whois \
    ufw \
    sudo

echo_success "Network dependencies installed"

# Step 2: Detect network interface
echo_info "Detecting primary network interface..."
INTERFACE=$(ip -br a | grep -v lo | grep UP | head -1 | awk '{print $1}')

if [ -z "$INTERFACE" ]; then
    echo_error "Could not detect network interface"
    exit 1
fi

echo_info "Primary interface detected: $INTERFACE"

# Step 3: Backup existing network configuration
echo_info "Backing up existing network configuration..."
cp /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Step 4: Create new netplan configuration
echo_info "Creating static IP netplan configuration..."
cat > /etc/netplan/01-static.yaml << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses:
        - $STATIC_IP/$NETMASK
      routes:
        - to: default
          via: $GATEWAY
          metric: 100
      nameservers:
        addresses: [$(echo $DNS_SERVERS | sed 's/,/","/g' | sed 's/^/"/;s/$/"/')]
EOF

# Fix file permissions for netplan configuration
chmod 600 /etc/netplan/01-static.yaml
chown root:root /etc/netplan/01-static.yaml

echo_success "Netplan configuration created"

# Step 5: Verify netplan syntax
echo_info "Validating netplan configuration syntax..."
if ! netplan generate; then
    echo_error "Netplan syntax validation failed"
    echo_info "Restoring backup configuration..."

    # Restore backup if it exists
    BACKUP_FILE=$(ls -t /etc/netplan/00-installer-config.yaml.backup.* 2>/dev/null | head -1)
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" /etc/netplan/00-installer-config.yaml
    fi
    exit 1
fi

echo_success "Netplan syntax is valid"

echo_success "Network configuration applied successfully!"
echo_info "Static IP configured: $STATIC_IP on interface $INTERFACE"
echo

echo_warning "⚠️  Server will reboot in 15 seconds to activate new network configuration"
echo_info "Press Enter to reboot immediately..."
echo

# Disable cleanup trap for reboot (prevents false failure messages)
trap '' EXIT

echo_success "Network configuration complete!"
echo_info "Press Enter to reboot now and activate the new static IP configuration..."
read -r input
echo_info "Rebooting now to activate new network configuration..."
sleep 2
reboot
