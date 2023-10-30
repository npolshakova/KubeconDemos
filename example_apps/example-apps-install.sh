# in ambient mode
kubectl label namespace default istio.io/dataplane-mode=ambient
kubectl apply -f sleep/sleep.yaml -n default
kubectl label namespace default istio.io/dataplane-mode=ambient
kubectl apply -f sleep/notsleep.yaml -n default

# in ambient mode
kubectl get namespace bookinfo &> /dev/null || kubectl create namespace bookinfo
kubectl label namespace bookinfo istio.io/dataplane-mode=ambient
kubectl apply -f bookinfo/bookinfo.yaml -n bookinfo

# in sidecar mode
kubectl get namespace helloworld &> /dev/null || kubectl create namespace helloworld
kubectl label namespace helloworld istio-injection=enabled --overwrite=true
kubectl apply -f helloworld/helloworld.yaml -n helloworld

# curl 
# kubectl run curl --image=radial/busyboxplus:curl -i --tty --rm