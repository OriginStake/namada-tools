#!/bin/bash

# Define some colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m' # No Color

NEWCHAINID=shielded-expedition.88f17d1d14

function namada_service_menu {
    while true
    do
        echo "Choose an option:"
        echo "1/ Start Namada Service as a Post-Genesis"
        echo "2/ Stop Namada Service"
        echo "3/ Check Namada Service Status"
        echo "4/ Remove all Namada install (CAUTION)"
        echo "5/ Go back to the previous menu"
        echo -n "Enter your choice [1-5]: "
        read service_option
        case $service_option in
            1) echo "Starting Namada Service as a Post-Genesis..."
               cd $HOME && namada client utils join-network --chain-id $NEWCHAINID
               sudo systemctl enable namadad && sudo systemctl start namadad
               echo "Namada Service has been started."
               sleep 3;;
            2) echo "Stopping Namada Service..."
               sudo systemctl stop namadad
               echo "Namada Service has been stopped."
               sleep 3;;
            3) echo "Checking Namada Service status..."
               systemctl status namadad
               echo "Press any key to continue..."
               read -n 1 -s;;
            4) echo "You have chosen 'Remove all Namada install (CAUTION)'."
               echo "The system will automatically delete the current Namada working directory and back it up to the following path: $HOME/namada_backup/. Please be careful and make sure that you have backed up the necessary files. This action cannot be undone."
               echo "Are you sure you want to proceed? (Yes/No):"
               read confirmation
               if [[ "${confirmation,,}" == "yes" ]]; then
                   echo "Please confirm again (Yes/No):"
                   read confirmation2
                   if [[ "${confirmation2,,}" == "yes" ]]; then
                       echo "Please confirm one last time (Yes/No):"
                       read confirmation3
                       if [[ "${confirmation3,,}" == "yes" ]]; then
                           echo "Removing all Namada install..."
                           cd $HOME && mkdir $HOME/namada_backup
                           cp -r $HOME/.local/share/namada/ $HOME/namada_backup/
                           systemctl stop namadad && systemctl disable namadad
                           rm /etc/systemd/system/namada* -rf
                           rm $(which namada) -rf
                           rm /usr/local/bin/namada* /usr/local/bin/cometbft -rf
                           rm $HOME/.namada* -rf
                           rm $HOME/.local/share/namada -rf
                           rm $HOME/namada -rf
                           rm $HOME/cometbft -rf
                           echo "All Namada installs have been removed."
                           sleep 3
                       else
                           echo "Operation cancelled."
                           sleep 3
                       fi
                   else
                       echo "Operation cancelled."
                       sleep 3
                   fi
               else
                   echo "Operation cancelled."
                   sleep 3
               fi;;
            5) echo "Going back to the previous menu..."
               return;;
            *) echo "Invalid choice. Please try again."
               sleep 3;;
        esac
    done
}

