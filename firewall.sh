#!/bin/bash

clear_console() {
    clear
    echo -e "######################################################################################"
    echo -e "#                                                                                    #"
    echo -e "#                            Project 'BOGDIZ - Firewall'                             #"
    echo -e "#                                                                                    #"
    echo -e "######################################################################################"
}

execute_command() {
    if "$@"; then
        echo -e "✔ $@"
    else
        echo -e "✘ $@"
    fi
}

installpackages() {
    clear_console
    if ! dpkg -s "$1" &> /dev/null; then
        echo -e "$1 is not installed. Installing...\n"
        echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
        echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
        if sudo apt-get install -y --no-install-recommends "$1"; then
            echo -e "$1 has been installed successfully. ✔\n"
        else
            echo -e "$1 installation failed. ✘\n"
        fi
    else
        echo "$1 is already installed. ✘ (already existing)"
    fi
    read -rp "Press Enter to continue..."
}

firewall_install() {
    clear_console
    echo "Setting up firewall rules..."

    # Flush existing rules
    execute_command sudo iptables -F
    execute_command sudo iptables -t nat -F
    execute_command sudo ip6tables -F
    execute_command sudo ip6tables -t nat -F
    execute_command sudo iptables -X
    execute_command sudo ip6tables -X
    execute_command sudo iptables -Z
    execute_command sudo ip6tables -Z

    # Set default policy to DROP
    execute_command sudo iptables -P INPUT DROP
    execute_command sudo iptables -P FORWARD DROP
    execute_command sudo iptables -P OUTPUT ACCEPT
    execute_command sudo ip6tables -P INPUT DROP
    execute_command sudo ip6tables -P FORWARD DROP
    execute_command sudo ip6tables -P OUTPUT ACCEPT

    # Drop invalid packets
    execute_command sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
    execute_command sudo ip6tables -A INPUT -m conntrack --ctstate INVALID -j DROP

    # Drop packets with suspicious TCP flags
    execute_command sudo iptables -A INPUT -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
    execute_command sudo iptables -A INPUT -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
    execute_command sudo iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
    execute_command sudo iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
    execute_command sudo iptables -A INPUT -p tcp --tcp-flags FIN,ACK FIN -j DROP
    execute_command sudo iptables -A INPUT -p tcp --tcp-flags ACK,URG URG -j DROP
    execute_command sudo iptables -A INPUT -p tcp --tcp-flags ACK,FIN FIN -j DROP
    execute_command sudo iptables -A INPUT -p tcp --tcp-flags ACK,PSH PSH -j DROP
    execute_command sudo iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
    execute_command sudo iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
    execute_command sudo iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
    execute_command sudo iptables -A INPUT -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
    execute_command sudo iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
    execute_command sudo ip6tables -A INPUT -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
    execute_command sudo ip6tables -A INPUT -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
    execute_command sudo ip6tables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
    execute_command sudo ip6tables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
    execute_command sudo ip6tables -A INPUT -p tcp --tcp-flags FIN,ACK FIN -j DROP
    execute_command sudo ip6tables -A INPUT -p tcp --tcp-flags ACK,URG URG -j DROP
    execute_command sudo ip6tables -A INPUT -p tcp --tcp-flags ACK,FIN FIN -j DROP
    execute_command sudo ip6tables -A INPUT -p tcp --tcp-flags ACK,PSH PSH -j DROP
    execute_command sudo ip6tables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
    execute_command sudo ip6tables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
    execute_command sudo ip6tables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
    execute_command sudo ip6tables -A INPUT -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
    execute_command sudo ip6tables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

    # Drop fragmented packets
    execute_command sudo iptables -A INPUT -f -j DROP
    execute_command sudo ip6tables -A INPUT -m frag --fragid 0 -j DROP

    # Prevent SYN flood
    execute_command sudo iptables -A INPUT -p tcp --syn -m limit --limit 100/s --limit-burst 200 -j ACCEPT
    execute_command sudo iptables -A INPUT -p tcp --syn -j DROP
    execute_command sudo ip6tables -A INPUT -p tcp --syn -m limit --limit 100/s --limit-burst 200 -j ACCEPT
    execute_command sudo ip6tables -A INPUT -p tcp --syn -j DROP

    # Limit new connections
    execute_command sudo iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
    execute_command sudo iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP
    execute_command sudo ip6tables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
    execute_command sudo ip6tables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP

    # Detect port scanning
    execute_command sudo iptables -N port-scanning
    execute_command sudo iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j LOG --log-prefix "Port Scan:"
    execute_command sudo iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
    execute_command sudo iptables -A port-scanning -j DROP
    execute_command sudo ip6tables -N port-scanning
    execute_command sudo ip6tables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j LOG --log-prefix "Port Scan:"
    execute_command sudo ip6tables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
    execute_command sudo ip6tables -A port-scanning -j DROP

    # Layer 7 DDoS protection
    execute_command sudo iptables -N LAYER7_DDOS_HTTP
    execute_command sudo iptables -A LAYER7_DDOS_HTTP -p tcp --dport 80 -m string --string "GET" --algo bm --to 65535 -j DROP
    execute_command sudo iptables -A LAYER7_DDOS_HTTP -p tcp --dport 80 -m string --string "POST" --algo bm --to 65535 -j DROP
    execute_command sudo iptables -A LAYER7_DDOS_HTTP -p tcp --dport 80 -m recent --name HTTP --update --seconds 60 --hitcount 50 -j DROP
    execute_command sudo ip6tables -N LAYER7_DDOS_HTTP
    execute_command sudo ip6tables -A LAYER7_DDOS_HTTP -p tcp --dport 80 -m string --string "GET" --algo bm --to 65535 -j DROP
    execute_command sudo ip6tables -A LAYER7_DDOS_HTTP -p tcp --dport 80 -m string --string "POST" --algo bm --to 65535 -j DROP
    execute_command sudo ip6tables -A LAYER7_DDOS_HTTP -p tcp --dport 80 -m recent --name HTTP --update --seconds 60 --hitcount 50 -j DROP

    # Allow specific services (example: SSH, HTTP, HTTPS)
    execute_command sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    execute_command sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    execute_command sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    execute_command sudo ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT
    execute_command sudo ip6tables -A INPUT -p tcp --dport 80 -j ACCEPT
    execute_command sudo ip6tables -A INPUT -p tcp --dport 443 -j ACCEPT

    # Allow loopback traffic
    execute_command sudo iptables -A INPUT -i lo -j ACCEPT
    execute_command sudo ip6tables -A INPUT -i lo -j ACCEPT

    # Allow established and related connections
    execute_command sudo iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    execute_command sudo ip6tables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

    # Save rules
    execute_command sudo netfilter-persistent save

    echo -e "Firewall rules have been set up successfully. ✔\n"
    read -rp "Press Enter to continue..."
}

