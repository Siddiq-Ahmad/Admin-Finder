#!/bin/bash

# Function to print the banner
banner() {
    echo -e "\033[91m██   ██▄   █▀▄▀█ ▄█    ▄       \033[97m█ ▄▄  ██      ▄   ▄███▄   █         \033[92m▄████  ▄█    ▄   ██▄   ▄███▄   █▄▄▄▄"
    echo -e "\033[91m█ █  █  █  █ █ █ ██     █      \033[97m█   █ █ █      █  █▀   ▀  █         \033[92m█▀   ▀ ██     █  █  █  █▀   ▀  █  ▄▀"
    echo -e "\033[91m█▄▄█ █   █ █ ▄ █ ██ ██   █     \033[97m█▀▀▀  █▄▄█ ██   █ ██▄▄    █         \033[92m█▀▀    ██ ██   █ █   █ ██▄▄    █▀▀▌"
    echo -e "\033[91m█  █ █  █  █   █ ▐█ █ █  █     \033[97m█     █  █ █ █  █ █▄   ▄▀ ███▄      \033[92m█      ▐█ █ █  █ █  █  █▄   ▄▀ █  █"
    echo -e "\033[91m   █ ███▀     █   ▐ █  █ █     \033[97m █       █ █  █ █ ▀███▀       ▀     \033[92m █      ▐ █  █ █ ███▀  ▀███▀     █"
    echo -e "\033[91m  █          ▀      █   ██     \033[97m  ▀     █  █   ██                   \033[92m  ▀       █   ██                ▀"
    echo -e "\033[91m ▀                             \033[97m       ▀                                        \033[92m"
}

# Function to print the usage
print_usage() {
    echo -e "\033[92mauthor: SIDDIQ AHMAD\033[0m"
    echo -e "\033[91mThis tool is for educational and testing purposes only.\033[0m"
    echo -e "\033[91mI am not responsible for what you do with this tool\033[0m"
    echo -e "\033[96mUsages:\033[0m"
    echo -e "\033[96m    -site <url of website> - Website to scan"
    echo -e "\033[96m    --proxy <protocol>-<proxyserverip:port> - Scan admin panel using proxy server"
    echo -e "\033[96m    --t <second(s)> - Time delay for a thread to scan (To prevent from getting HTTP 508)"
    echo -e "\033[96m    --w <path/of/custom/wordlist> - custom wordlist"
    echo -e "Example:"
    echo -e "    ./$0 -site http://example.com"
    echo -e "    ./$0 -site https://example.com --t 1"
    echo -e "    ./$0 -site http://example.com example2.com"
    echo -e "    ./$0 -site https://example.com --w /custom/wordlist/list.txt"
    echo -e "    ./$0 --proxy http-1.2.3.4:8080 -site http://example.com"
    exit 1
}

# Check for command line arguments
if [[ $# -eq 0 ]]; then
    print_usage
fi

# Default values
proxy_enable=false
delay=0
file_to_open='list.txt'

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --proxy)
            proxy_enable=true
            proxyserver="$2"
            echo -e "\033[35mUsing Proxy - True\033[0m"
            shift 2
            ;;
        --t)
            delay="$2"
            shift 2
            ;;
        -site)
            websites_to_scan=("${@:2}")
            break
            ;;
        --w)
            file_to_open="$2"
            shift 2
            ;;
        *)
            echo -e "\033[91mUnknown option: $1\033[0m"
            print_usage
            ;;
    esac
done

# If no sites provided, show usage
if [[ -z "$websites_to_scan" ]]; then
    echo -e "\033[91mWhich site you wanna scan!!!!\033[0m"
    exit 1
fi

# Function to make the HTTP request
scan_website() {
    local website="$1"
    local worker="$2"
    local response

    if [[ "$proxy_enable" == true ]]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" --proxy "$proxyserver" "${website}${worker}")
    else
        response=$(curl -s -o /dev/null -w "%{http_code}" "${website}${worker}")
    fi

    if [[ "$response" -eq 200 ]]; then
        echo -e "\033[92m[Status-code - 200] Success: ${worker}\033[0m"
    else
        echo -e "\033[91m[Status-code - $response] Failed: ${worker}\033[0m"
    fi
}

# Main execution
banner

for website in "${websites_to_scan[@]}"; do
    [[ "${website}" != */ ]] && website="${website}/"
    echo -e "\033[96mResult for ${website}:\033[0m"
    
    # Read the wordlist and spawn threads for each line
    while read -r line; do
        worker=$(echo "$line" | tr -d '\r')  # Trim carriage return if present
        {
            scan_website "$website" "$worker"
        } &
        sleep "$delay"
    done < "$file_to_open"

    wait
    echo -e "\n"
done
