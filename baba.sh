#!/usr/bin/env bash
# BABA CYBER TOOL v1.0
# Authorized security testing, defensive auditing and Linux administration helper.

set -o pipefail

VERSION="1.0"
TOOL_NAME="BABA CYBER TOOL"
REPORT_DIR="${HOME}/baba-reports"
mkdir -p "$REPORT_DIR"

RESET='\033[0m'
BOLD='\033[1m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
MAGENTA='\033[35m'
WHITE='\033[37m'

pause() {
    echo
    read -rp "Press Enter to continue..." _
}

header() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat <<'EOF'
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║                 ██████╗  █████╗ ██████╗  █████╗         ║
║                 ██╔══██╗██╔══██╗██╔══██╗██╔══██╗        ║
║                 ██████╔╝███████║██████╔╝███████║        ║
║                 ██╔══██╗██╔══██║██╔══██╗██╔══██║        ║
║                 ██████╔╝██║  ██║██████╔╝██║  ██║        ║
║                                                          ║
║                   BABA CYBER TOOL                        ║
║              RED TEAM | BLUE TEAM | SYSADMIN             ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
}

have() { command -v "$1" >/dev/null 2>&1; }

need() {
    if ! have "$1"; then
        echo -e "${YELLOW}[!] '$1' is not installed.${RESET}"
        return 1
    fi
    return 0
}

run_cmd() {
    echo -e "${BLUE}[+] Running:${RESET} $*"
    "$@"
}

system_info() {
    header
    echo -e "${CYAN}${BOLD}[1] SYSTEM INFORMATION${RESET}"
    echo "──────────────────────────────────────────────"
    echo "Hostname : $(hostname)"
    echo "User     : $(whoami)"
    echo "OS       : $(. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME")"
    echo "Kernel   : $(uname -r)"
    echo "Arch     : $(uname -m)"
    echo "Uptime   : $(uptime -p 2>/dev/null || uptime)"
    echo
    echo "CPU:"
    lscpu 2>/dev/null | grep -E 'Model name|CPU\(s\)' | head -n 2
    echo
    echo "Memory:"
    free -h
    echo
    echo "Disk:"
    df -hT --exclude-type=tmpfs --exclude-type=devtmpfs 2>/dev/null | head -n 12
    pause
}

network_info() {
    header
    echo -e "${CYAN}${BOLD}[2] NETWORK INFORMATION${RESET}"
    echo "──────────────────────────────────────────────"
    echo "Interfaces:"
    ip -br addr 2>/dev/null || ifconfig 2>/dev/null
    echo
    echo "Routes:"
    ip route 2>/dev/null
    echo
    echo "DNS:"
    if command -v resolvectl >/dev/null 2>&1; then
        resolvectl dns 2>/dev/null
    else
        cat /etc/resolv.conf 2>/dev/null | grep -E '^(nameserver|search)'
    fi
    pause
}

network_diag() {
    header
    echo -e "${CYAN}${BOLD}[3] NETWORK DIAGNOSTICS${RESET}"
    echo "──────────────────────────────────────────────"
    read -rp "Host/IP to test [1.1.1.1]: " target
    target="${target:-1.1.1.1}"
    echo
    if have ping; then
        echo "[+] Ping:"
        ping -c 4 -W 2 "$target"
    fi
    echo
    if have getent; then
        echo "[+] DNS/Name resolution:"
        getent hosts "$target" || true
    fi
    echo
    echo "[+] Default route:"
    ip route 2>/dev/null | grep '^default' || true
    pause
}

port_scanner() {
    header
    echo -e "${RED}${BOLD}[4] PORT SCANNER${RESET}"
    echo "──────────────────────────────────────────────"
    echo -e "${YELLOW}Use only against systems you own or are authorized to test.${RESET}"
    echo
    need nmap || { pause; return; }
    read -rp "Target IP/hostname: " target
    [[ -z "$target" ]] && { echo "[!] Target required."; pause; return; }

    echo
    echo "1) Quick/common ports"
    echo "2) Service/version detection"
    echo "3) Top 1000 TCP ports"
    echo "0) Back"
    read -rp "Select: " choice

    case "$choice" in
        1) nmap --top-ports 100 "$target" ;;
        2) nmap -sV --top-ports 100 "$target" ;;
        3) nmap --top-ports 1000 "$target" ;;
        0) return ;;
        *) echo "[!] Invalid option." ;;
    esac
    pause
}

