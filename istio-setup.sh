#!/bin/sh -ex

# Provide the pi address as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <pi_address>"
    exit 1
fi

# Store the provided address in a variable
PI_ADDRESS="$1"

# Setup env for installing Istio and VM onboarding
export VM_APP="hello-vm"
export VM_NAMESPACE="vm-namespace"
export SERVICE_ACCOUNT="vm-sa"
export WORK_DIR="$PWD/vm-files"
# Customize values for multi-cluster/multi-network as needed
# Demo will assume single network setup
export CLUSTER_NETWORK="kube-network"
export VM_NETWORK="vm-network"
export CLUSTER="cluster1"

# Create output directory for VM files
mkdir -p $WORK_DIR

# Install Istio
cat <<EOF > vm-cluster.yaml
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
    global:
      meshID: mesh1
      multiCluster:
        clusterName: "${CLUSTER}"
      network: "${CLUSTER_NETWORK}"
EOF
istioctl install -f vm-cluster.yaml --set values.pilot.env.PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION=true --set values.pilot.env.ISTIOD_SAN="istiod.istio-system.svc"

# Install east-west gateway
samples/multicluster/gen-eastwest-gateway.sh \
--mesh mesh1 --cluster "${CLUSTER}" --network "${CLUSTER_NETWORK}" | \
istioctl install -y -f -

# Expose istiod 
kubectl apply -f samples/multicluster/expose-istiod.yaml
# Expose svcs (only need for multinetwork setup)
# kubectl apply -n istio-system -f samples/multicluster/expose-services.yaml

# Create VM Namespace and ServiceAccount
kubectl create namespace "${VM_NAMESPACE}"
kubectl create serviceaccount "${SERVICE_ACCOUNT}" -n "${VM_NAMESPACE}"

# Create WorkloadGroup. We will use autoregistration so a WorkloadEntry will be generated from this WorkloadGroup
cat <<EOF > workloadgroup.yaml
apiVersion: networking.istio.io/v1alpha3
kind: WorkloadGroup
metadata:
  name: "${VM_APP}"
  namespace: "${VM_NAMESPACE}"
spec:
  metadata:
    labels:
      app: "${VM_APP}"
  template:
    serviceAccount: "${SERVICE_ACCOUNT}"
    network: "${VM_NETWORK}"
EOF
kubectl --namespace "${VM_NAMESPACE}" apply -f workloadgroup.yaml

# Run istioctl to create the vm files and create WorkloadEntry 
istioctl x workload entry configure -f workloadgroup.yaml -o "${WORK_DIR}" --clusterID "${CLUSTER}"

# Copy the files to the pi
scp ~/vm-files/* ninapolshakova@${PI_ADDERSS}:~/vm-files

