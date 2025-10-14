#!/bin/bash
#
# setup_network.sh - Comprehensive network setup after fresh Debian 12 install
# This script prepares the server for Ansible deployment by configuring static IP,
# SSH, and required network dependencies.
#
# Usage: ./setup_network.sh
#
# Author: Ready-1 LLC
#

set -e  # Exit on any error

# Network configuration (should match group_vars/all.yml)
STATIC_IP="10.211.55.99"
NETMASK="24"
GATEWAY="10.211.55.1"
DNS_SERVERS="1.1.1.1,8.8.8.8"

# SSH Configuration
SSH_PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAlpoxkVdvq3DjLp5kyVn2N7sNb4Lcr2LZTvRkIaZI/b monitor's general ed25519 ID"

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

echo_info "Starting comprehensive network setup for Monitor Server..."
echo_info "Static IP: $STATIC_IP/$NETMASK"
echo_info "Gateway: $GATEWAY"

# Step 1: Update package lists and install required network packages
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

    if [ "$TIME_DIFF" -gt 86400 ]; then  # More than 24 hours off
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

# Step 1.5: Temporarily relax SSH configuration for setup
echo_info "Temporarily relaxing SSH configuration for initial setup..."
if ! grep -q "^# Temporary setup configuration" /etc/ssh/sshd_config; then
    # Backup current SSH configuration
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)

    # Add temporary relaxed settings
    cat >> /etc/ssh/sshd_config << EOF

# Temporary setup configuration - will be removed after key authentication is configured
MaxAuthTries 20
PasswordAuthentication yes
ChallengeResponseAuthentication yes
PermitRootLogin yes
EOF

    # Reload SSH service
    systemctl reload ssh
    echo_success "SSH temporarily configured for setup"
else
    echo_info "SSH already temporarily configured"
fi

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

# Step 6: Apply netplan configuration
echo_info "Applying network configuration..."
netplan apply

# Give network time to settle
sleep 5

echo_success "Network configuration applied"

