#!/bin/sh

echo 'please wait a few seconds...'

sleep 1

sudo apt-get install -y macchanger pwgen python curl wget cowsay figlet wireless_tools net-tools

sudo pacman -Syu macchanger pwgen python curl wget cowsay figlet wireless_tools net-tools

sudo dnf install macchanger pwgen python curl wget cowsay figlet wireless_tools net-tools

sudo apk install macchanger pwgen python curl wget cowsay figlet wireless_tools net-tools

#clear

chmod u+x main.sh

figlet "Done!"
