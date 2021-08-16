#!/bin/sh

echo 'please wait a few seconds...'

sleep 1

sudo rm -r ~/local/share/NacreousDawn596/WiSpammer

sudo apt-get update

sudo apt-get upgrade

sudo apt-get install -y mdk3 macchanger pwgen figlet python3 curl wget cowsay

sudo pacman -S mdk3 macchanger pwgen figlet python3 curl wget cowsay

sudo dnf install mdk3 macchanger pwgen figlet python3 curl wget cowsay

sudo wget https://http.kali.org/kali/pool/main/k/kali-archive-keyring/kali-archive-keyring_2018.1_all.deb

sudo apt-apt install ./kali-archive-keyring_2018.1_all.deb

sudo pacman -S ./kali-archive-keyring_2018.1_all.deb

sudo dnf install ./kali-archive-keyring_2018.1_all.deb

echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" >> /etc/apt/sources.list

echo "" >> /etc/apt/sources.list

echo "deb http://repo.kali.org/kali kali-bleeding-edge main" >> /etc/apt/sources.list

echo "" >> /etc/apt/sources.list

cd ..

mkdir ~/.local/share/NacreousDawn596

mv WiSpammer/ ~/.local/share/NacreousDawn596/

echo "" >> ~/.bashrc

echo "source ~/.local/share/NacreousDawn596/WiSpammer/.wisp.sh" >> ~/.bashrc

clear

figlet "Done!"

rm ~/.local/share/NacreousDawn596/WiSpammer/setup.sh

cd
