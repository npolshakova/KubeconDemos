#!/bin/bash

# need istioctl installed
source ~/.bashrc

# Provide the pi address and username as an argument
if [ $# -ne 2 ]; then
    echo "Usage: $0 <pi_address> <pi_username>" 
    exit 1
fi

# Store the provided address in a variable
PI_ADDRESS="$1"
PI_USERNAME="$2"

# Setup env for installing Istio and PI onboarding
PI_APP="hello-pi"
PI_NAMESPACE="pi-namespace"
SERVICE_ACCOUNT="pi-sa"
WORK_DIR="$PWD/pi-files"
# Customize values for multi-cluster/multi-network as needed
# Demo will assume single network setup
# CLUSTER_NETWORK="kube-network"
# PI_NETWORK="pi-network"
CLUSTER="Kubernetes"

# Create output directory for PI files
mkdir -p $WORK_DIR

# Install Istio
cat <<EOF > pi-cluster.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  name: istio
spec:
  meshConfig:
    defaultConfig:
      proxyMetadata:
        ISTIO_META_DNS_CAPTURE: "true"
        ISTIO_META_DNS_AUTO_ALLOCATE: "true"
        ISTIO_META_DNS_PROXY_ADDR: "127.0.0.1:15053"
  profile: ambient
  values:
    ztunnel:
      meshConfig:
        defaultConfig:
          proxyMetadata:
            ISTIO_META_DNS_CAPTURE: "true"
            ISTIO_META_DNS_AUTO_ALLOCATE: "true"
            ISTIO_META_DNS_PROXY_ADDR: "127.0.0.1:15053"
EOF
istioctl install -f pi-cluster.yaml --set values.pilot.env.PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION=true --set values.pilot.env.ISTIOD_SAN="istiod.istio-system.svc"

# Install east-west gateway
# Multinetwork:  multicluster/gen-eastwest-gateway.sh \
# --mesh mesh1 --cluster "${CLUSTER}" --network "${CLUSTER_NETWORK}" | \
# istioctl install -y -f -

# Singlenetwork:
multicluster/gen-eastwest-gateway.sh --single-cluster | istioctl install -y -f -

# Expose istiod 
kubectl apply -f multicluster/expose-istiod.yaml
# Expose svcs (only need for multinetwork setup)
# kubectl apply -n istio-system -f multicluster/expose-services.yaml

# Create Pi Namespace and ServiceAccount
kubectl get namespace "$PI_NAMESPACE" &> /dev/null || kubectl create namespace "$PI_NAMESPACE"
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

# Run istioctl to create the pi files and create WorkloadEntry 
istioctl x workload entry configure -f workloadgroup.yaml -o "${WORK_DIR}" --clusterID "${CLUSTER}" --autoregister

# Ztunnel setup needs to manually create workloadentry: 
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

# Copy the files to the pi
# ssh-copy-id 192.168.0.58
scp -r pi-files $PI_USERNAME@$PI_ADDRESS:~

# Optionally, you may also want to add an SSH key if not already done to avoid password prompts during the SCP operation.
# ssh-copy-id "$PI_USERNAME@$PI_ADDRESS"
