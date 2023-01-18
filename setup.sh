#!/bin/sh

echo 'please wait a few seconds...'

sleep 1

sudo apt-get install -y mdk3 macchanger pwgen python3 curl wget cowsay figlet wireless_tools net-tools

sudo pacman -Syu macchanger pwgen python3 curl wget cowsay figlet wireless_tools net-tools

sudo dnf install mdk3 macchanger pwgen python3 curl wget cowsay figlet wireless_tools net-tools

sudo apk install mdk3 macchanger pwgen python3 curl wget cowsay figlet wireless_tools net-tools

#clear

chmod u+x main.sh

figlet "Done!"
