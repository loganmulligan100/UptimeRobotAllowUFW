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
    while IFS= read -r line; do
        if echo "$line" | grep -q '# Uptime Robot'; then
            number=$(echo "$line" | awk '{print $1}' | tr -d '[]')
            sudo ufw --force delete "$number"
            ufw_deleted=$((ufw_deleted+1))
            show_progress "$number" "$ufw_deleted" "$ufw_created" "$ufw_ignored"
        fi
    done < <(sudo ufw status numbered)
}

show_progress() {
    local current=$1
    local deleted=$2
    local created=$3
    local ignored=$4
    local progress=$((current * 100 / total_ips))
    local done=$((progress * 4 / 10))
    local left=$((40 - done))
    local fill=$(printf "%${done}s")
    local empty=$(printf "%${left}s")
    printf "\rProgress: [${fill// /#}${empty// /-}] ${progress}%% - Deleted: $deleted, Created: $created, Ignored: $ignored"
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
        show_progress $current_ip $ufw_deleted $ufw_created $ufw_ignored
    done
    echo ""
    sudo ufw reload
fi

echo ''
echo "Total rules deleted: ${ufw_deleted}"
echo "Total rules created: ${ufw_created}"
echo "Total rules ignored: ${ufw_ignored}"
echo 'Done.'
