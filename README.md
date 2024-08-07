### README

- Make all sh files executable 
  `chmod +x filename.sh `

- Delete old configurations if necessary.

- Disable IPV6 to avoid leaks. Best to reboot after and ensure it has been disabled:
  `ip a | grep inet6` 

- Bulk import VPN configs to NetworkManager
    `./bulk_import_vpns.sh /path/to/ovpn/files surfshark_username surfshark_password`
