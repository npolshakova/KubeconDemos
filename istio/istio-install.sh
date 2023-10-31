#!/bin/bash

# need istioctl installed
source ~/.bashrc

# Setup env for installing Istio
# Customize values for multi-cluster/multi-network as needed
# Demo will assume single network setup
# CLUSTER_NETWORK="kube-network"
CLUSTER="Kubernetes"

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