service_enum() {
    header
    echo -e "${RED}${BOLD}[5] SERVICE ENUMERATION${RESET}"
    echo "──────────────────────────────────────────────"
    echo -e "${YELLOW}Authorized targets only.${RESET}"
    need nmap || { pause; return; }
    read -rp "Target IP/hostname: " target
    [[ -z "$target" ]] && { pause; return; }
    nmap -sV --top-ports 100 "$target"
    pause
}

web_enum() {
    header
    echo -e "${RED}${BOLD}[6] WEB ENUMERATION${RESET}"
    echo "──────────────────────────────────────────────"
    echo -e "${YELLOW}Use only on authorized lab/assessment targets.${RESET}"
    echo
    read -rp "URL (example: http://10.10.10.10): " url
    [[ -z "$url" ]] && { pause; return; }

    echo
    echo "[1] HTTP headers"
    echo "[2] robots.txt"
    echo "[3] sitemap.xml"
    echo "[4] Basic HTTP checks"
    echo "[0] Back"
    read -rp "Select: " choice

    case "$choice" in
        1)
            need curl && curl -I -L --max-time 10 "$url"
            ;;
        2)
            need curl && curl -L --max-time 10 "${url%/}/robots.txt"
            ;;
        3)
            need curl && curl -L --max-time 10 "${url%/}/sitemap.xml"
            ;;
        4)
            need curl && {
                echo "--- Headers ---"
                curl -I -L --max-time 10 "$url"
                echo
                echo "--- Status ---"
                curl -o /dev/null -s -w "HTTP %{http_code}\nTime %{time_total}s\n" "$url"
            }
            ;;
        0) return ;;
        *) echo "[!] Invalid option." ;;
    esac
    pause
}

dns_tools() {
    header
    echo -e "${CYAN}${BOLD}[7] DNS TOOLS${RESET}"
    echo "──────────────────────────────────────────────"
    read -rp "Domain/hostname: " domain
    [[ -z "$domain" ]] && { pause; return; }

    if have dig; then
        echo "[+] A/AAAA records:"
        dig +short A "$domain"
        dig +short AAAA "$domain"
        echo
        echo "[+] MX records:"
        dig +short MX "$domain"
        echo
        echo "[+] NS records:"
        dig +short NS "$domain"
    elif have nslookup; then
        nslookup "$domain"
    else
        echo "[!] Install dnsutils/bind-utils for dig or nslookup."
    fi
    pause
}

file_permissions() {
    header
    echo -e "${CYAN}${BOLD}[8] FILE & PERMISSION TOOLS${RESET}"
    echo "──────────────────────────────────────────────"
    echo "1) Inspect file permissions"
    echo "2) Find SUID files (local system)"
    echo "3) Find world-writable files in common system paths"
    echo "0) Back"
    read -rp "Select: " choice

    case "$choice" in
        1)
            read -rp "File/path: " path
            [[ -n "$path" ]] && ls -ld "$path" && stat "$path" 2>/dev/null
            ;;
        2)
            echo "[+] SUID files:"
            find / -type f -perm -4000 -user root 2>/dev/null | head -n 200
            ;;
        3)
            echo "[+] World-writable files in /etc and /usr/local:"
            find /etc /usr/local -type f -perm -0002 2>/dev/null | head -n 200
            ;;
        0) return ;;
        *) echo "[!] Invalid option." ;;
    esac
    pause
}

process_monitor() {
    header
    echo -e "${BLUE}${BOLD}[9] PROCESS & SERVICE MONITOR${RESET}"
    echo "──────────────────────────────────────────────"
    echo "[+] Top CPU processes:"
    ps aux --sort=-%cpu | head -n 12
    echo
    echo "[+] Top memory processes:"
    ps aux --sort=-%mem | head -n 12
    echo
    echo "[+] Listening sockets:"
    ss -tulpen 2>/dev/null | head -n 30
    echo
    if have systemctl; then
        echo "[+] Failed services:"
        systemctl --failed --no-pager 2>/dev/null || true
    fi
    pause
}

user_audit() {
    header
    echo -e "${BLUE}${BOLD}[10] USER & PRIVILEGE AUDIT${RESET}"
    echo "──────────────────────────────────────────────"
    echo "[+] Current user:"
    id
    echo
    echo "[+] Local users:"
    awk -F: '$3 >= 1000 || $1 == "root" {printf "%-20s UID=%-6s HOME=%s\n",$1,$3,$6}' /etc/passwd
    echo
    echo "[+] Sudo permissions:"
    sudo -n -l 2>&1 || sudo -l 2>&1 | head -n 60
    echo
    echo "[+] Recent login information:"
    last -n 10 2>/dev/null || true
    pause
}

