#!/bin/bash

# URL to fetch the list of Uptime Robot IP addresses
UPTIME_ROBOT_IPS_URL="https://uptimerobot.com/inc/files/ips/IPv4.txt"

# Temporary file to store the list of IP addresses
TEMP_IP_LIST="/tmp/uptimerobot_ips.txt"

# Fetch the list of IP addresses
curl -s $UPTIME_ROBOT_IPS_URL -o $TEMP_IP_LIST

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Failed to download the list of Uptime Robot IP addresses."
    exit 1
fi

# Read each IP address from the downloaded list and add it to UFW rules
while read -r ip; do
    # Trim any leading or trailing whitespace from the IP address
    ip=$(echo $ip | xargs)
    
    # Validate the IP address format
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        sudo ufw allow from $ip comment "Uptime Robot"
        if [ $? -ne 0 ]; then
            echo "Failed to add IP: $ip"
        else
            echo "Added IP: $ip"
        fi
    else
        echo "Invalid IP address format: $ip"
    fi
done < $TEMP_IP_LIST

# Reload UFW to apply the new rules
sudo ufw reload

# Clean up by removing the temporary IP list file
rm -f $TEMP_IP_LIST

echo "Uptime Robot IP addresses have been added to UFW rules."
