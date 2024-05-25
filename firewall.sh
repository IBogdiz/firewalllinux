#!/bin/bash

clear_console() {
    clear
    echo -e "######################################################################################"
    echo -e "#                                                                                    #"
    echo -e "#                            Project 'BOGDIZ - Firewall'                             #"
    echo -e "#                                                                                    #"
    echo -e "######################################################################################"
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
    echo "bogdiz: Setting up firewall rules..."

    execute_command() {
        "$@"
        if [ $? -eq 0 ]; then
            echo -e "✔ $@"
        else
            echo -e "✘ $@"
        fi
    }

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

    execute_command sudo iptables -N LAYER7_DDOS_HTTPS
    execute_command sudo iptables -A LAYER7_DDOS_HTTPS -p tcp --dport 443 -m string --string "GET" --algo bm --to 65535 -j DROP
    execute_command sudo iptables -A LAYER7_DDOS_HTTPS -p tcp --dport 443 -m string --string "POST" --algo bm --to 65535 -j DROP
    execute_command sudo iptables -A LAYER7_DDOS_HTTPS -p tcp --dport 443 -m recent --name HTTPS --update --seconds 60 --hitcount 50 -j DROP

    execute_command sudo ip6tables -N LAYER7_DDOS_HTTPS
    execute_command sudo ip6tables -A LAYER7_DDOS_HTTPS -p tcp --dport 443 -m string --string "GET" --algo bm --to 65535 -j DROP
    execute_command sudo ip6tables -A LAYER7_DDOS_HTTPS -p tcp --dport 443 -m string --string "POST" --algo bm --to 65535 -j DROP
    execute_command sudo ip6tables -A LAYER7_DDOS_HTTPS -p tcp --dport 443 -m recent --name HTTPS --update --seconds 60 --hitcount 50 -j DROP

    # Allow HTTP (port 80) connections
    execute_command sudo iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
    execute_command sudo ip6tables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

    # Allow HTTPS (port 443) connections
    execute_command sudo iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
    execute_command sudo ip6tables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

    # Ensure LAYER7_DDOS chains are called
    execute_command sudo iptables -A INPUT -j LAYER7_DDOS_HTTP
    execute_command sudo iptables -A INPUT -j LAYER7_DDOS_HTTPS
    execute_command sudo ip6tables -A INPUT -j LAYER7_DDOS_HTTP
    execute_command sudo ip6tables -A INPUT -j LAYER7_DDOS_HTTPS

    # Accept packets for loopback interface
    execute_command sudo iptables -A INPUT -i lo -j ACCEPT
    execute_command sudo ip6tables -A INPUT -i lo -j ACCEPT

    # Accept established connections
    execute_command sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    execute_command sudo ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # Allow SSH (port 22) connections
    execute_command sudo iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
    execute_command sudo ip6tables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

    # Save the iptables rules
    execute_command sudo netfilter-persistent save

    clear_console
    echo -e "Firewall rules setup successfully. ✔\n"
    read -rp "Press Enter to continue..."
}

restart_services() {
    clear_console
    echo "bogdiz: Restarting services..."
    services=(apache2 mysql nginx)
    for service in "${services[@]}"; do
        if sudo systemctl restart "$service"; then
            echo -e "Service $service restarted successfully. ✔"
        else
            echo -e "Failed to restart service $service. ✘"
        fi
    done
    read -rp "Press Enter to continue..."
}

while true; do
    clear_console
    echo "Select an option:"
    echo "1. Clear Firewall"
    echo "2. List Firewall Rules"
    echo "3. Setup Firewall"
    echo "4. Restart Services"
    echo "5. Install packages"
    echo "6. Exit"
    read -rp "Enter your choice: " choice
    case $choice in
        1)
            clear_console
            echo "bogdiz: Clearing firewall rules..."
            if sudo iptables -F && sudo ip6tables -F && sudo iptables -t nat -F && sudo ip6tables -t nat -F; then
                echo -e "Firewall rules cleared successfully. ✔\n"
            else
                echo -e "Failed to clear firewall rules. ✘\n"
            fi
            read -rp "Press Enter to continue..."
            ;;
        2)
            clear_console
            echo "bogdiz: Listing firewall rules..."
            sudo iptables -L -v -n
            sudo ip6tables -L -v -n
            read -rp "Press Enter to continue..."
            ;;
        3)
            firewall_install
            ;;
        4)
            restart_services
            ;;
        5)
            installpackages iptables-persistent
            ;;
        6)
            exit 0
            ;;
        *)
            clear_console
            echo "Invalid choice. Please try again."
            read -rp "Press Enter to continue..."
            ;;
    esac
done
