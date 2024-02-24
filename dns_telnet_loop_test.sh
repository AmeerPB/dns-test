#!/bin/bash

# Define the hostname to query
hostname="smtp.mailchannels.net"

# Define the DNS resolvers to use
resolvers=("8.8.8.8" "1.1.1.1" "8.8.4.4")

# Telnet port
port=25

# Log file for DNS resolution failures
dns_log_file="dns_failures.log"

# Log file for telnet failures
telnet_log_file="telnet_failures.log"

# Variables to track failures and successes
dns_failures=0
dns_successes=0
telnet_failures=0
telnet_successes=0

# Function to handle SIGINT signal (Ctrl+C)
handle_interrupt() {
    echo "Script interrupted! Printing statistics..."
    echo "DNS Resolution Failures: $dns_failures"
    echo "DNS Resolution Successes: $dns_successes"
    echo "Telnet Failures: $telnet_failures"
    echo "Telnet Successes: $telnet_successes"

    # Calculate failure and success ratios for DNS resolution
    if (( dns_failures + dns_successes > 0 )); then
        dns_failure_ratio=$(awk "BEGIN {printf \"%.2f\", $dns_failures * 100 / ($dns_failures + $dns_successes)}")
        dns_success_ratio=$(awk "BEGIN {printf \"%.2f\", $dns_successes * 100 / ($dns_failures + $dns_successes)}")
        echo "DNS Resolution Failure Ratio: $dns_failure_ratio%"
        echo "DNS Resolution Success Ratio: $dns_success_ratio%"
    else
        echo "DNS Resolution Failure Ratio: 0%"
        echo "DNS Resolution Success Ratio: 0%"
    fi

    # Calculate failure and success ratios for telnet
    if (( telnet_failures + telnet_successes > 0 )); then
        telnet_failure_ratio=$(awk "BEGIN {printf \"%.2f\", $telnet_failures * 100 / ($telnet_failures + $telnet_successes)}")
        telnet_success_ratio=$(awk "BEGIN {printf \"%.2f\", $telnet_successes * 100 / ($telnet_failures + $telnet_successes)}")
        echo "Telnet Failure Ratio: $telnet_failure_ratio%"
        echo "Telnet Success Ratio: $telnet_success_ratio%"
    else
        echo "Telnet Failure Ratio: 0%"
        echo "Telnet Success Ratio: 0%"
    fi

    echo "Script terminated."
    exit
}

# Trap the SIGINT signal (Ctrl+C) and call the handle_interrupt function
trap handle_interrupt SIGINT

# Run the script in an infinite loop
while true
do
    echo "---------------------------------------"
    echo "New iteration: $(date)"

    for resolver in "${resolvers[@]}"
    do
        echo "Resolver: $resolver"

        dns_output=$(dig @${resolver} +short ${hostname} A)
        if [ -z "$dns_output" ]; then
            echo "DNS resolution failed!"
            echo "$(date) - DNS resolution failed for $resolver" >> "$dns_log_file"
            dns_failures=$((dns_failures + 1))
        else
            resolved_ips=($dns_output)
            for ip in "${resolved_ips[@]}"
            do
                echo "IP: $ip"
                telnet_output=$(echo "open $ip $port" | telnet 2>&1)
                if [[ $telnet_output != *"Connected"* ]]; then
                    echo "Telnet failed!"
                    echo "$(date) - Telnet failed for $ip:$port" >> "$telnet_log_file"
                    telnet_failures=$((telnet_failures + 1))
                else
                    telnet_successes=$((telnet_successes + 1))
                fi
            done
            dns_successes=$((dns_successes + 1))
        fi

        echo "--------------------------------------------------------------"
    done

    # Sleep for 1 minute before the next iteration
    sleep 5
done