open_port() {
    clear_console
    echo "Opening a port..."
    read -rp "Enter the port number to open: " port
    echo "Choose the protocol:"
    echo "1) TCP"
    echo "2) UDP"
    echo "3) Both"
    read -rp "Enter your choice: " protocol
    case $protocol in
        1)
            execute_command sudo iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
            execute_command sudo ip6tables -A INPUT -p tcp --dport "$port" -j ACCEPT
            ;;
        2)
            execute_command sudo iptables -A INPUT -p udp --dport "$port" -j ACCEPT
            execute_command sudo ip6tables -A INPUT -p udp --dport "$port" -j ACCEPT
            ;;
        3)
            execute_command sudo iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
            execute_command sudo iptables -A INPUT -p udp --dport "$port" -j ACCEPT
            execute_command sudo ip6tables -A INPUT -p tcp --dport "$port" -j ACCEPT
            execute_command sudo ip6tables -A INPUT -p udp --dport "$port" -j ACCEPT
            ;;
        *)
            echo "Invalid choice. ✘"
            ;;
    esac
    read -rp "Press Enter to continue..."
}

close_port() {
    clear_console
    echo "Closing a port..."
    read -rp "Enter the port number to close: " port
    echo "Choose the protocol:"
    echo "1) TCP + UDP"
    echo "2) UDP"
    echo "3) TCP"
    read -rp "Enter your choice: " protocol

    block_port() {
        local port=$1
        local proto=$2

        # Check if the rule exists before blocking the port
        if ! sudo iptables -C INPUT -p "$proto" --dport "$port" -j DROP 2>/dev/null; then
            execute_command sudo iptables -A INPUT -p "$proto" --dport "$port" -j DROP
            echo "✔ Port $port has been successfully blocked for $proto protocol."
        else
            echo "✘ Rule already exists in iptables for $proto port $port"
        fi

        if ! sudo ip6tables -C INPUT -p "$proto" --dport "$port" -j DROP 2>/dev/null; then
            execute_command sudo ip6tables -A INPUT -p "$proto" --dport "$port" -j DROP
            echo "✔ Port $port has been successfully blocked for $proto protocol."
        else
            echo "✘ Rule already exists in ip6tables for $proto port $port"
        fi
    }

    restart_iptables() {
        if sudo systemctl restart iptables.service; then
            echo "✔ iptables service restarted successfully."
        else
            echo "✘ Failed to restart iptables service."
        fi
    }

    restart_docker() {
        if sudo systemctl restart docker.service; then
            echo "✔ Docker service restarted successfully."
        else
            echo "✘ Failed to restart Docker service."
        fi
    }

    restart_network() {
        # Restart NetworkManager
        if sudo systemctl restart NetworkManager.service; then
            echo "✔ Network service restarted successfully."
        else
            echo "✘ Failed to restart network service."
        fi
    }

    case $protocol in
        1)
            block_port "$port" "tcp"
            block_port "$port" "udp"
            ;;
        2)
            block_port "$port" "udp"
            ;;
        3)
            block_port "$port" "tcp"
            ;;
        *)
            echo "Invalid choice. ✘"
            ;;
    esac

    restart_iptables
    restart_docker
    restart_network

    read -rp "Press Enter to continue..."
}

