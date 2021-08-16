clear
WHITE="\e[0;17m"
BOLD_WHITE="\e[1;37m"
BLACK="\e[0;30m"
BLUE="\e[0;34m"
BOLD_BLUE="\e[1;34m"
GREEN="\e[0;32m"
BOLD_GREEN="\e[1;32m"

function exitss() {
figlet "wispammer"
clear
ifconfig $AD down > /dev/null 2>&1
macchanger -p $AD > /dev/null 2>&1
iwconfig $AD mode managed > /dev/null 2>&1
ifconfig $AD up > /dev/null 2>&1
rm random.txt > /dev/null 2>&1
nmcli device connect $AD > /dev/null 2>&1
clear
echo 'I hope you enjoyed'
exit
}

function title() {
figlet wispammer
echo -e "$BOLD_WHITE                                           By NacreousDawn596  "
echo " "
}

figlet "wispammer"
echo 'made by NacreousDawn596'
sleep 1
echo -e "$BOLD_BLUE   Your interfaces: "
echo -e -n "$BOLD_WHITE"
ifconfig | grep -e ": " | sed -e 's/: .*//g' | sed -e 's/^/   /'
echo " "
echo -n -e "$BOLD_GREEN   Type your wireless interface > "
echo -n -e "$BOLD_WHITE"
read AD
clear
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
clear
if [ $user_input == 1 ]; then
	nmcli device disconnect $AD > /dev/null 2>&1
	clear
	title
	echo -n -e "$BOLD_GREEN enter an SSID name > "
	echo -n -e "$BOLD_WHITE"
	read WORD
	echo -n -e "$BOLD_GREEN How many SSIDs do you want? > "
	echo -n -e "$BOLD_WHITE"
	read N
	COUNT=1
	while [ $COUNT -lt $N ] || [ $COUNT -eq $N ]; do
		echo $WORD $COUNT >> $WORD"_wordlist.txt"
		let COUNT=COUNT+1
	done
	clear
	title
	echo -e "$BOLD_BLUE Starting process..."
	echo " If you want to stop it, press CTRL+C."
	echo " "
	trap exitss EXIT
	sleep 1
	ifconfig $AD down
	macchanger -r $AD
	iwconfig $AD mode monitor
	ifconfig $AD up
	trap exitss EXIT
	mdk3 $AD b -f ./$WORD"_wordlist.txt" -a -s 1000
fi
if [ $user_input == 2 ]; then
	nmcli device disconnect $AD > /dev/null 2>&1
	clear
	title
	echo 'what is the filename desired?\n'
	read OWN
	echo $OWN
	echo 'write an SSID name on every line then delete this first line' > $OWN
	nano $OWN
	echo -n -e "$BOLD_WHITE"
	clear
	title
	echo -e "$BOLD_BLUE Starting process..."
	echo " If you want to stop it, press CTRL+C."
	echo -e "$BOLD_WHITE"
	sleep 1
	ifconfig $AD down
	macchanger -r $AD
	iwconfig $AD mode monitor
	ifconfig $AD up
	trap exitss EXIT
	mdk3 $AD b -f ./$OWN -a -s $(wc -l $OWN | cut -f1 -d ' ')
fi
if [ $user_input == 3 ]; then
	nmcli device disconnect $AD > /dev/null 2>&1
	clear
	title
	echo -n -e "$BOLD_BLUE How many SSIDs do you want? > "
	echo -n -e "$BOLD_WHITE"
	read N
	COUNT=1
	while [ $COUNT -lt $N ] || [ $COUNT -eq $N ]; do
		echo $(pwgen 14 1) >> "RANDOM_wordlist.txt"
		let COUNT=COUNT+1
	done
	clear
	title
	echo -e "$BOLD_GREEN Starting process..."
	echo " If you want to stop it, press CTRL+C."
	echo " "
	sleep 1
	ifconfig $AD down
	macchanger -r $AD
	iwconfig $AD mode monitor
	ifconfig $AD up
	trap exitss EXIT
	mdk3 $AD b -f ./RANDOM_wordlist.txt -a -s $N
fi
