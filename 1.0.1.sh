#!/bin/bash

VERSION="1.0.1"
REPO_DIR="/home/kali/Baba_cyber_tool"

# ==========================================================
# BABA CYBER TOOL
# Personal Cybersecurity / Bug Bounty Toolkit
# Version: 1.0.1
# ==========================================================

banner() {
    clear
    echo "======================================================"
    echo "              BABA CYBER TOOL v$VERSION"
    echo "======================================================"
    echo "        Personal Cybersecurity Toolkit"
    echo "======================================================"
    echo
}

pause_tool() {
    echo
    read -p "Press Enter to return to menu..."
}

check_tool() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo
        echo "[!] $1 is not installed."
        echo "[!] Install it first, then try again."
        pause_tool
        return 1
    fi
    return 0
}

# ==========================================================
# EXISTING PERSONAL TOOLS
# ==========================================================
# BURAYA SƏNİN ƏVVƏLKİ TOOL-LARININ ÇAĞIRIŞLARINI YAZACAĞIQ.
# Onların öz kodlarını dəyişmirik.
#
# Məsələn:
#
# personal_tool_1() {
#     bash "$REPO_DIR/tools/mytool.sh"
# }
#
# personal_tool_2() {
#     python3 "$REPO_DIR/tools/mytool.py"
# }
#
# ==========================================================


# ==========================================================
# NMAP
# ==========================================================

nmap_tool() {
    check_tool nmap || return

    echo
    echo "================ NMAP ================"
    echo "1) Basic Scan"
    echo "2) Service Detection"
    echo "3) Default Scripts"
    echo "4) All TCP Ports"
    echo "5) Custom Nmap Command"
    echo "0) Back"
    echo

    read -p "Select: " nmap_choice

    case "$nmap_choice" in

        1)
            read -p "Target IP/domain: " target
            nmap "$target"
            pause_tool
            ;;

        2)
            read -p "Target IP/domain: " target
            nmap -sV "$target"
            pause_tool
            ;;

        3)
            read -p "Target IP/domain: " target
            nmap -sC "$target"
            pause_tool
            ;;

        4)
            read -p "Target IP/domain: " target
            nmap -p- "$target"
            pause_tool
            ;;

        5)
            read -p "Enter Nmap arguments: " args
            read -p "Target: " target
            nmap $args "$target"
            pause_tool
            ;;

        0)
            return
            ;;

        *)
            echo "[!] Invalid option."
            pause_tool
            ;;
    esac
}


# ==========================================================
# NCAT
# ==========================================================

ncat_tool() {
    check_tool ncat || return

    echo
    echo "================ NCAT ================"
    echo "1) Connect to TCP service"
    echo "2) Listen on TCP port"
    echo "3) Custom Ncat command"
    echo "0) Back"
    echo

    read -p "Select: " ncat_choice

    case "$ncat_choice" in

        1)
            read -p "Target IP/domain: " target
            read -p "Port: " port

            ncat "$target" "$port"

            pause_tool
            ;;

        2)
            read -p "Listen port: " port

            echo
            echo "[+] Listening on port $port"
            echo "[+] Press Ctrl+C to stop."
            echo

            ncat -l "$port"

            pause_tool
            ;;

        3)
            read -p "Ncat arguments: " args
            ncat $args

            pause_tool
            ;;

        0)
            return
            ;;

        *)
            echo "[!] Invalid option."
            pause_tool
            ;;
    esac
}


# ==========================================================
# BETTERCAP
# ==========================================================

bettercap_tool() {
    check_tool bettercap || return

    echo
    echo "============== BETTERCAP =============="
    echo
    echo "1) Start Bettercap"
    echo "2) Start with network interface"
    echo "3) Custom Bettercap arguments"
    echo "0) Back"
    echo

    read -p "Select: " bc_choice

    case "$bc_choice" in

        1)
            sudo bettercap
            ;;

        2)
            ip link
            echo
            read -p "Interface (example: eth0): " iface

            sudo bettercap -iface "$iface"
            ;;

        3)
            read -p "Bettercap arguments: " args

            sudo bettercap $args
            ;;

        0)
            return
            ;;

        *)
            echo "[!] Invalid option."
            pause_tool
            ;;
    esac
}


# ==========================================================
# UPDATE
# ==========================================================

update_tool() {
    echo
    echo "============== BABA UPDATE =============="
    echo

    cd "$REPO_DIR" || {
        echo "[!] Repository not found:"
        echo "$REPO_DIR"
        pause_tool
        return
    }

    echo "[+] Checking GitHub..."
    git fetch origin

    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main)

    echo
    echo "Local : $LOCAL"
    echo "Remote: $REMOTE"
    echo

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "[✓] BABA Cyber Tool is already up to date."
    else
        echo "[+] New version found."
        echo "[+] Updating..."

        git pull --ff-only origin main

        if [ $? -eq 0 ]; then
            echo
            echo "[✓] Update completed successfully."
        else
            echo
            echo "[!] Update failed."
        fi
    fi

    pause_tool
}


# ==========================================================
# MAIN MENU
# ==========================================================

while true; do

    banner

    echo "  [ BUG BOUNTY / RECON ]"
    echo
    echo "  1)  Nmap"
    echo "  2)  Ncat"
    echo "  3)  Bettercap"
    echo
    echo "  [ PERSONAL TOOLS ]"
    echo
    echo "  4)  My Tool #1"
    echo "  5)  My Tool #2"
    echo "  6)  My Tool #3"
    echo "  7)  My Tool #4"
    echo "  8)  My Tool #5"
    echo
    echo "  [ SYSTEM ]"
    echo
    echo "  20) Update BABA Cyber Tool"
    echo "  0)  Exit"
    echo
    echo "======================================================"
    read -p "Select option: " choice

    case "$choice" in

        1)
            nmap_tool
            ;;

        2)
            ncat_tool
            ;;

        3)
            bettercap_tool
            ;;

        4)
            echo
            echo "[+] Your existing Tool #1"
            echo "[!] Buraya əvvəlki tool-un əmri əlavə olunacaq."
            pause_tool
            ;;

        5)
            echo
            echo "[+] Your existing Tool #2"
            echo "[!] Buraya əvvəlki tool-un əmri əlavə olunacaq."
            pause_tool
            ;;

        6)
            echo
            echo "[+] Your existing Tool #3"
            echo "[!] Buraya əvvəlki tool-un əmri əlavə olunacaq."
            pause_tool
            ;;

        7)
            echo
            echo "[+] Your existing Tool #4"
            echo "[!] Buraya əvvəlki tool-un əmri əlavə olunacaq."
            pause_tool
            ;;

        8)
            echo
            echo "[+] Your existing Tool #5"
            echo "[!] Buraya əvvəlki tool-un əmri əlavə olunacaq."
            pause_tool
            ;;

        20)
            update_tool
            ;;

        0)
            clear
            echo "BABA Cyber Tool closed."
            exit 0
            ;;

        *)
            echo
            echo "[!] Invalid option."
            sleep 1
            ;;
    esac

done
