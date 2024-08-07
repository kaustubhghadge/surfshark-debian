#!/bin/bash

# Function to check if the script is run as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

# Function to disable IPv6 in sysctl.conf
disable_ipv6_sysctl() {
    echo "Disabling IPv6 in sysctl.conf..."
    cat >> /etc/sysctl.conf <<EOF

# Disable IPv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
    sysctl -p
}

# Function to disable IPv6 in GRUB
disable_ipv6_grub() {
    echo "Disabling IPv6 in GRUB..."
    if grep -q "ipv6.disable=1" /etc/default/grub; then
        echo "IPv6 is already disabled in GRUB."
    else
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="ipv6.disable=1 /' /etc/default/grub
        update-grub
    fi
}

# Function to disable IPv6 in NetworkManager
disable_ipv6_nm() {
    echo "Disabling IPv6 in NetworkManager..."
    cat > /etc/NetworkManager/conf.d/disable-ipv6.conf <<EOF
[connection]
ipv6.method=ignore
EOF
    systemctl restart NetworkManager
}

# Main function
main() {
    check_root
    disable_ipv6_sysctl
    disable_ipv6_grub
    disable_ipv6_nm
    echo "IPv6 has been disabled system-wide. Please reboot your system for all changes to take effect."
}

# Run the main function
main
