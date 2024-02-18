#!/bin/bash

while true
do
  clear
  echo "OriginStake xin chào, vui lòng lựa chọn chức năng sau:"
  echo "1/ Cài đặt Namada - All in One Script"
  echo "2/ Thoát"
  echo -n "Chọn lựa chọn của bạn [1-2]: "

  read option
  case $option in
    1) echo "Bạn đã chọn 'Cài đặt Namada - All in One Script'."
       echo "Vui lòng chọn hệ điều hành của bạn:"
       echo "1/ Linux"
       # echo "2/ MacOS (chưa hỗ trợ)"
       echo -n "Chọn lựa chọn của bạn [1]: "
       read os_option
       case $os_option in
           1) OPERATING_SYSTEM="linux"; OPERATING_SYSTEM_CAP="Linux";;
           *) echo "Lựa chọn không hợp lệ. Vui lòng thử lại."
              sleep 3
              continue;;
       esac
       ARCHITECTURE="x86_64"
       # Kiểm tra xem jq đã được cài đặt chưa
       if ! command -v jq &> /dev/null
       then
           echo "jq chưa được cài đặt. Đang cài đặt..."
           # Cài đặt jq
           case $OPERATING_SYSTEM in
               "linux") sudo apt-get install jq;;
               "darwin") brew install jq;;
           esac
           echo "jq đã được cài đặt thành công."
       else
           echo "jq đã được cài đặt."
       fi
       # Cài đặt Namada
       echo "Kiểm tra Namada..."
       if ! command -v namada &> /dev/null && ! command -v namadaw &> /dev/null && ! command -v namadan &> /dev/null && ! command -v namadac &> /dev/null
       then
           echo "Namada chưa được cài đặt. Đang cài đặt..."
           latest_release_url=$(curl -s "https://api.github.com/repos/anoma/namada/releases/latest" | jq -r ".assets[] | select(.name | test(\"$OPERATING_SYSTEM_CAP-$ARCHITECTURE\")) | .browser_download_url")
           if [ -z "$latest_release_url" ]; then
               echo "Không thể xác định URL tải xuống. Vui lòng kiểm tra lại."
               exit 1
           fi
           curl -L $latest_release_url -o namada.tar.gz
           if [ $? -ne 0 ]; then
               echo "Không thể tải xuống tệp. Vui lòng kiểm tra lại."
               exit 1
           fi
           tar -xvf namada.tar.gz
           if [ $? -ne 0 ]; then
               echo "Không thể giải nén tệp. Vui lòng kiểm tra lại."
               exit 1
           fi
           dirname=$(tar -tzf namada.tar.gz | head -1 | cut -f1 -d"/")
           sudo mv $dirname/* /usr/local/bin/
           rm -r $dirname namada.tar.gz
           namada_version=$(namada --version)
           echo "Bạn đã cài đặt Binary Namada thành công, Version hiện tại là $namada_version"
       else
           echo "Namada đã được cài đặt."
           namada_version=$(namada --version)
           echo "Version hiện tại của Namada là $namada_version"
       fi
       # Cài đặt cometbft
       echo "Kiểm tra CometBFT..."
       if ! command -v cometbft &> /dev/null
       then
           echo "CometBFT chưa được cài đặt. Đang cài đặt..."
           cometbft_release_info=$(curl -s "https://api.github.com/repos/cometbft/cometbft/releases/tags/v0.37.2")
           machine=$(uname -m)
           if [ "$machine" == "x86_64" ]; then
             machine="amd64"
           fi
           cometbft_download_url=$(echo $cometbft_release_info | jq -r ".assets[] | select(.name | test(\"$OPERATING_SYSTEM\")) | select(.name | test(\"$machine\")) | .browser_download_url")
           if [ "$cometbft_download_url" == "null" ]; then
             echo "Không có tệp nhị phân nào để tải xuống từ tag này."
             exit 1
           fi
           wget "$cometbft_download_url"
           tar -xzvf cometbft*.tar.gz
           sudo cp ./cometbft /usr/local/bin/
           rm cometbft*.tar.gz  # Xóa tệp tarball sau khi đã sao chép tệp nhị phân
           rm CHANGELOG.md LICENSE README.md SECURITY.md UPGRADING.md cometbft  # Xóa các tệp giải nén không cần thiết
           cometbft_version=$(cometbft version)
           echo "Bạn đã cài đặt Binary cometbft thành công, Version hiện tại là $cometbft_version"
       else
           echo "CometBFT đã được cài đặt."
           cometbft_version=$(cometbft version)
           echo "Version hiện tại của CometBFT là $cometbft_version"
       fi

       # Tạo file service namadad
       echo "Tạo file service namadad..."
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
       echo "File service namadad đã được tạo và kích hoạt."

       # Clear terminal and display final message
       clear
       echo "Bạn đã hoàn tất cài đặt script OriginStake - Namada All in One. Đây là thông tin hiện tại"
       echo "- Namada Version: $namada_version"
       echo "- Cometbft Version: $cometbft_version"
       echo "- Đã tạo file namadad.service. Bạn có thể quay trở về menu đầu tiên và bắt đầu khởi động Namada."
       exit 0;;

    2) echo "Bạn đã chọn 'Thoát'."
       exit 0;;
    *) echo "Lựa chọn không hợp lệ. Vui lòng thử lại."
       sleep 3;;
  esac
done