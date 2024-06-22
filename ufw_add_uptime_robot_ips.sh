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

ufw_delete_rule_by_id () {
    local rule_id="$1"
    if [ ! -z "$rule_id" ]; then
        rule=$(LC_ALL=C sudo ufw --force delete "$rule_id")
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
    while true; do
        rule_id=$(sudo ufw status numbered | awk '/# Uptime Robot$/{print $1}' | tr -d '[]' | head -n 1)
        if [ -z "$rule_id" ]; then
            break
        fi
        ufw_delete_rule_by_id "$rule_id"
        show_progress
    done
}

ufw_delete_ipv6_rules () {
    ips=$(curl -s $UPTIME_ROBOT_IPV6_URL | tr '\r' '\n' | tr -s '\n')
    total=$(echo "$ips" | wc -l)
    current=0

    for ip in $ips; do
        if [[ $ip =~ ^([0-9a-fA-F]{1,4}:){1,7}[0-9a-fA-F]{1,4}$ ]]; then
            ufw_delete_ip "$ip"
        else
            echo -e "\033[33mIgnored invalid IPv6 address: $ip\033[0m"
            ufw_ignored=$((ufw_ignored+1))
        fi
        current=$((current + 1))
        show_progress $current $total $ufw_deleted $ufw_created $ufw_ignored
    done
}

ufw_delete_ip () {
    if [ ! -z "$1" ]; then
        rule=$(LC_ALL=C sudo ufw delete allow from "$1")
        if [[ "$rule" == *"Rule deleted"* ]] || [[ "$rule" == *"Rule deleted (v6)"* ]]; then
            ufw_deleted=$((ufw_deleted+1))
            return
        fi
    fi
    ufw_ignored=$((ufw_ignored+1))
}

show_progress() {
    local progress=$((ufw_deleted + ufw_ignored + ufw_created))
    local total=$((ufw_deleted + ufw_ignored + ufw_created))
    local done=$((progress * 4 / 10))
    local left=$((40 - done))
    local fill=$(printf "%${done}s")
    local empty=$(printf "%${left}s")
    printf "\rProgress: [${fill// /#}${empty// /-}] - \033[32mCreated: $ufw_created\033[0m \033[33mIgnored: $ufw_ignored\033[0m \033[31mDeleted: $ufw_deleted\033[0m"
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

ips=$(curl -s $UPTIME_ROBOT_IPV4_URL | tr '\r' '\n' | tr -s '\n')
total_ips=$(echo "$ips" | wc -l)
current_ip=0

for ip in $ips; do
    ufw_add_ip "$ip"
    current_ip=$((current_ip + 1))
    show_progress
done
echo ""
sudo ufw reload

echo ''
echo -e "\033[32mTotal rules created: ${ufw_created}\033[0m"
echo -e "\033[33mTotal rules ignored: ${ufw_ignored}\033[0m"
echo -e "\033[31mTotal rules deleted: ${ufw_deleted}\033[0m"
echo 'Done.'
