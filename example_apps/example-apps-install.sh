# COMMON_SCRIPTS contains the directory this file is in.
COMMON_SCRIPTS=$(dirname "${BASH_SOURCE:-$0}")

# in ambient mode
kubectl label namespace default istio.io/dataplane-mode=ambient
kubectl apply -f $COMMON_SCRIPTS/sleep/sleep.yaml -n default
kubectl label namespace default istio.io/dataplane-mode=ambient
kubectl apply -f $COMMON_SCRIPTS/sleep/notsleep.yaml -n default

# in ambient mode
kubectl create namespace bookinfo --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace bookinfo istio.io/dataplane-mode=ambient
kubectl apply -f $COMMON_SCRIPTS/bookinfo/bookinfo.yaml -n bookinfo

# in sidecar mode
kubectl create namespace helloworld --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace helloworld istio-injection=enabled --overwrite=true
kubectl apply -f $COMMON_SCRIPTS/helloworld/helloworld.yaml -n helloworld

# curl 
# kubectl run curl --image=radial/busyboxplus:curl -i --tty --rm