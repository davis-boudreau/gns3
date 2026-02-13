#!/bin/bash
# Network Troubleshooting Quick-Start
set -e

echo "--- [ SYSTEM INFO ] ---"
echo "Hostname: $(hostname)"
echo "Public IP: $(curl -s https://ifconfig.me || echo 'Offline')"
echo "Default Gateway: $(ip route | grep default | awk '{print $3}')"

echo -e "\n--- [ INTERFACE STATUS ] ---"
ip -brief address show

echo -e "\n--- [ LISTENING PORTS ] ---"
ss -tulpn | grep LISTEN

echo -e "\n--- [ QUICK DIAGNOSTIC COMMANDS ] ---"
echo "1. Bandwidth Test:  iperf3 -c <target_ip>"
echo "2. Packet Trace:    tshark -i any -Y 'http or dns'"
echo "3. Port Scan:       nmap -sV -T4 <target_ip>"
echo "4. Path Analysis:   mtr -rw 8.8.8.8"
echo "5. Traffic Monitor: iftop -i any"