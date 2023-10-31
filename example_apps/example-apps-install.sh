# COMMON_SCRIPTS contains the directory this file is in.
COMMON_SCRIPTS=$(dirname "${BASH_SOURCE:-$0}")

# in ambient mode
kubectl label namespace default istio.io/dataplane-mode=ambient
kubectl apply -f $COMMON_SCRIPTS/sleep/sleep.yaml -n default
kubectl label namespace default istio.io/dataplane-mode=ambient
kubectl apply -f $COMMON_SCRIPTS/sleep/notsleep.yaml -n default

# in ambient mode
kubectl get namespace bookinfo &> /dev/null || kubectl create namespace bookinfo
kubectl label namespace bookinfo istio.io/dataplane-mode=ambient
kubectl apply -f $COMMON_SCRIPTS/bookinfo/bookinfo.yaml -n bookinfo

# in sidecar mode
kubectl get namespace helloworld &> /dev/null || kubectl create namespace helloworld
kubectl label namespace helloworld istio-injection=enabled --overwrite=true
kubectl apply -f $COMMON_SCRIPTS/helloworld/helloworld.yaml -n helloworld

# curl 
# kubectl run curl --image=radial/busyboxplus:curl -i --tty --rm