#! /bin/bash

USER_NAME="gateway"

printf "\nRemove packages ...\n\n"
sudo apt -y purge cloud-init
sudo rm -rf /etc/cloud/
sudo rm -rf /var/lib/cloud/

printf "\nAdd analysis tools repositories ...\n\n"
printf "\nTOR\n"
sudo curl https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | sudo gpg --import
sudo gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add - 
sudo sh -c 'echo "deb https://deb.torproject.org/torproject.org focal main" > /etc/apt/sources.list.d/tor.list'
sudo sh -c 'echo "deb-src https://deb.torproject.org/torproject.org focal main" >> /etc/apt/sources.list.d/tor.list'
printf "\nINetSim\n"
sudo echo "deb http://www.inetsim.org/debian/ binary/" > /etc/apt/sources.list.d/inetsim.list
sudo wget -O - https://www.inetsim.org/inetsim-archive-signing-key.asc | sudo apt-key add - 
printf "\nCode\n"
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > ~/microsoft.gpg
sudo install -o root -g root -m 644 ~/microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
printf "\nWireshark\n"
sudo add-apt-repository ppa:wireshark-dev/stable -y

printf "\nPolarProxy\n"
sudo adduser --system --shell /bin/bash proxyuser 
sudo mkdir /var/log/PolarProxy
sudo chown proxyuser:root /var/log/PolarProxy/
sudo chmod 0775 /var/log/PolarProxy/ 
mkdir ~/PolarProxy
cd ~/PolarProxy
curl https://www.netresec.com/?download=PolarProxy | tar -xzvf - 
sudo mv ~/PolarProxy /home/proxyuser/
sudo chown -R proxyuser /home/proxyuser/PolarProxy/
sudo cp /home/proxyuser/PolarProxy/PolarProxy.service /etc/systemd/system/PolarProxy.service 

printf "\nUpdates ...\n\n"
sudo apt update
printf "\nInstall utilities ...\n\n"
sudo apt -y install ncdu bat htop most mc arj zip p7zip net-tools apt-transport-https scrot --no-install-recommends
cd /usr/bin/; curl https://getmic.ro | sudo bash
printf "\nInstall graphical utilities ...\n\n"
sudo apt -y install xserver-xorg xclip xsel xdm openbox caja engrampa eom mousepad tilix conky rofi dunst firefox zim fonts-mononoki adwaita-icon-theme-full mate-polkit --no-install-recommends
sudo apt -y install gvfs-backends caja-open-terminal
printf "\nInstall build tools ...\n\n"
sudo apt -y install build-essential python3-pip python3-venv python-is-python3 openjdk-14-jre-headless --no-install-recommends

printf "\nInstall analysis tools from repositories ...\n\n"
sudo apt -y install tor deb.torproject.org-keyring code wireshark iptables-persistent netcat-openbsd inetsim inspircd --no-install-recommends

printf "\nSetup Wireshark ...\n\n"
sudo usermod -a -G wireshark "$USER_NAME"

printf "\nSetup INetSim manager ...\n\n"
sudo usermod -a -G inetsim "$USER_NAME"
sudo chgrp -R inetsim /var/log/inetsim
sudo chmod 770 /var/log/inetsim

printf "\nDisable services ...\n\n"
sudo systemctl disable tor.service
sudo systemctl disable inspircd.service
sudo systemctl disable inetsim.service

printf "\nClean-up ...\n\n"
sudo apt -y autoremove
sudo apt clean
