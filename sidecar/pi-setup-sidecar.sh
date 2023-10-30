#!/bin/bash

# Provide the east-west gateway address as an argument, and optionally the path to the pi files
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <istio_ew_address> [pi-files-path]"
    exit 1
fi

# Store the provided address in a variable
ISTIO_EW_ADDRESS="$1"

# Set the default value for PI_FILE_PATH
PI_FILE_PATH="$PWD/pi-files"

# Check if a command-line argument was provided for pi files path
if [ ! -z "$2" ]; then
  PI_FILE_PATH="$2"
fi
echo "Using PI_FILE_PATH: $PI_FILE_PATH"

# Sidecar demo
curl -LO https://storage.googleapis.com/istio-release/releases/1.19.3/deb/istio-sidecar-arm64.deb
sudo dpkg -i istio-sidecar-arm64.deb

# Setup pi files 
sudo mkdir -p /etc/certs
sudo cp $PI_FILE_PATH/root-cert.pem /etc/certs/root-cert.pem
sudo  mkdir -p /var/run/secrets/tokens
sudo cp $PI_FILE_PATH/istio-token /var/run/secrets/tokens/istio-token

# Config setup for running sidecar
sudo cp $PI_FILE_PATH/cluster.env /var/lib/istio/envoy/cluster.env 
sudo cp $PI_FILE_PATH/mesh.yaml /etc/istio/config/mesh 

# Add address to /etc/hosts to reach istiod for onboarding PI and xDS updates
echo "${ISTIO_EW_ADDRESS} istiod.istio-system.svc" | sudo tee -a /etc/hosts

sudo mkdir -p /etc/istio/proxy
sudo chown -R istio-proxy /var/lib/istio /etc/certs /etc/istio/proxy /etc/istio/config /var/run/secrets /etc/certs/root-cert.pem

sudo systemctl start istio