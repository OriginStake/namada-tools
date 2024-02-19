#!/bin/bash

# Download the content from the namada-aio.sh file and save it as namadaio
wget -O namadaio https://raw.githubusercontent.com/tungdh1/namada-tools/main/namada-aio.sh

# Set execute permissions for the namadaio file
chmod +x namadaio

# Move the namadaio file to a common directory
mv namadaio /usr/local/bin/