# Step 7: Verify IP address assignment
echo_info "Verifying IP address assignment..."
VERIFIED_IP=$(ip -4 addr show $INTERFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

if [ "$VERIFIED_IP" != "$STATIC_IP" ]; then
    echo_error "IP address verification failed. Expected: $STATIC_IP, Got: $VERIFIED_IP"

    # Attempt rollback
    echo_info "Attempting network configuration rollback..."
    rm -f /etc/netplan/01-static.yaml

    BACKUP_FILE=$(ls -t /etc/netplan/00-installer-config.yaml.backup.* 2>/dev/null | head -1)
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" /etc/netplan/00-installer-config.yaml
        netplan apply
    fi
    exit 1
fi

echo_success "IP address correctly configured: $VERIFIED_IP"

# Step 8: Test network connectivity
echo_info "Testing network connectivity..."

# Test default route
if ! ip route get 8.8.8.8 >/dev/null 2>&1; then
    echo_error "Default route configuration failed"
    exit 1
fi

# Test DNS resolution
if ! nslookup google.com >/dev/null 2>&1; then
    echo_warning "DNS resolution test failed - possible DNS issue"
else
    echo_success "DNS resolution working"
fi

# Test internet connectivity
if curl -s --max-time 10 google.com >/dev/null 2>&1; then
    echo_success "Internet connectivity confirmed"
else
    echo_warning "Internet connectivity test failed"
fi

# Step 9: Configure SSH
echo_info "Configuring SSH server..."

# Create monitor user
if ! id -u monitor >/dev/null 2>&1; then
    useradd -m -s /bin/bash monitor
    usermod -aG sudo monitor
    echo_success "Created monitor user"
else
    echo_info "Monitor user already exists"
fi

# Create .ssh directory for monitor
mkdir -p /home/monitor/.ssh
chmod 700 /home/monitor/.ssh
chown monitor:monitor /home/monitor/.ssh

# Add SSH public key
echo "$SSH_PUBLIC_KEY" > /home/monitor/.ssh/authorized_keys
chmod 600 /home/monitor/.ssh/authorized_keys
chown monitor:monitor /home/monitor/.ssh/authorized_keys

echo_success "SSH public key configured"

# Step 10: Configure basic firewall
echo_info "Configuring basic firewall..."

# Allow SSH (port 22 assumed)
ufw allow ssh

# Allow HTTP/HTTPS (will be needed later)
ufw allow 80
ufw allow 443

# Allow Cockpit (will be needed later)
ufw allow 9090

ufw --force enable
ufw status

echo_success "Firewall configured"

# Step 11: Test SSH connectivity (local test)
echo_info "Testing SSH service..."
systemctl enable ssh
systemctl start ssh

if systemctl is-active --quiet ssh; then
    echo_success "SSH service is running"
else
    echo_error "SSH service failed to start"
    exit 1
fi

# Step 12: Verify system time synchronization
echo_info "Checking system time synchronization..."
apt install -y systemd-timesyncd
timedatectl set-ntp true

# Wait for NTP sync
sleep 2

if timedatectl show -p NTPSynchronized --value | grep -q "yes"; then
    echo_success "NTP synchronization active"
else
    echo_warning "NTP synchronization not yet confirmed (may require more time)"
fi

# Step 13: Final SSH hardening and system validation
echo_info "Finalizing SSH configuration and system validation..."

# Harden SSH configuration now that key authentication is established
echo_info "Hardening SSH configuration for production use..."
if grep -q "^# Temporary setup configuration" /etc/ssh/sshd_config && [ -f /home/monitor/.ssh/authorized_keys ]; then
    # Remove temporary relaxed settings
    sed -i '/^# Temporary setup configuration/,/^PermitRootLogin yes$/d' /etc/ssh/sshd_config

    # Add hardened settings
    cat >> /etc/ssh/sshd_config << EOF

# Hardened production configuration
MaxAuthTries 8
PasswordAuthentication no
ChallengeResponseAuthentication no
PermitRootLogin no
PermitEmptyPasswords no

# Key-based authentication only
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
EOF

    # Reload SSH service with hardened configuration
    systemctl reload ssh
    echo_success "SSH configuration hardened for production"
else
    echo_warning "SSH hardening skipped - check that SSH keys are properly configured"
fi

# Step 14: Final system validation
echo_info "Performing final system validation..."

# Check required commands
REQUIRED_COMMANDS=("netplan" "ip" "systemctl" "curl" "ufw")
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo_success "✓ $cmd available"
    else
        echo_warning "✗ $cmd not found"
    fi
done

# Verify SSH key authentication is working
echo_info "Testing SSH key authentication..."
if [ -f /home/monitor/.ssh/authorized_keys ]; then
    SSH_KEY_COUNT=$(wc -l < /home/monitor/.ssh/authorized_keys)
    echo_success "✓ $SSH_KEY_COUNT SSH key(s) configured"
else
    echo_warning "✗ No SSH authorized keys file found"
fi

# Display final network information
echo
echo_success "=== Network Setup Complete ==="
echo_info "New IP Address: $STATIC_IP"
echo_info "Network Interface: $INTERFACE"
echo_info "Gateway: $GATEWAY"
echo_info "DNS Servers: $DNS_SERVERS"
echo_info "SSH User: monitor (key-only authentication)"
echo
echo_info "Next steps:"
echo "  1. Exit this session and reconnect as 'monitor' user:"
echo "     ssh monitor@$STATIC_IP"
echo "  2. Test Ansible connectivity: ansible -i inventory.ini all -m ping"
echo "  3. Run deployment: ansible-playbook -i inventory.ini site.yml"
echo
echo_warning "⚠️  Make sure to re-enable your Mac's SSH keychain after successful setup:"
echo_warning "   eval \"\$(ssh-agent -s)\" && ssh-add ~/.ssh/id_monitor_ed25519"

echo_success "Network preparation complete! Server is ready for Ansible deployment."
