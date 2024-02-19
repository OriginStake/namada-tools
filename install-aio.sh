#!/bin/bash

# Download the content from the namada-aio.sh file and save it as namadaio
curl -sL https://raw.githubusercontent.com/tungdh1/namada-tools/main/namada-aio.sh | sudo tee /usr/local/bin/namadaio > /dev/null && sudo 

# Set execute permissions for the namadaio file
chmod +x namadaio

# Move the namadaio file to a common directory
mv namadaio /usr/local/bin/

echo "Finish install Namada All In One! Please run 'namadaio' to start using NamadaAIO Script."