while true
do
  clear
  echo -e "${GREEN}Welcome to OriginStake - Namada AIO Install Script${NC}"
  echo -e "${GREEN}Here are your current settings:${NC}"
  echo -e "${BOLD}ChainID:${NC} ${GREEN}$NEWCHAINID${NC}"
  if command -v namada &> /dev/null; then
    echo -e "${BOLD}Namada version:${NC} ${GREEN}$(namada --version)${NC}"
  else
    echo -e "${BOLD}Namada:${NC} ${RED}Not installed${NC}"
  fi
  if command -v cometbft &> /dev/null; then
    echo -e "${BOLD}CometBFT version:${NC} ${GREEN}$(cometbft version)${NC}"
  else
    echo -e "${BOLD}CometBFT:${NC} ${RED}Not installed${NC}"
  fi
  echo "Please choose an option:"
  echo "1/ Install Namada - All in One Script"
  echo "2/ Start/Stop/Check/Remove Namada Service"
  echo "3/ Exit"
  echo -n "Enter your choice [1-3]: "

  read option
  case $option in
    1) echo "You have chosen 'Install Namada - All in One Script'."
       echo "Please choose your operating system:"
       echo "1/ Linux"
       echo -n "Enter your choice [1]: "
       read os_option
       case $os_option in
           1) OPERATING_SYSTEM="linux"; OPERATING_SYSTEM_CAP="Linux";;
           *) echo "Invalid choice. Please try again."
              sleep 3
              continue;;
       esac
       ARCHITECTURE="x86_64"

       echo "Updating and upgrading the system..."
       sudo apt update -y && sudo apt upgrade -y

       if ! command -v jq &> /dev/null
       then
           echo "jq is not installed. Installing..."
           case $OPERATING_SYSTEM in
               "linux") sudo apt-get install -y jq;;
           esac
           echo "jq has been installed successfully."
       else
           echo "jq is already installed."
       fi
       echo "Checking Namada..."
       if ! command -v namada &> /dev/null && ! command -v namadaw &> /dev/null && ! command -v namadan &> /dev/null && ! command -v namadac &> /dev/null
       then
           echo "Namada is not installed. Installing..."
           latest_release_url=$(curl -s "https://api.github.com/repos/anoma/namada/releases/latest" | jq -r ".assets[] | select(.name | test(\"$OPERATING_SYSTEM_CAP-$ARCHITECTURE\")) | .browser_download_url")
           if [ -z "$latest_release_url" ]; then
               echo "Unable to determine download URL. Please check again."
               exit 1
           fi
           curl -L $latest_release_url -o namada.tar.gz
           if [ $? -ne 0 ]; then
               echo "Unable to download the file. Please check again."
               exit 1
           fi
           tar -xvf namada.tar.gz
           if [ $? -ne 0 ]; then
               echo "Unable to extract the file. Please check again."
               exit 1
           fi
           dirname=$(tar -tzf namada.tar.gz | head -1 | cut -f1 -d"/")
           sudo mv $dirname/* /usr/local/bin/
           rm -r $dirname namada.tar.gz
           namada_version=$(namada --version)
           echo "You have successfully installed Namada Binary, the current version is $namada_version"
       else
           echo "Namada is already installed."
           namada_version=$(namada --version)
           echo "The current version of Namada is $namada_version"
       fi
       echo "Checking CometBFT..."
       if ! command -v cometbft &> /dev/null
       then
           echo "CometBFT is not installed. Installing..."
           cometbft_release_info=$(curl -s "https://api.github.com/repos/cometbft/cometbft/releases/tags/v0.37.2")
           machine=$(uname -m)
           if [ "$machine" == "x86_64" ]; then
             machine="amd64"
           fi
           cometbft_download_url=$(echo $cometbft_release_info | jq -r ".assets[] | select(.name | test(\"$OPERATING_SYSTEM\")) | select(.name | test(\"$machine\")) | .browser_download_url")
           if [ "$cometbft_download_url" == "null" ]; then
             echo "There are no binaries to download from this tag."
             exit 1
           fi
           wget "$cometbft_download_url"
           tar -xzvf cometbft*.tar.gz
           sudo cp ./cometbft /usr/local/bin/
           rm cometbft*.tar.gz
           rm CHANGELOG.md LICENSE README.md SECURITY.md UPGRADING.md cometbft
           cometbft_version=$(cometbft version)
           echo "You have successfully installed cometbft Binary, the current version is $cometbft_version"
       else
           echo "CometBFT is already installed."
           cometbft_version=$(cometbft version)
           echo "The current version of CometBFT is $cometbft_version"
       fi

       echo "Creating namadad service file..."
       sudo bash -c "cat > /etc/systemd/system/namadad.service" << EOF
[Unit]
Description=namada
After=network-online.target
[Service]
User=$(whoami)
WorkingDirectory=/root/.local/share/namada
Environment=TM_LOG_LEVEL=p2p:none,pex:error
Environment=NAMADA_CMT_STDOUT=true
ExecStart=/usr/local/bin/namada node ledger run 
StandardOutput=syslog
StandardError=syslog
Restart=always
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
       sudo systemctl daemon-reload
       sudo systemctl enable namadad
       echo "The namadad service file has been created and activated."

       clear
       echo -e "${GREEN}You have successfully completed the installation of the OriginStake - Namada All in One script. Here is the current information:${NC}"
       echo -e "${BOLD}Namada Version:${NC} ${GREEN}$namada_version${NC}"
       echo -e "${BOLD}Cometbft Version:${NC} ${GREEN}$cometbft_version${NC}"
       echo "- A namadad.service file has been created. You can return to the main menu and start Namada."
       sleep 3;;

    2) namada_service_menu;;

    3) echo "You have chosen 'Exit'."
       exit 0;;
    *) echo "Invalid choice. Please try again."
       sleep 3;;
  esac
done