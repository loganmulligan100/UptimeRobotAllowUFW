#!/bin/sh

# URL to fetch the list of Uptime Robot IP addresses
UPTIME_ROBOT_IPS_URL="https://uptimerobot.com/inc/files/ips/IPv4andIPv6.txt"

# Initialize counters
ufw_deleted=0
ufw_created=0
ufw_ignored=0

ufw_add_ip () {
    if [ ! -z "$1" ]; then
        rule=$(LC_ALL=C sudo ufw allow from $1 comment "Uptime Robot")

        if [ "$rule" = 'Rule added' ] || [ "$rule" = 'Rule added (v6)' ]; then
            ufw_created=$((ufw_created+1))
            return
        fi
    fi

    ufw_ignored=$((ufw_ignored+1))
}

ufw_delete_ip () {
    if [ ! -z "$1" ]; then
        rule=$(LC_ALL=C sudo ufw delete allow from $1)

        if [ "$rule" = 'Rule deleted' ] || [ "$rule" = 'Rule deleted (v6)' ]; then
            ufw_deleted=$((ufw_deleted+1))
            return
        fi
    fi

    ufw_ignored=$((ufw_ignored+1))
}

ufw_purge_rules () {
    total=$(sudo ufw status numbered | awk '/# Uptime Robot$/ {++count} END {print count}')
    i=1

    if [ -z "$total" ]; then
        ufw_deleted=0
        return
    fi

    while [ $i -le $total ]; do
        ip=$(sudo ufw status numbered | awk '/# Uptime Robot$/{print $6; exit}')
        ufw_delete_ip $ip
        i=$((i+1))
    done
}

show_progress() {
    local current=$1
    local total=$2
    local progress=$((current * 100 / total))
    local done=$((progress * 4 / 10))
    local left=$((40 - done))
    local fill=$(printf "%${done}s")
    local empty=$(printf "%${left}s")
    printf "\rProgress: [${fill// /#}${empty// /-}] ${progress}%%"
}

if [ "$1" = "--purge" ]; then
    ufw_purge_rules
else
    ips=$(curl -s $UPTIME_ROBOT_IPS_URL | tr '\r' '\n' | tr -s '\n')
    total_ips=$(echo "$ips" | wc -l)
    current_ip=0

    for ip in $ips; do
        ufw_add_ip "$ip"
        current_ip=$((current_ip + 1))
        show_progress $current_ip $total_ips
    done
    echo ""
    sudo ufw reload
fi

echo ''
echo "Total rules deleted: ${ufw_deleted}"
echo "Total rules created: ${ufw_created}"
echo "Total rules ignored: ${ufw_ignored}"
echo 'Done.'
