# Provide the pi address and username as an argument
if [ $# -ne 2 ]; then
    echo "Usage: $0 <pi_address> <pi_username>" 
    exit 1
fi

# Store the provided address in a variable
export PI_ADDRESS="$1"
export PI_USERNAME="$2"

# Setup env for installing Istio and PI onboarding
export PI_APP="hello-pi"
export PI_NAMESPACE="pi-namespace"
export SERVICE_ACCOUNT="pi-sa"
export WORK_DIR="$PWD/pi-files"
# Customize values for multi-cluster/multi-network as needed
# Demo will assume single network setup
export CLUSTER_NETWORK="kube-network"
# export PI_NETWORK="pi-network"
export CLUSTER="cluster1"

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
    global:
      meshID: mesh1
      multiCluster:
        clusterName: "${CLUSTER}"
      network: "${CLUSTER_NETWORK}"
EOF
istioctl install -f pi-cluster.yaml --set values.pilot.env.PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION=true --set values.pilot.env.ISTIOD_SAN="istiod.istio-system.svc"

# Install east-west gateway
samples/multicluster/gen-eastwest-gateway.sh \
--mesh mesh1 --cluster "${CLUSTER}" --network "${CLUSTER_NETWORK}" | \
istioctl install -y -f -

# Expose istiod 
kubectl apply -f samples/multicluster/expose-istiod.yaml
# Expose svcs (only need for multinetwork setup)
# kubectl apply -n istio-system -f samples/multicluster/expose-services.yaml

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
    network: "${KUBE_NETWORK}"
EOF
kubectl --namespace "${PI_NAMESPACE}" apply -f workloadgroup.yaml

# Run istioctl to create the pi files and create WorkloadEntry 
istioctl x workload entry configure -f workloadgroup.yaml -o "${WORK_DIR}" --clusterID "${CLUSTER}"

# Copy the files to the pi

# ssh-copy-id 192.168.0.58
scp pi-files/* $PI_USERNAME@$PI_ADDRESS:~/pi-files

