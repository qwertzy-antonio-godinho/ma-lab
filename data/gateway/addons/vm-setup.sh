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
printf "\nCode\n"
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > ~/microsoft.gpg
sudo install -o root -g root -m 644 ~/microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
printf "\nWireshark\n"
sudo add-apt-repository ppa:wireshark-dev/stable

printf "\nPolarProxy\n"
sudo adduser --system --shell /bin/bash proxyuser 
sudo mkdir /var/log/PolarProxy
sudo chown proxyuser:root /var/log/PolarProxy/
sudo chmod 0775 /var/log/PolarProxy/ 
mkdir ~/PolarProxy
cd ~/PolarProxy/
curl https://www.netresec.com/?download=PolarProxy | tar -xzf - 
cd ..
sudo mv ~/PolarProxy /home/proxyuser/
sudo chown -R proxyuser /home/proxyuser/PolarProxy/
sudo cp /home/proxyuser/PolarProxy/PolarProxy.service /etc/systemd/system/PolarProxy.service 

printf "\nUpdates ...\n\n"
sudo apt update
printf "\nInstall utilities ...\n\n"
sudo apt -y install ncdu htop mc arj zip p7zip net-tools apt-transport-https scrot --no-install-recommends
printf "\nInstall graphical utilities ...\n\n"
sudo apt -y install xserver-xorg xclip xsel xdm openbox caja engrampa eom mousepad tilix conky rofi dunst firefox zim fonts-mononoki --no-install-recommends
printf "\nInstall build tools ...\n\n"
sudo apt -y install build-essential python3-pip python3-venv python-is-python3 openjdk-14-jre-headless --no-install-recommends

printf "\nInstall analysis tools from repositories ...\n\n"
sudo apt -y install tor deb.torproject.org-keyring code wireshark --no-install-recommends
sudo systemctl disable tor

printf "\nSetup lab directories ...\n\n"
sudo mkdir /lab
sudo chown -R "$USER_NAME" /lab
mkdir /lab/tools /lab/downloads /lab/garbage /lab/notebooks /lab/oracle /lab/samples /lab/sandbox /lab/SWAP /lab/automate /lab/data 

printf "\nClean-up ...\n\n"
sudo usermod -a -G wireshark "$USER_NAME"
sudo apt -y autoremove
sudo apt clean