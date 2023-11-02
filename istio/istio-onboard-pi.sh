#!/bin/bash

# need istioctl installed
source ~/.bashrc

# Provide the pi address and username as an argument
if [ $# -le 2 ]; then
    echo "Usage: $0 <pi_address> <pi_username>"  "[--ztunnel]"
    exit 1
fi

# Store the provided address in a variable
PI_ADDRESS="$1"
PI_USERNAME="$2"

# Initialize ztunnel to be false by default
ztunnel_mode=false
# Check if the ztunnel flag is provided as a command line argument
while [[ $# -gt 0 ]]; do
    case "$3" in
        -f|--ztunnel)
            ztunnel_mode=true
            shift
            ;;
        *)
    esac
done

# Setup env for installing Istio and PI onboarding
PI_APP="hello-pi-${PI_ADDRESS}"
PI_NAMESPACE="pi-namespace"
SERVICE_ACCOUNT="pi-sa-${PI_ADDRESS}"
WORK_DIR="$PWD/pi-files"
# Customize values for multi-cluster/multi-network as needed
# Demo will assume single network setup
# CLUSTER_NETWORK="kube-network"
# PI_NETWORK="pi-network"
CLUSTER="Kubernetes"

# Create output directory for PI files
mkdir -p $WORK_DIR

# Create Pi Namespace and ServiceAccount
kubectl get namespace "$PI_NAMESPACE" &> /dev/null || kubectl create namespace "$PI_NAMESPACE"
# label namespace for ambient mode if running ztunnel
if [ "$run_all" = true ]; then
kubectl label namespace "$PI_NAMESPACE" istio.io/dataplane-mode=ambient
fi 
kubectl get serviceaccount "${SERVICE_ACCOUNT}" -n "${PI_NAMESPACE}" &> /dev/null || kubectl create serviceaccount "${SERVICE_ACCOUNT}" -n "${PI_NAMESPACE}"

# Create WorkloadGroup. We will use autoregistration so a WorkloadEntry will be generated from this WorkloadGroup
cat <<EOF > workloadgroup.yaml
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
  name: "${PI_APP}"
  namespace: "${PI_NAMESPACE}"
spec:
  metadata:
    labels:
      app: "${PI_APP}"
  template:
    serviceAccount: "${SERVICE_ACCOUNT}"
    network: "${CLUSTER_NETWORK}"
EOF
kubectl --namespace "${PI_NAMESPACE}" apply -f workloadgroup.yaml

# Run istioctl to create the pi files and create WorkloadEntry with a verrrrry long lived token for demo purposes 
# Optionally include --autoregister flag, but we are manually creating the WE for ztunnel to have the ambient label
istioctl x workload entry configure -f workloadgroup.yaml -o "${WORK_DIR}" --clusterID "${CLUSTER}" --tokenDuration=86400

if [ "$run_all" = true ]; then
# Ztunnel setup needs to manually create workloadentry with ambient label: 
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadEntry
metadata:
  labels:
    app: "${PI_APP}"
  name: "${PI_APP}"
  namespace: "${PI_NAMESPACE}"
spec:
  address: "${PI_ADDRESS}"
  labels:
    app: "${PI_APP}"
    ambient.istio.io/redirection: enabled
  serviceAccount: "${SERVICE_ACCOUNT}"
EOF
else
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadEntry
metadata:
  labels:
    app: "${PI_APP}"
  name: "${PI_APP}"
  namespace: "${PI_NAMESPACE}"
spec:
  address: "${PI_ADDRESS}"
  labels:
    app: "${PI_APP}"
  serviceAccount: "${SERVICE_ACCOUNT}"
EOF
fi

# Copy the files to the pi
# ssh-copy-id 192.168.0.58
scp -r pi-files $PI_USERNAME@$PI_ADDRESS:~

# Optionally, you may also want to add an SSH key if not already done to avoid password prompts during the SCP operation.
# ssh-copy-id "$PI_USERNAME@$PI_ADDRESS"