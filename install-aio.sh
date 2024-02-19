#!/bin/bash

# Download the content from the namada-aio.sh file and save it as namadaio
curl -sL https://raw.githubusercontent.com/tungdh1/namada-tools/main/namada-aio.sh | sudo tee /usr/local/bin/namadaio > /dev/null && sudo chmod +x /usr/local/bin/namadaio

echo "Finish install Namada All In One! Please run 'namadaio' to start using NamadaAIO Script."