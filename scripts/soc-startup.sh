#!/bin/bash
# SOC Startup Script
# Location: /share/Container/SOC/scripts/soc-startup.sh
# Purpose: Initialize SOC components on QNAP boot
# Trigger: /etc/config/autorun.sh

LOG_FILE="/share/Container/SOC/logs/startup.log"
echo "$(date): SOC startup script initiated" >> "$LOG_FILE"

# Remove IP from eth4 (SPAN interface must be passive)
# QNAP assigns DHCP to all connected interfaces by default
echo "$(date): Removing IP from eth4 (SPAN interface)" >> "$LOG_FILE"
ip addr flush dev eth4 2>/dev/null
if [ $? -eq 0 ]; then
    echo "$(date): eth4 IP removed successfully" >> "$LOG_FILE"
else
    echo "$(date): eth4 already has no IP or error occurred" >> "$LOG_FILE"
fi

# Wait for Docker to be ready
echo "$(date): Waiting for Docker..." >> "$LOG_FILE"
sleep 30

# Update Suricata rules
echo "$(date): Updating Suricata rules" >> "$LOG_FILE"
docker exec suricata-live suricata-update >> "$LOG_FILE" 2>&1

# Restart Suricata to load updated rules
echo "$(date): Restarting Suricata" >> "$LOG_FILE"
docker restart suricata-live >> "$LOG_FILE" 2>&1

# Verify OpenSearch is accessible
echo "$(date): Checking OpenSearch health" >> "$LOG_FILE"
curl -sk -u admin:${OPENSEARCH_PASSWORD} \
    'https://192.168.50.10:9200/_cluster/health?pretty' >> "$LOG_FILE" 2>&1

echo "$(date): SOC startup script completed" >> "$LOG_FILE"
