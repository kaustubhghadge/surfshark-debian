#!/bin/bash

# Variables
SOURCE_DIR="$1"
USERNAME="$2"
PASSWORD="$3"
DEST_DIR="$HOME/.config/openvpn"
CREDENTIALS_FILE="$DEST_DIR/credentials.txt"
CONFIG_FILE="server_names.conf"
SURFSHARK_DNS1="162.252.172.57"
SURFSHARK_DNS2="149.154.159.92"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Create the credentials file
echo -e "$USERNAME\n$PASSWORD" > "$CREDENTIALS_FILE"
chmod 600 "$CREDENTIALS_FILE"

# Function to get friendly name from remote address
get_friendly_name() {
    local remote="$1"
    local country_code=$(echo "$remote" | cut -d'-' -f1)
    local city_code=$(echo "$remote" | cut -d'-' -f2 | cut -d'.' -f1)
    
    local country=$(grep "^$country_code," "$CONFIG_FILE" | cut -d',' -f2 | head -n 1)
    local city=$(grep "^$country_code,.*,$city_code," "$CONFIG_FILE" | cut -d',' -f4)
    
    if [ -z "$country" ]; then
        country="Unknown"
    fi
    if [ -z "$city" ]; then
        city="Unknown"
    fi
    
    echo "$country ($city)"
}

# Loop through all .ovpn files in the source directory
for FILE in "$SOURCE_DIR"/*.ovpn; do
    if [ -f "$FILE" ]; then
        # Get the base name of the file
        BASENAME=$(basename "$FILE" .ovpn)
        
        # Copy the .ovpn file to the destination directory
        cp "$FILE" "$DEST_DIR/$BASENAME.ovpn"

        # Add 'block-outside-dns' to the .ovpn file
        echo "block-outside-dns" >> "$DEST_DIR/$BASENAME.ovpn"

        # Add Surfshark DNS servers
        echo "dhcp-option DNS $SURFSHARK_DNS1" >> "$DEST_DIR/$BASENAME.ovpn"
        echo "dhcp-option DNS $SURFSHARK_DNS2" >> "$DEST_DIR/$BASENAME.ovpn"

        # Add IPv6 disabling directives
        echo "pull-filter ignore \"route-ipv6\"" >> "$DEST_DIR/$BASENAME.ovpn"
        echo "pull-filter ignore \"ifconfig-ipv6\"" >> "$DEST_DIR/$BASENAME.ovpn"

        # Extract the remote address
        REMOTE=$(grep -m 1 '^remote ' "$DEST_DIR/$BASENAME.ovpn" | awk '{print $2}')
        FRIENDLY_NAME=$(get_friendly_name "$REMOTE")

        # Import the .ovpn file into NetworkManager
        sudo nmcli connection import type openvpn file "$DEST_DIR/$BASENAME.ovpn"

        # Modify the imported connection to use the credentials and set the friendly name
        CONNECTION_NAME=$(nmcli -t -f NAME connection show | grep "$BASENAME")
        sudo nmcli connection modify "$CONNECTION_NAME" +vpn.data "username=$USERNAME,password-flags=0"
        sudo nmcli connection modify "$CONNECTION_NAME" +vpn.secrets "password=$PASSWORD"
        sudo nmcli connection modify "$CONNECTION_NAME" connection.id "$FRIENDLY_NAME"

        echo "Imported $FILE as $FRIENDLY_NAME"
    else
        echo "No .ovpn files found in $SOURCE_DIR"
    fi
done

# Restart NetworkManager to apply changes
sudo systemctl restart NetworkManager

echo "All VPN configurations have been added and imported into NetworkManager."
