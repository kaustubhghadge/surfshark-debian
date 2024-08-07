#!/bin/bash

# Function to delete VPN connections
delete_vpn_connections() {
    # Get all VPN connection UUIDs and names
    while IFS= read -r line; do
        uuid=$(echo "$line" | cut -d':' -f1)
        name=$(echo "$line" | cut -d':' -f2)
        echo "Deleting VPN connection: $name (UUID: $uuid)"
        sudo nmcli connection delete "$uuid"
    done < <(nmcli -t -f UUID,NAME,TYPE connection show | grep ':vpn$')

    echo "All VPN connections have been deleted."
}

# Main execution
echo "Deleting all VPN connections..."
delete_vpn_connections

# Restart NetworkManager to apply changes
echo "Restarting NetworkManager..."
sudo systemctl restart NetworkManager

echo "VPN cleanup complete."