log_analysis() {
    header
    echo -e "${BLUE}${BOLD}[11] LOG ANALYSIS${RESET}"
    echo "──────────────────────────────────────────────"
    echo "1) Recent authentication events"
    echo "2) Failed SSH/login attempts"
    echo "3) Recent system errors"
    echo "0) Back"
    read -rp "Select: " choice

    case "$choice" in
        1)
            if have journalctl; then
                journalctl -u ssh -n 80 --no-pager 2>/dev/null || journalctl -n 80 --no-pager
            else
                grep -Ei 'authentication|session|sudo|ssh' /var/log/auth.log 2>/dev/null | tail -n 80
            fi
            ;;
        2)
            if have journalctl; then
                journalctl --no-pager | grep -Ei 'failed password|authentication failure|invalid user' | tail -n 80
            else
                grep -Ei 'failed password|authentication failure|invalid user' /var/log/auth.log 2>/dev/null | tail -n 80
            fi
            ;;
        3)
            if have journalctl; then
                journalctl -p err..alert -n 80 --no-pager
            else
                grep -Ei 'error|failed|critical' /var/log/syslog 2>/dev/null | tail -n 80
            fi
            ;;
        0) return ;;
        *) echo "[!] Invalid option." ;;
    esac
    pause
}

security_audit() {
    header
    echo -e "${BLUE}${BOLD}[12] SECURITY AUDIT${RESET}"
    echo "──────────────────────────────────────────────"

    local score=0 total=0
    check() {
        local label="$1" result="$2"
        total=$((total+1))
        if [[ "$result" == "PASS" ]]; then
            echo -e "[+] $label : ${GREEN}PASS${RESET}"
            score=$((score+1))
        else
            echo -e "[!] $label : ${YELLOW}REVIEW${RESET}"
        fi
    }

    if have ufw; then
        ufw status 2>/dev/null | grep -qi active && check "UFW firewall" PASS || check "UFW firewall" REVIEW
    elif have firewall-cmd; then
        firewall-cmd --state 2>/dev/null | grep -qi running && check "Firewalld" PASS || check "Firewalld" REVIEW
    else
        check "Firewall tool detected" REVIEW
    fi

    if [[ -r /etc/ssh/sshd_config ]]; then
        grep -Eq '^[[:space:]]*PermitRootLogin[[:space:]]+no' /etc/ssh/sshd_config && \
            check "SSH root login disabled" PASS || check "SSH root login disabled" REVIEW
        grep -Eq '^[[:space:]]*PasswordAuthentication[[:space:]]+no' /etc/ssh/sshd_config && \
            check "SSH password authentication disabled" PASS || check "SSH password authentication" REVIEW
    fi

    if have ss; then
        local listening
        listening=$(ss -lntup 2>/dev/null | tail -n +2 | wc -l)
        echo "[i] Listening sockets: $listening"
    fi

    if [[ -f /etc/passwd ]]; then
        local uid0
        uid0=$(awk -F: '$3==0 {print $1}' /etc/passwd | tr '\n' ' ')
        echo "[i] UID 0 accounts: ${uid0:-none}"
    fi

    echo
    echo "Audit checks passed: $score / $total"
    pause
}

hash_tools() {
    header
    echo -e "${CYAN}${BOLD}[13] HASH TOOLS${RESET}"
    echo "──────────────────────────────────────────────"
    echo "1) Calculate file SHA256"
    echo "2) Calculate file MD5"
    echo "3) Identify hash format (local heuristic)"
    echo "0) Back"
    read -rp "Select: " choice

    case "$choice" in
        1)
            read -rp "File: " f
            [[ -f "$f" ]] && sha256sum "$f" || echo "[!] File not found."
            ;;
        2)
            read -rp "File: " f
            [[ -f "$f" ]] && md5sum "$f" || echo "[!] File not found."
            ;;
        3)
            read -rp "Hash: " h
            if [[ "$h" =~ ^[a-fA-F0-9]{32}$ ]]; then echo "Possible MD5"
            elif [[ "$h" =~ ^[a-fA-F0-9]{40}$ ]]; then echo "Possible SHA1"
            elif [[ "$h" =~ ^[a-fA-F0-9]{64}$ ]]; then echo "Possible SHA256"
            elif [[ "$h" =~ ^\$2[aby]\$[0-9]{2}\$ ]]; then echo "Possible bcrypt"
            elif [[ "$h" =~ ^\$6\$ ]]; then echo "Possible sha512crypt"
            elif [[ "$h" =~ ^\$5\$ ]]; then echo "Possible sha256crypt"
            else echo "Unknown / unsupported format"
            fi
            ;;
        0) return ;;
        *) echo "[!] Invalid option." ;;
    esac
    pause
}

