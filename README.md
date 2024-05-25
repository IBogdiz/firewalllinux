English Version
Firewall Auto Installer
This repository contains a script to set up a basic firewall using iptables and ip6tables. The script provides options to clear the firewall, list current rules, restart services, and set up firewall rules.

Installation
Clone the repository:

sh
Copiază codul
git clone https://ibogdiz.xyz/firewall
cd firewall
Make the script executable:

sh
Copiază codul
chmod +x firewall_installer.sh
Run the script:

sh
Copiază codul
sudo ./firewall_installer.sh
Options
Clear Firewall: Clears all existing firewall rules.
List Firewall Rules: Displays the current firewall rules.
Restart Services: Restarts specified services.
Setup Firewall: Configures and sets up the firewall rules.
Ports Allowed
SSH: 22
HTTP: 80
HTTPS: 443
Minecraft: 25565
FiveM: 30120
Custom: 8080, 2020
Features
Flush existing rules
Set default policy to DROP
Allow established connections and loopback traffic
Drop invalid and suspicious packets
Prevent SYN flood attacks
Limit new connections
Detect port scanning
Layer 7 DDoS protection
Contributing
Feel free to fork this repository, create a branch, make your changes, and open a pull request.

Romanian Version
Installer Automat pentru Firewall
Acest depozit conține un script pentru configurarea unui firewall de bază folosind iptables și ip6tables. Scriptul oferă opțiuni pentru a goli firewall-ul, a lista regulile curente, a reporni serviciile și a configura regulile firewall-ului.

Instalare
Clonează depozitul:

sh
Copiază codul
git clone https://ibogdiz.xyz/firewall
cd firewall
Fă scriptul executabil:

sh
Copiază codul
chmod +x firewall_installer.sh
Rulează scriptul:

sh
Copiază codul
sudo ./firewall_installer.sh
Opțiuni
Golește Firewall: Golește toate regulile firewall existente.
Listează Reguli Firewall: Afișează regulile curente ale firewall-ului.
Repornește Servicii: Repornește serviciile specificate.
Configurează Firewall: Configurează și setează regulile firewall-ului.
Porturi Permise
SSH: 22
HTTP: 80
HTTPS: 443
Minecraft: 25565
FiveM: 30120
Personalizat: 8080, 2020
Caracteristici
Golire reguli existente
Setarea politicii implicite la DROP
Permiterea conexiunilor stabilite și a traficului de loopback
Blocarea pachetelor invalide și suspicioase
Prevenirea atacurilor de tip SYN flood
Limitarea noilor conexiuni
Detectarea scanărilor de porturi
Protecție Layer 7 DDoS
