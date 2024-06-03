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

    # Accept incoming packets related to established connections
    execute_command sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    execute_command sudo ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # Accept on localhost
    execute_command sudo iptables -A INPUT -i lo -j ACCEPT
    execute_command sudo ip6tables -A INPUT -i lo -j ACCEPT

    # Accept incoming SSH connections
    execute_command sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    execute_command sudo ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT

    # Accept HTTP and HTTPS connections
    execute_command sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    execute_command sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    execute_command sudo ip6tables -A INPUT -p tcp --dport 80 -j ACCEPT
    execute_command sudo ip6tables -A INPUT -p tcp --dport 443 -j ACCEPT

    # Save the rules
    execute_command sudo sh -c "iptables-save > /etc/iptables/rules.v4"
    execute_command sudo sh -c "ip6tables-save > /etc/iptables/rules.v6"

    echo -e "\nFirewall setup completed. ✔"
    read -rp "Press Enter to continue..."
}

firewall_clear() {
    clear_console
    echo "Clearing all firewall rules..."

    # Flush existing rules
    execute_command sudo iptables -F
    execute_command sudo iptables -t nat -F
    execute_command sudo ip6tables -F
    execute_command sudo ip6tables -t nat -F
    execute_command sudo iptables -X
    execute_command sudo ip6tables -X
    execute_command sudo iptables -Z
    execute_command sudo ip6tables -Z

    # Set default policies to ACCEPT
    execute_command sudo iptables -P INPUT ACCEPT
    execute_command sudo iptables -P FORWARD ACCEPT
    execute_command sudo iptables -P OUTPUT ACCEPT
    execute_command sudo ip6tables -P INPUT ACCEPT
    execute_command sudo ip6tables -P FORWARD ACCEPT
    execute_command sudo ip6tables -P OUTPUT ACCEPT

    # Ensure SSH is allowed
    execute_command sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    execute_command sudo ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT

    echo -e "\nAll firewall rules cleared. ✔"
    read -rp "Press Enter to continue..."
}

firewall_open_port() {
    clear_console
    echo "Open a new port"

    read -rp "Enter the port number you want to open: " port
    read -rp "Enter the protocol (tcp/udp): " protocol

    if [ "$protocol" == "tcp" ]; then
        execute_command sudo iptables -A INPUT -p tcp --dport "$port" -j ACCEPT
        execute_command sudo ip6tables -A INPUT -p tcp --dport "$port" -j ACCEPT
    elif [ "$protocol" == "udp" ]; then
        execute_command sudo iptables -A INPUT -p udp --dport "$port" -j ACCEPT
        execute_command sudo ip6tables -A INPUT -p udp --dport "$port" -j ACCEPT
    else
        echo "Invalid protocol specified. Please enter either 'tcp' or 'udp'."
    fi

    # Save the rules
    execute_command sudo sh -c "iptables-save > /etc/iptables/rules.v4"
    execute_command sudo sh -c "ip6tables-save > /etc/iptables/rules.v6"

    echo -e "\nPort $port/$protocol opened. ✔"
    read -rp "Press Enter to continue..."
}

main_menu() {
    while true; do
        clear_console
        echo "Main Menu"
        echo "1. Install packages"
        echo "2. Clear all firewall rules"
        echo "3. Set up firewall rules"
        echo "4. Open a new port"
        echo "5. Exit"
        read -rp "Please enter your choice: " choice
        case $choice in
            1)
                installpackages "iptables-persistent"
                ;;
            2)
                firewall_clear
                ;;
            3)
                firewall_install
                ;;
            4)
                firewall_open_port
                ;;
            5)
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                read -rp "Press Enter to continue..."
                ;;
        esac
    done
}

main_menu
