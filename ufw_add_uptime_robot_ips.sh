#!/bin/bash

# URL of the IP list from Uptime Robot
IP_LIST_URL="https://uptimerobot.com/inc/files/ips/IPv4andIPv6.txt"
TEMP_IP_FILE="uptime_robot_ips.txt"

# Download the IP list
curl -s $IP_LIST_URL -o $TEMP_IP_FILE

# Check if the file was downloaded
if [[ ! -f "$TEMP_IP_FILE" ]]; then
    echo "Failed to download the IP list from Uptime Robot!"
    exit 1
fi

# Read and add each IP to UFW
while IFS= read -r ip; do
    if [[ ! -z "$ip" ]]; then
        sudo ufw allow from $ip
        echo "Allowed IP: $ip"
    fi
done < "$TEMP_IP_FILE"

# Reload UFW to apply changes
sudo ufw reload
echo "UFW rules updated and reloaded."

# Clean up
rm $TEMP_IP_FILE
