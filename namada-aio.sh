#!/bin/bash

function namada_service_menu {
    while true
    do
        echo "Choose an option:"
        echo "1/ Start Namada Service"
        echo "2/ Stop Namada Service"
        echo "3/ Check Namada Service Status"
        echo "4/ Go back to the previous menu"
        echo -n "Enter your choice [1-4]: "
        read service_option
        case $service_option in
            1) echo "Starting Namada Service..."
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
            4) echo "Going back to the previous menu..."
               return;;
            *) echo "Invalid choice. Please try again."
               sleep 3;;
        esac
    done
}

while true
do
  clear
  echo "Welcome to OriginStake, please choose an option:"
  echo "1/ Install Namada - All in One Script"
  echo "2/ Start Namada"
  echo "3/ Exit"
  echo -n "Enter your choice [1-3]: "

  read option
  case $option in
    1) echo "You have chosen 'Install Namada - All in One Script'."
       echo "Please choose your operating system:"
       echo "1/ Linux"
       # echo "2/ MacOS (not yet supported)"
       echo -n "Enter your choice [1]: "
       read os_option
       case $os_option in
           1) OPERATING_SYSTEM="linux"; OPERATING_SYSTEM_CAP="Linux";;
           *) echo "Invalid choice. Please try again."
              sleep 3
              continue;;
       esac
       ARCHITECTURE="x86_64"
       # Check if jq is installed
       if ! command -v jq &> /dev/null
       then
           echo "jq is not installed. Installing..."
           # Install jq
           case $OPERATING_SYSTEM in
               "linux") sudo apt-get install jq;;
               "darwin") brew install jq;;
           esac
           echo "jq has been installed successfully."
       else
           echo "jq is already installed."
       fi
       # Install Namada
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
       # Install cometbft
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
           rm cometbft*.tar.gz  # Remove the tarball file after the binary file has been copied
           rm CHANGELOG.md LICENSE README.md SECURITY.md UPGRADING.md cometbft  # Remove unnecessary extracted files
           cometbft_version=$(cometbft version)
           echo "You have successfully installed cometbft Binary, the current version is $cometbft_version"
       else
           echo "CometBFT is already installed."
           cometbft_version=$(cometbft version)
           echo "The current version of CometBFT is $cometbft_version"
       fi

       # Create namadad service file
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

       # Clear terminal and display final message
       clear
       echo "You have successfully completed the installation of the OriginStake - Namada All in One script. Here is the current information:"
       echo "- Namada Version: $namada_version"
       echo "- Cometbft Version: $cometbft_version"
       echo "- A namadad.service file has been created. You can return to the main menu and start Namada."
       sleep 3;;

    2) namada_service_menu;;

    3) echo "You have chosen 'Exit'."
       exit 0;;
    *) echo "Invalid choice. Please try again."
       sleep 3;;
  esac
done