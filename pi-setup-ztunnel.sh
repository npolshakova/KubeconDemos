#!/bin/bash

# Get the internal IP address of the PI. You can remove `head -n 1` if only one ip is assigned
PI_INTERNAL_IP=$(ip route | grep default | awk '{print $3}' | head -n 1)

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

# setup networking rules (if not already setup)
sudo iptables-apply ztunnel-iptables-rules
sudo iptables -t nat -A OUTPUT ! -o lo -p udp -m udp --dport 53 -m owner ! --uid-owner 999 -j DNAT --to-destination $PI_INTERNAL_IP:15053

sudo dpkg -i ztunnel_0.0.0-1_arm64.deb 

# Setup pi files 
sudo mkdir -p ./var/run/secrets/tokens ./var/run/secrets/istio ./var/lib/istio/ztunnel
sudo mkdir -p /etc/certs

# Copy provisioned resources to the correct location 
sudo cp $PI_FILE_PATH/root-cert.pem /etc/certs/root-cert.pem
sudo cp $PI_FILE_PATH/root-cert.pem ./var/run/secrets/istio/root-cert.pem
sudo cp $PI_FILE_PATH/istio-token ./var/run/secrets/tokens/istio-token

# Config setup for running sidecar
sudo cp $PI_FILE_PATH/cluster.env ./var/lib/istio/ztunnel/cluster.env 
sudo cp $PI_FILE_PATH/mesh.yaml ./etc/istio/config/mesh 

# Add address to /etc/hosts to reach istiod for onboarding PI and xDS updates
echo "${ISTIO_EW_ADDRESS} istiod.istio-system.svc" | sudo tee -a /etc/hosts

sudo mkdir -p ./etc/istio/proxy
sudo chown -R istio-proxy ./var/lib/istio /etc/certs ./etc/istio/proxy ./var/run/secrets /etc/certs/root-cert.pem ./var/run/secrets/istio/root-cert.pem 

sudo -u istio-proxy CA_ADDRESS="istiod.istio-system.svc:15012" XDS_ADDRESS="istiod.istio-system.svc:15012" CLUSTER_ID=cluster1 NETWORK=kube-network RUST_LOG=debug ISTIO_META_ENABLE_HBONE=true ISTIO_META_DNS_CAPTURE=true ISTIO_META_DNS_AUTO_ALLOCATE=true ISTIO_META_DNS_PROXY_ADDR="127.0.0.1:15053" ztunnel