#!/bin/bash

# Colors
WHITE="\e[0;17m"
BOLD_WHITE="\e[1;37m"
BLACK="\e[0;30m"
BLUE="\e[0;34m"
BOLD_BLUE="\e[1;34m"
GREEN="\e[0;32m"
BOLD_GREEN="\e[1;32m"
RED="\e[0;31m"
BOLD_RED="\e[1;31m"

# Global variable for the active interface
ACTIVE_AD=""
ORIGINAL_AD=""

function exitss() {
    echo -e "\n$BOLD_BLUE Cleaning up..."
    if [ ! -z "$ACTIVE_AD" ] && [ "$ACTIVE_AD" != "$ORIGINAL_AD" ]; then
        if command -v airmon-ng &> /dev/null; then
            echo -e "$BOLD_BLUE [!] Stopping monitor mode on $ACTIVE_AD..."
            airmon-ng stop $ACTIVE_AD > /dev/null 2>&1
        fi
    fi
    
    if [ ! -z "$ORIGINAL_AD" ]; then
        echo -e "$BOLD_BLUE [!] Restoring $ORIGINAL_AD..."
        # Force it down first to clear any lingering states
        ip link set $ORIGINAL_AD down > /dev/null 2>&1
        macchanger -p $ORIGINAL_AD > /dev/null 2>&1
        iwconfig $ORIGINAL_AD mode managed > /dev/null 2>&1
        ip link set $ORIGINAL_AD up > /dev/null 2>&1
        
        # Tell NetworkManager to manage it again
        nmcli device set $ORIGINAL_AD managed yes > /dev/null 2>&1
        nmcli device connect $ORIGINAL_AD > /dev/null 2>&1
    fi
    
    rm random.txt > /dev/null 2>&1
    rm .conf > /dev/null 2>&1
    echo -e "$BOLD_GREEN Done. I hope you enjoyed!"
    exit
}

function title() {
    clear
    figlet wispammer
    echo -e "$BOLD_WHITE                                           By NacreousDawn596  "
    echo " "
}

function setup_interface() {
    AD=$1
    ORIGINAL_AD=$1
    echo -e "$BOLD_BLUE [!] Preparing interface $AD..."
    
    # Aggressive kill of network services
    echo -e "$BOLD_BLUE [!] Silencing network services..."
    nmcli device set $AD managed no > /dev/null 2>&1
    nmcli device disconnect $AD > /dev/null 2>&1
    
    if command -v airmon-ng &> /dev/null; then
        echo -e "$BOLD_BLUE [!] Killing interfering processes..."
        airmon-ng check kill > /dev/null 2>&1
    fi
    
    pkill wpa_supplicant > /dev/null 2>&1
    pkill dhclient > /dev/null 2>&1
    rfkill unblock wifi > /dev/null 2>&1
    
    echo -e "$BOLD_BLUE [!] Enabling monitor mode..."
    if command -v airmon-ng &> /dev/null; then
        airmon-ng start $AD > /dev/null 2>&1
        
        # Force the "mon" suffix as requested
        if ip link show "${AD}mon" &> /dev/null; then
            ACTIVE_AD="${AD}mon"
        else
            # Some drivers don't rename, check if the original is still there but in monitor mode
            ACTIVE_AD=$AD
        fi
    else
        ACTIVE_AD=$AD
        ip link set $AD down > /dev/null 2>&1
        iwconfig $AD mode monitor || { echo -e "$BOLD_RED [!] Error: Manual monitor mode failed."; return 1; }
    fi

    echo -e "$BOLD_GREEN [!] Active interface: $ACTIVE_AD"
    
    echo -e "$BOLD_BLUE [!] Changing MAC address on $ACTIVE_AD..."
    ip link set $ACTIVE_AD down > /dev/null 2>&1
    macchanger -r $ACTIVE_AD || echo -e "$BOLD_RED [!] Warning: Could not change MAC address."
    ip link set $ACTIVE_AD up > /dev/null 2>&1
    
    sleep 2
    if ! ip link show $ACTIVE_AD | grep -q "UP"; then
        echo -e "$BOLD_RED [!] Error: Interface $ACTIVE_AD failed to come UP."
        # One last attempt to force it up
        ip link set $ACTIVE_AD up > /dev/null 2>&1
        if ! ip link show $ACTIVE_AD | grep -q "UP"; then
            return 1
        fi
    fi
    
    return 0
}