wordlist_tools() {
    header
    echo -e "${RED}${BOLD}[14] PASSWORD / WORDLIST TOOLS${RESET}"
    echo "──────────────────────────────────────────────"
    echo -e "${YELLOW}For authorized labs, CTFs and password-audit work only.${RESET}"
    echo
    echo "1) Locate common wordlists"
    echo "2) Show rockyou.txt status"
    echo "3) Generate a small custom wordlist from supplied words"
    echo "0) Back"
    read -rp "Select: " choice

    case "$choice" in
        1)
            find /usr/share/wordlists "$HOME" -maxdepth 3 -type f 2>/dev/null | head -n 100
            ;;
        2)
            if [[ -f /usr/share/wordlists/rockyou.txt ]]; then
                ls -lh /usr/share/wordlists/rockyou.txt
            elif [[ -f /usr/share/wordlists/rockyou.txt.gz ]]; then
                ls -lh /usr/share/wordlists/rockyou.txt.gz
                echo "Hint: gunzip the archive if you are authorized to use it."
            else
                echo "rockyou.txt not found."
            fi
            ;;
        3)
            read -rp "Output file [custom.txt]: " out
            out="${out:-custom.txt}"
            echo "Enter words, one per line. Type DONE on a new line to finish."
            : > "$out"
            while IFS= read -r word; do
                [[ "$word" == "DONE" ]] && break
                [[ -n "$word" ]] && printf '%s\n' "$word" >> "$out"
            done
            sort -u "$out" -o "$out"
            echo "[+] Created: $out"
            ;;
        0) return ;;
        *) echo "[!] Invalid option." ;;
    esac
    pause
}

ssh_tools() {
    header
    echo -e "${CYAN}${BOLD}[15] SSH TOOLS${RESET}"
    echo "──────────────────────────────────────────────"
    echo "1) Test SSH connection"
    echo "2) Check local SSH configuration"
    echo "3) Show local SSH keys"
    echo "0) Back"
    read -rp "Select: " choice

    case "$choice" in
        1)
            read -rp "Username: " user
            read -rp "Host: " host
            read -rp "Port [22]: " port
            port="${port:-22}"
            ssh -o ConnectTimeout=7 -p "$port" "${user}@${host}"
            ;;
        2)
            if [[ -r /etc/ssh/sshd_config ]]; then
                grep -E '^[[:space:]]*(Port|PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|MaxAuthTries)' /etc/ssh/sshd_config
            else
                echo "[!] /etc/ssh/sshd_config not readable."
            fi
            ;;
        3)
            ls -lah "$HOME/.ssh" 2>/dev/null || echo "[!] ~/.ssh not found."
            ;;
        0) return ;;
        *) echo "[!] Invalid option." ;;
    esac
    pause
}

firewall_check() {
    header
    echo -e "${BLUE}${BOLD}[16] FIREWALL CHECK${RESET}"
    echo "──────────────────────────────────────────────"
    if have ufw; then
        ufw status verbose
    elif have firewall-cmd; then
        firewall-cmd --state
        firewall-cmd --list-all 2>/dev/null
    elif have nft; then
        sudo nft list ruleset 2>/dev/null | head -n 200
    elif have iptables; then
        sudo iptables -L -n -v 2>/dev/null | head -n 200
    else
        echo "[!] No supported firewall utility found."
    fi
    pause
}

installed_software() {
    header
    echo -e "${CYAN}${BOLD}[17] INSTALLED SOFTWARE${RESET}"
    echo "──────────────────────────────────────────────"
    if have dpkg; then
        dpkg-query -W -f='${binary:Package}\t${Version}\n' 2>/dev/null | sort | less -FRX
    elif have rpm; then
        rpm -qa | sort | less -FRX
    elif have pacman; then
        pacman -Q | less -FRX
    else
        echo "[!] Unsupported package manager."
    fi
}

