#!/bin/bash
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <pi_address-ztunnel> <pi_address-sidecar>"
    exit 1
fi

# Store the provided address in a variable
PI_ADDRESS_ZTUNNEL="$1"
PI_ADDRESS_SIDECAR="$2"
export PI_ADDRESS_ZTUNNEL=${PI_ADDRESS_ZTUNNEL}
export PI_ADDRESS_SIDECAR=${PI_ADDRESS_SIDECAR}

export PI_NAMESPACE="pi-namespace"

# Setup env for policy applications
export PI_APP_ZTUNNEL="hello-pi-${PI_ADDRESS_ZTUNNEL}"
export PI_SERVICE_ACCOUNT_ZTUNNEL="pi-sa-${PI_ADDRESS_ZTUNNEL}"

export PI_APP_SIDECAR="hello-pi-${PI_ADDRESS_SIDECAR}"
export PI_SERVICE_ACCOUNT_SIDECAR="pi-sa-${PI_ADDRESS_SIDECAR}"