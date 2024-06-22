#!/bin/bash

# URLs to fetch the list of Uptime Robot IP addresses
UPTIME_ROBOT_IPV4_URL="https://uptimerobot.com/inc/files/ips/IPv4.txt"
UPTIME_ROBOT_IPV6_URL="https://uptimerobot.com/inc/files/ips/IPv6.txt"

# Initialize counters
ufw_deleted=0
ufw_created=0
ufw_ignored=0

ufw_add_ip () {
    if [ ! -z "$1" ]; then
        rule=$(LC_ALL=C sudo ufw allow from "$1" comment "Uptime Robot")
        if [[ "$rule" == *"Rule added"* ]] || [[ "$rule" == *"Rule added (v6)"* ]]; then
            ufw_created=$((ufw_created+1))
            return
        fi
    fi
    ufw_ignored=$((ufw_ignored+1))
}

ufw_delete_ip () {
    local ip="$1"
    if [ ! -z "$ip" ]; then
        rule=$(LC_ALL=C sudo ufw delete allow from "$ip")
        if [[ "$rule" == *"Rule deleted"* ]] || [[ "$rule" == *"Rule deleted (v6)"* ]]; then
            ufw_deleted=$((ufw_deleted+1))
            echo -n "\e[31m-\e[39m"
            return
        fi
    fi
    echo -n "\e[90m.\e[39m"
    ufw_ignored=$((ufw_ignored+1))
}

ufw_delete_ipv4_rules () {
    ips=$(curl -s $UPTIME_ROBOT_IPV4_URL | tr '\r' '\n' | tr -s '\n')
    total=$(echo "$ips" | wc -l)
    current=0

    for ip in $ips; do
        ufw_delete_ip "$ip"
        current=$((current + 1))
        show_progress $current $total $ufw_deleted $ufw_created $ufw_ignored
    done
}

ufw_delete_ipv6_rules () {
    while true; do
        rule_id=$(sudo ufw status numbered | awk '/Anywhere \(v6\)/{print $1}' | tr -d '[]' | head -n 1)
        if [ -z "$rule_id" ]; then
            break
        fi
        ufw_delete_rule_by_id "$rule_id"
        show_progress
    done
}

show_progress() {
    local deleted=$ufw_deleted
    local created=$ufw_created
    local ignored=$ufw_ignored
    local total=$((deleted + created + ignored))
    local progress=$((total * 100 / (total + 1)))
    local done=$((progress * 4 / 10))
    local left=$((40 - done))
    local fill=$(printf "%${done}s")
    local empty=$(printf "%${left}s")
    printf "\rProgress: [${fill// /#}${empty// /-}] ${progress}%% - \033[32mCreated: $created\033[0m \033[33mIgnored: $ignored\033[0m \033[31mDeleted: $deleted\033[0m"
}

if [ "$1" = "--purge" ]; then
    ufw_delete_ipv4_rules
    ufw_delete_ipv6_rules
    echo ''
    echo -e "\033[32mTotal rules created: ${ufw_created}\033[0m"
    echo -e "\033[33mTotal rules ignored: ${ufw_ignored}\033[0m"
    echo -e "\033[31mTotal rules deleted: ${ufw_deleted}\033[0m"
    echo 'Done.'
    exit 0
fi

# Add IPv4 rules
ips=$(curl -s $UPTIME_ROBOT_IPV4_URL | tr '\r' '\n' | tr -s '\n')
total_ips=$(echo "$ips" | wc -l)
current_ip=0

for ip in $ips; do
    ufw_add_ip "$ip"
    current_ip=$((current_ip + 1))
    show_progress $current_ip $total_ips
done

# Add IPv6 rules
ips=$(curl -s $UPTIME_ROBOT_IPV6_URL | tr '\r' '\n' | tr -s '\n')
total_ips=$(echo "$ips" | wc -l)
current_ip=0

for ip in $ips; do
    ufw_add_ip "$ip"
    current_ip=$((current_ip + 1))
    show_progress $current_ip $total_ips
done

echo ""
sudo ufw reload

echo ''
echo -e "\033[32mTotal rules created: ${ufw_created}\033[0m"
echo -e "\033[33mTotal rules ignored: ${ufw_ignored}\033[0m"
echo -e "\033[31mTotal rules deleted: ${ufw_deleted}\033[0m"
echo 'Done.'
