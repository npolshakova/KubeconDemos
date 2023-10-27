#!/bin/bash

PI_INTERNAL_IP=$(ip route | grep default | awk '{print $3}')

# Provide the east-west gateway address as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <istio_ew_address>"
    exit 1
fi

# Store the provided address in a variable
ISTIO_EW_ADDRESS="$1"

sudo dpkg -i ztunnel_0.0.0-1_arm64.deb 

# Setup pi files 
cd pi-files

sudo mkdir -p ./var/run/secrets/tokens ./var/run/secrets/istio
sudo mkdir -p /etc/certs

sudo cp root-cert.pem /etc/certs/root-cert.pem
sudo cp root-cert.pem ./var/run/secrets/istio/root-cert.pem
sudo cp istio-token ./var/run/secrets/tokens/istio-token

# Config setup for running sidecar
sudo cp cluster.env ./var/lib/istio/envoy/cluster.env 
sudo cp mesh.yaml ./etc/istio/config/mesh 

# Add address to /etc/hosts to reach istiod for onboarding PI and xDS updates
echo "${ISTIO_EW_ADDRESS} istiod.istio-system.svc" | sudo tee -a /etc/hosts

sudo mkdir -p ./etc/istio/proxy
sudo chown -R istio-proxy ./var/lib/istio /etc/certs ./etc/istio/proxy ./etc/istio/config ./var/run/secrets /etc/certs/root-cert.pem ./var/run/secrets/istio/root-cert.pem 

sudo -u istio-proxy CA_ADDRESS="istiod.istio-system.svc:15012" XDS_ADDRESS="istiod.istio-system.svc:15012" CLUSTER_ID=cluster1 NETWORK=vm-network RUST_LOG=debug ISTIO_META_ENABLE_HBONE=true ISTIO_META_DNS_CAPTURE=true ISTIO_META_DNS_AUTO_ALLOCATE=true ISTIO_META_DNS_PROXY_ADDR="127.0.0.1:15053" ztunnel