enable_dns_protection() {
    clear_console
    echo "Enabling DNS protection..."

    # Prompt for the port number
    read -rp "Enter the port number to protect (default is 53): " port
    port="${port:-53}"  # If no input provided, default to port 53

    # Layer 7 DNS protection
    execute_command sudo iptables -N LAYER7_DDOS_DNS
    execute_command sudo iptables -A LAYER7_DDOS_DNS -p tcp --dport "$port" -m string --hex-string "|00 00 01 00 00 01|" --algo bm -j DROP
    execute_command sudo iptables -A LAYER7_DDOS_DNS -p tcp --sport "$port" -m string --hex-string "|00 00 01 00 00 01|" --algo bm -j DROP
    execute_command sudo iptables -A LAYER7_DDOS_DNS -p udp --dport "$port" -m string --hex-string "|00 00 01 00 00 01|" --algo bm -j DROP
    execute_command sudo iptables -A LAYER7_DDOS_DNS -p udp --sport "$port" -m string --hex-string "|00 00 01 00 00 01|" --algo bm -j DROP
    execute_command sudo ip6tables -N LAYER7_DDOS_DNS
    execute_command sudo ip6tables -A LAYER7_DDOS_DNS -p tcp --dport "$port" -m string --hex-string "|00 00 01 00 00 01|" --algo bm -j DROP
    execute_command sudo ip6tables -A LAYER7_DDOS_DNS -p tcp --sport "$port" -m string --hex-string "|00 00 01 00 00 01|" --algo bm -j DROP
    execute_command sudo ip6tables -A LAYER7_DDOS_DNS -p udp --dport "$port" -m string --hex-string "|00 00 01 00 00 01|" --algo bm -j DROP
    execute_command sudo ip6tables -A LAYER7_DDOS_DNS -p udp --sport "$port" -m string --hex-string "|00 00 01 00 00 01|" --algo bm -j DROP

    echo -e "DNS protection for port $port has been enabled successfully. ✔\n"
    read -rp "Press Enter to continue..."
}


# Main menu
while true; do
    clear_console
    echo "Main Menu"
    echo "1) Install packages"
    echo "2) Setup firewall rules"
    echo "3) Enable DNS protection"
    echo "4) Open a port"
    echo "5) Close a port"
    echo "6) Exit"
    read -rp "Enter your choice: " choice
    case $choice in
        1)
            installpackages iptables-persistent
            ;;
        2)
            firewall_install
            ;;
        3)
            enable_dns_protection
            ;;
        4)
            open_port
            ;;
        5)
            close_port
            ;;
        6)
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter a valid option."
            read -rp "Press Enter to continue..."
            ;;
    esac
done
