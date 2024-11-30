#!/bin/bash

# Monitoring Script Configuration
LOG_DIR="/home/likhithavandanapu/Documents/logs/system_monitoring"
ALERT_EMAIL="admin@yourcompany.com"
THRESHOLD_CPU=80
THRESHOLD_MEMORY=85
THRESHOLD_DISK=90
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Create log directory if it doesn't exist
mkdir -p $LOG_DIR

# Function to log system metrics
log_system_metrics() {
    # Capture comprehensive system state
    {
        echo "--- System Metrics at $TIMESTAMP ---"
        
        # CPU Monitoring
        echo "CPU USAGE:"
        top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4 "%"}'
        
        # Memory Monitoring
        echo -e "\nMEMORY USAGE:"
        free -h
        
        # Disk Usage
        echo -e "\nDISK USAGE:"
        df -h
        
        # Network Connections
        echo -e "\nNETWORK CONNECTIONS:"
        ss -tuln
        
        # Running Processes
        echo -e "\nTOP 10 PROCESSES BY CPU:"
        ps aux --sort=-%cpu | head -11
        
        # Load Average
        echo -e "\nSYSTEM LOAD:"
        uptime
    } >> "$LOG_DIR/system_metrics_$(date +%Y%m%d).log"
}

# Function to check critical thresholds
check_critical_thresholds() {
    # CPU Usage Check
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d. -f1)
    if [ $CPU_USAGE -gt $THRESHOLD_CPU ]; then
        send_alert "HIGH CPU USAGE" "Current CPU usage is $CPU_USAGE%"
    fi
    
    # Memory Usage Check
    MEMORY_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}' | cut -d. -f1)
    if [ $MEMORY_USAGE -gt $THRESHOLD_MEMORY ]; then
        send_alert "HIGH MEMORY USAGE" "Current memory usage is $MEMORY_USAGE%"
    fi
    
    # Disk Usage Check
    DISK_USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//g')
    if [ $DISK_USAGE -gt $THRESHOLD_DISK ]; then
        send_alert "HIGH DISK USAGE" "Current disk usage is $DISK_USAGE%"
    fi
}

# Function to send alerts
send_alert() {
    local SUBJECT="$1"
    local MESSAGE="$2"
    echo "$MESSAGE" | mail -s "$SUBJECT" $ALERT_EMAIL
}

# Function to check for potential security issues
check_security() {
    # Failed login attempts
    FAILED_LOGINS=$(grep "Failed" /var/log/auth.log | wc -l)
    if [ $FAILED_LOGINS -gt 10 ]; then
        send_alert "MULTIPLE FAILED LOGIN ATTEMPTS" "Number of failed logins: $FAILED_LOGINS"
    fi
    
    # Check for unusual open ports
    UNUSUAL_PORTS=$(ss -tuln | awk '{print $5}' | grep -E ":([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-3][0-9]|6554[0-5])$" | wc -l)
    if [ $UNUSUAL_PORTS -gt 0 ]; then
        send_alert "UNUSUAL OPEN PORTS DETECTED" "Number of unusual ports: $UNUSUAL_PORTS"
    fi
}

# Main monitoring routine
main() {
    log_system_metrics
    check_critical_thresholds
    check_security
}

# Run the monitoring script
main