# Trap CTRL+C
trap exitss INT TERM

title
echo 'made by NacreousDawn596'
sleep 1

# Improved interface detection
WIFI_INTERFACES=$(iwconfig 2>&1 | grep "IEEE 802.11" | awk '{print $1}')

if [ -z "$WIFI_INTERFACES" ]; then
    echo -e "$BOLD_RED [!] No wireless interfaces detected!"
    echo -e "$BOLD_WHITE Available interfaces (all):"
    ifconfig | grep -e ": " | sed -e 's/: .*//g' | sed -e 's/^/   /'
else
    echo -e "$BOLD_BLUE   Your wireless interfaces: "
    echo -e "$BOLD_WHITE"
    for iface in $WIFI_INTERFACES; do
        echo "   $iface"
    done
fi

echo " "
echo -n -e "$BOLD_GREEN   Type your wireless interface > "
echo -n -e "$BOLD_WHITE"
read AD

if [ -z "$AD" ]; then
    echo -e "$BOLD_RED Invalid interface."
    exit 1
fi

# Initialize monitor mode immediately after selection
setup_interface "$AD" || exit 1

title
echo -e "$BOLD_GREEN  Choose an option:"
echo " "
echo -e "$BOLD_GREEN  1.$BOLD_WHITE custom word and time for the SSID"
echo -e "$BOLD_GREEN  2.$BOLD_WHITE create an wordlist for the SSIDs"
echo -e "$BOLD_GREEN  3.$BOLD_WHITE Use a random SSID word list"
echo " "
echo -n -e "$BOLD_GREEN  > "
echo -n -e "$BOLD_WHITE"
read user_input

if [ "$user_input" == "1" ]; then
    title
    echo -n -e "$BOLD_GREEN enter an SSID name > "
    echo -n -e "$BOLD_WHITE"
    read WORD
    echo -n -e "$BOLD_GREEN How many SSIDs do you want? > "
    echo -n -e "$BOLD_WHITE"
    read N
    
    python3 .name.py
    filename='.conf'
    name=$(cat $filename)
    
    COUNT=1
    while [ $COUNT -le $N ]; do
        echo "$WORD $COUNT" >> "${name}.txt"
        let COUNT=COUNT+1
    done
    
    echo -e "$BOLD_BLUE Starting process on $ACTIVE_AD..."
    echo " If you want to stop it, press CTRL+C."
    echo " "
    
    mdk3 $ACTIVE_AD b -f "./${name}.txt" -a -s 1000
    rm "${name}.txt"
    exitss

elif [ "$user_input" == "2" ]; then
    title
    echo 'what is the filename desired?'
    read OWN
    echo 'write an SSID name on every line' > "$OWN"
    nano "$OWN"
    
    echo -e "$BOLD_BLUE Starting process on $ACTIVE_AD..."
    echo " If you want to stop it, press CTRL+C."
    
    mdk3 $ACTIVE_AD b -f "./$OWN" -a -s $(wc -l "$OWN" | cut -f1 -d ' ')
    rm "$OWN"
    exitss

elif [ "$user_input" == "3" ]; then
    title
    echo -n -e "$BOLD_BLUE How many SSIDs do you want? > "
    echo -n -e "$BOLD_WHITE"
    read N
    
    COUNT=1
    while [ $COUNT -le $N ]; do
        echo $(pwgen 14 1) >> "RANDOM_wordlist.txt"
        let COUNT=COUNT+1
    done
    
    echo -e "$BOLD_GREEN Starting process on $ACTIVE_AD..."
    echo " If you want to stop it, press CTRL+C."
    echo " "
    
    mdk3 $ACTIVE_AD b -f ./RANDOM_wordlist.txt -a -s $N
    rm RANDOM_wordlist.txt
    exitss

else
    echo -e "$BOLD_RED Invalid option."
    exit 1
fi
