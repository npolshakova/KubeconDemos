#!/bin/bash

# Provide the east-west gateway address as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <istio_ew_address>"
    exit 1
fi

# Store the provided address in a variable
ISTIO_EW_ADDRESS="$1"

# Sidecar demo
curl -LO https://storage.googleapis.com/istio-release/releases/1.19.0/deb/istio-sidecar-arm64.deb
sudo dpkg -i istio-sidecar.deb

# Setup vm files 
cd vm-files

sudo mkdir -p /etc/certs
sudo cp root-cert.pem /etc/certs/root-cert.pem
sudo  mkdir -p /var/run/secrets/tokens
sudo cp istio-token /var/run/secrets/tokens/istio-token
sudo  mkdir -p ./var/run/secrets/tokens
sudo cp istio-token ./var/run/secrets/tokens/istio-token

# Config setup for running sidecar
sudo cp cluster.env /var/lib/istio/envoy/cluster.env 
sudo cp mesh.yaml /etc/istio/config/mesh 

# Add address to /etc/hosts to reach istiod for onboarding VM and xDS updates
echo "${ISTIO_EW_ADDRESS} istiod.istio-system.svc" | sudo tee -a /etc/hosts

sudo mkdir -p /etc/istio/proxy
sudo chown -R istio-proxy /var/lib/istio /etc/certs /etc/istio/proxy /etc/istio/config /var/run/secrets /etc/certs/root-cert.pem /var/run/secrets/istio/root-cert.pem