system_cleanup() {
    header
    echo -e "${BLUE}${BOLD}[18] SYSTEM CLEANUP${RESET}"
    echo "──────────────────────────────────────────────"
    echo -e "${YELLOW}Cleanup can remove cached data. Review before confirming.${RESET}"
    echo
    df -h / 2>/dev/null
    echo
    if have apt; then
        read -rp "Run 'sudo apt clean'? [y/N]: " ans
        [[ "$ans" =~ ^[Yy]$ ]] && sudo apt clean
        read -rp "Run 'sudo apt autoremove'? [y/N]: " ans
        [[ "$ans" =~ ^[Yy]$ ]] && sudo apt autoremove
    elif have dnf; then
        read -rp "Run 'sudo dnf clean all'? [y/N]: " ans
        [[ "$ans" =~ ^[Yy]$ ]] && sudo dnf clean all
    elif have pacman; then
        echo "For pacman cache cleanup, review and use paccache manually."
    fi
    echo
    df -h / 2>/dev/null
    pause
}

generate_report() {
    header
    echo -e "${CYAN}${BOLD}[19] GENERATE REPORT${RESET}"
    echo "──────────────────────────────────────────────"
    local report="${REPORT_DIR}/baba-report-$(date +%Y%m%d-%H%M%S).txt"

    {
        echo "BABA CYBER TOOL v${VERSION}"
        echo "Generated: $(date)"
        echo "Hostname: $(hostname)"
        echo "User: $(whoami)"
        echo
        echo "=== SYSTEM ==="
        uname -a
        free -h
        df -h
        echo
        echo "=== NETWORK ==="
        ip -br addr 2>/dev/null
        ip route 2>/dev/null
        echo
        echo "=== LISTENING SOCKETS ==="
        ss -tulpen 2>/dev/null
        echo
        echo "=== USERS ==="
        awk -F: '$3 >= 1000 || $1 == "root" {print $1 ":" $3 ":" $6}' /etc/passwd
        echo
        echo "=== FAILED SERVICES ==="
        systemctl --failed --no-pager 2>/dev/null || true
    } > "$report"

    echo -e "${GREEN}[+] Report saved:${RESET} $report"
    pause
}

update_tool() {
    header
    echo -e "${CYAN}${BOLD}[20] UPDATE TOOL${RESET}"
    echo "──────────────────────────────────────────────"
    echo "This local version does not download or execute remote code."
    echo "You can replace this script with a reviewed newer version."
    echo
    echo "Current version: $VERSION"
    pause
}

main_menu() {
    while true; do
        header
        echo -e "${WHITE}${BOLD} System: $(hostname) | User: $(whoami) | $(date '+%Y-%m-%d %H:%M')${RESET}"
        echo
        echo -e "${RED}🔴 RED TEAM / LABS${RESET}"
        echo " 4. Port Scanner"
        echo " 5. Service Enumeration"
        echo " 6. Web Enumeration"
        echo
        echo -e "${BLUE}🔵 BLUE TEAM / SECURITY${RESET}"
        echo "11. Log Analysis"
        echo "12. Security Audit"
        echo "16. Firewall Check"
        echo
        echo -e "${MAGENTA}🖥️  SYSADMIN / GENERAL${RESET}"
        echo " 1. System Information"
        echo " 2. Network Information"
        echo " 3. Network Diagnostics"
        echo " 7. DNS Tools"
        echo " 8. File & Permission Tools"
        echo " 9. Process & Service Monitor"
        echo "10. User & Privilege Audit"
        echo "13. Hash Tools"
        echo "14. Password / Wordlist Tools"
        echo "15. SSH Tools"
        echo "17. Installed Software"
        echo "18. System Cleanup"
        echo "19. Generate Report"
        echo "20. Update Tool"
        echo
        echo " 0. Exit"
        echo
        read -rp "BABA@linux:~$ Select option: " choice

        case "$choice" in
            1) system_info ;;
            2) network_info ;;
            3) network_diag ;;
            4) port_scanner ;;
            5) service_enum ;;
            6) web_enum ;;
            7) dns_tools ;;
            8) file_permissions ;;
            9) process_monitor ;;
            10) user_audit ;;
            11) log_analysis ;;
            12) security_audit ;;
            13) hash_tools ;;
            14) wordlist_tools ;;
            15) ssh_tools ;;
            16) firewall_check ;;
            17) installed_software ;;
            18) system_cleanup ;;
            19) generate_report ;;
            20) update_tool ;;
            0)
                clear
                echo "BABA CYBER TOOL closed."
                exit 0
                ;;
            *) echo "[!] Invalid option."; sleep 1 ;;
        esac
    done
}

main_menu
