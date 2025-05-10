#!/bin/bash

# Exit on errors
set -e

# Debug: Confirm script is running
echo "Starting log analysis for file: $1"

# Check if log file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <log_file>"
    exit 1
fi

LOG_FILE="$1"

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' not found"
    exit 1
fi

# Check if log file is empty
if [ ! -s "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' is empty"
    exit 1
fi

# Check if log file has valid content (at least one line starting with an IP)
if ! grep -q '^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' "$LOG_FILE"; then
    echo "Error: Log file '$LOG_FILE' contains no valid Apache log entries"
    exit 1
fi

echo "Log Analysis Report"
echo "=================="

# 1. Request Counts
echo -e "\n1. Request Counts"
echo "----------------"
total_requests=$(wc -l < "$LOG_FILE")
get_requests=$(grep -c '"GET ' "$LOG_FILE")
post_requests=$(grep -c '"POST ' "$LOG_FILE")

echo "Total Requests: $total_requests"
echo "GET Requests: $get_requests"
echo "POST Requests: $post_requests"

# 2. Unique IP Addresses
echo -e "\n2. Unique IP Addresses"
echo "---------------------"
unique_ips=$(awk '{print $1}' "$LOG_FILE" | sort -u | wc -l)
echo "Total Unique IPs: $unique_ips"

echo -e "\nGET and POST requests per IP:"
awk '{print $1, $6}' "$LOG_FILE" | 
    sort | 
    uniq -c | 
    awk '{
        ip=$2; 
        method=substr($3,2); 
        count=$1; 
        if(method=="GET") get_count[ip]+=count; 
        if(method=="POST") post_count[ip]+=count
    } 
    END {
        for(ip in get_count) {
            printf "%s: GET=%d, POST=%d\n", 
                   ip, 
                   get_count[ip]+0, 
                   post_count[ip]+0
        }
    }' | sort

# 3. Failure Requests
echo -e "\n3. Failure Requests (4xx/5xx)"
echo "----------------------------"
failed_requests=$(awk '$9 ~ /^[45][0-9][0-9]$/ {count++} END {print count+0}' "$LOG_FILE")
failure_percentage=$(awk -v failed="$failed_requests" -v total="$total_requests" 'BEGIN {printf "%.2f", total ? (failed/total)*100 : 0}')

echo "Failed Requests: $failed_requests"
echo "Failure Percentage: $failure_percentage%"

# 4. Top User
echo -e "\n4. Top User"
echo "----------"
top_ip=$(awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1)
top_ip_address=$(echo "$top_ip" | awk '{print $2}')
top_ip_count=$(echo "$top_ip" | awk '{print $1}')
echo "Most Active IP: $top_ip_address ($top_ip_count requests)"

# 5. Daily Request Averages
echo -e "\n5. Daily Request Averages"
echo "------------------------"
days=$(awk -F'[' '{print $2}' "$LOG_FILE" | awk -F'/' '{print $1"/"$2"/"$3}' | sort -u | wc -l)
avg_requests_per_day=$(awk -v total="$total_requests" -v days="$days" 'BEGIN {printf "%.2f", days ? total/days : 0}')
echo "Number of Days: $days"
echo "Average Requests per Day: $avg_requests_per_day"

# 6. Days with Highest Failures
echo -e "\n6. Days with Highest Failures"
echo "---------------------------"
failure_days=$(awk -F'[' '$9 ~ /^[45][0-9][0-9]$/ {print $2}' "$LOG_FILE" | 
    awk -F'/' '{print $1"/"$2"/"$3}' | 
    sort | 
    uniq -c | 
    sort -nr | 
    head -5 | 
    awk '{printf "%s: %d failures\n", $2, $1}')
if [ -z "$failure_days" ]; then
    echo "No failed requests (4xx/5xx) found in the log file."
else
    echo "$failure_days"
fi

# 7. Requests by Hour
echo -e "\n7. Requests by Hour"
echo "------------------"
awk -F'[' '{print $2}' "$LOG_FILE" | 
    awk -F: '{print $2}' | 
    sort | 
    uniq -c | 
    awk '{printf "Hour %02d: %d requests\n", $2, $1}' | 
    sort -k2 -n

# 8. Request Trends
echo -e "\n8. Request Trends"
echo "----------------"
hourly_counts=$(awk -F'[' '{print $2}' "$LOG_FILE" | awk -F: '{print $2}' | sort | uniq -c | awk '{print $1}')
trend_analysis=""
prev_count=0
hour=0
for count in $hourly_counts; do
    if [ $prev_count -ne 0 ]; then
        if [ $count -gt $prev_count ]; then
            trend_analysis="$trend_analysis\nHour $(printf %02d $hour): Increasing (from $prev_count to $count requests)"
        elif [ $count -lt $prev_count ]; then
            trend_analysis="$trend_analysis\nHour $(printf %02d $hour): Decreasing (from $prev_count to $count requests)"
        fi
    fi
    prev_count=$count
    hour=$((hour+1))
done
if [ -z "$trend_analysis" ]; then
    echo "No significant trends detected."
else
    echo -e "$trend_analysis"
fi

# 9. Status Codes Breakdown
echo -e "\n9. Status Codes Breakdown"
echo "-----------------------"
awk '{print $9}' "$LOG_FILE" | 
    sort | 
    uniq -c | 
    sort -nr | 
    awk -v total="$total_requests" '{printf "Status %s: %d requests (%.2f%%)\n", $2, $1, total ? ($1/total)*100 : 0}'

# 10. Most Active User by Method
echo -e "\n10. Most Active User by Method"
echo "----------------------------"
top_get_ip=$(awk '$6 == "\"GET" {print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1)
if [ -n "$top_get_ip" ]; then
    top_get_ip_address=$(echo "$top_get_ip" | awk '{print $2}')
    top_get_count=$(echo "$top_get_ip" | awk '{print $1}')
else
    top_get_ip_address="None"
    top_get_count=0
fi
top_post_ip=$(awk '$6 == "\"POST" {print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -1)
if [ -n "$top_post_ip" ]; then
    top_post_ip_address=$(echo "$top_post_ip" | awk '{print $2}')
    top_post_count=$(echo "$top_post_ip" | awk '{print $1}')
else
    top_post_ip_address="None"
    top_post_count=0
fi
echo "Most Active GET IP: $top_get_ip_address ($top_get_count requests)"
echo "Most Active POST IP: $top_post_ip_address ($top_post_count requests)"

# 11. Patterns in Failure Requests
echo -e "\n11. Patterns in Failure Requests"
echo "------------------------------"
echo "Failures by Hour:"
failure_hours=$(awk -F'[' '$9 ~ /^[45][0-9][0-9]$/ {print $2}' "$LOG_FILE" | 
    awk -F: '{print $2}' | 
    sort | 
    uniq -c | 
    awk -v total="$failed_requests" '{printf "Hour %02d: %d failures (%.2f%% of total failures)\n", $2, $1, total ? ($1/total)*100 : 0}' | 
    sort -k2 -n)
if [ -z "$failure_hours" ]; then
    echo "No failed requests (4xx/5xx) found in the log file."
else
    echo "$failure_hours"
fi

echo -e "\nTop 5 Days with Failures (repeated for reference):"
if [ -z "$failure_days" ]; then
    echo "No failed requests (4xx/5xx) found in the log file."
else
    echo "$failure_days"
fi

echo -e "\nAnalysis complete!"
