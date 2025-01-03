#!/bin/bash
# Script to change the IP address of the main NIC on debian 11/12
# By David Mear (MK) | Jan 2025

# Check if sudo is installed and install if not
if ! command -v sudo &> /dev/null; then
    echo "sudo is not installed. Installing sudo..."
    apt-get update
    apt-get install -y sudo
fi

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

# Check if the user is connected via SSH
if [ -n "$SSH_CONNECTION" ]; then
    read -p "You are connected via SSH. You will be disconnected from the host when changes are made. Do you want to continue? (yes/no): " CONTINUE
    if [ "$CONTINUE" != "yes" ]; then
        echo "Exiting script."
        exit 1
    fi
fi

# Auto-detect the network interface
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')

# Prompt for IP address, netmask, gateway, and DNS settings
read -p "Enter the new IP address: " NEW_IP
read -p "Enter the netmask: " NETMASK
read -p "Enter the gateway: " GATEWAY
read -p "Enter the DNS domain: " DNS_DOMAIN
read -p "Enter the DNS nameservers (space-separated): " DNS_NAMESERVERS

# Make a backup of the original interfaces file
sudo cp /etc/network/interfaces /etc/network/interfaces.bak

# Update the /etc/network/interfaces file
sudo bash -c "cat > /etc/network/interfaces <<EOF
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto $INTERFACE
iface $INTERFACE inet static
 address $NEW_IP
 netmask $NETMASK
 gateway $GATEWAY
 dns-domain $DNS_DOMAIN
 dns-nameservers $DNS_NAMESERVERS
EOF"

# Restart networking services
sudo systemctl restart networking

# Display the new IP address
echo "New IP address for $INTERFACE is $NEW_IP"