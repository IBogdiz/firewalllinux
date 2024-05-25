# Firewall Auto Installer

Acest repository conține un script pentru configurarea unui firewall de bază folosind `iptables` și `ip6tables`. Scriptul oferă opțiuni pentru a goli firewall-ul, a lista regulile curente, a reporni serviciile și a configura regulile firewall-ului.

## Instalare

1. Clonează depozitul:
    ```sh
    git clone https://ibogdiz.xyz/firewall.git
    cd firewall
    ```

2. Fă scriptul executabil:
    ```sh
    chmod +x firewall_installer.sh
    ```

3. Rulează scriptul:
    ```sh
    sudo ./firewall_installer.sh
    ```

## Opțiuni
- Golește Firewall: Golește toate regulile firewall existente.
- Listează Reguli Firewall: Afișează regulile curente ale firewall-ului.
- Repornește Servicii: Repornește serviciile specificate.
- Configurează Firewall: Configurează și setează regulile firewall-ului.

## Porturi Permise
- SSH: 22
- HTTP: 80
- HTTPS: 443
- Minecraft: 25565
- FiveM: 30120
- Personalizat: 8080, 2020

## Caracteristici
- Golire reguli existente
- Setarea politicii implicite la DROP
- Permiterea conexiunilor stabilite și a traficului de loopback
- Blocarea pachetelor invalide și suspicioase
- Prevenirea atacurilor de tip SYN flood
- Limitarea noilor conexiuni
- Detectarea scanărilor de porturi
- Protecție Layer 7 DDoS

## Contribuire
Simte-te liber să forkezi acest depozit, să creezi o ramură, să faci modificările tale și să deschizi un pull request.
