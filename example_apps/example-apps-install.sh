# COMMON_SCRIPTS contains the directory this file is in.
COMMON_SCRIPTS=$(dirname "${BASH_SOURCE:-$0}")

# sleep is in ambient mode
kubectl label namespace default istio.io/dataplane-mode=ambient --overwrite=true
kubectl apply -f $COMMON_SCRIPTS/sleep/sleep.yaml -n default
# notsleep is in sidecar mode
kubectl apply -f <(istioctl kube-inject -f $COMMON_SCRIPTS/sleep/notsleep.yaml) -n default

# in ambient mode
#kubectl create namespace bookinfo --dry-run=client -o yaml | kubectl apply -f -
#kubectl label namespace bookinfo istio.io/dataplane-mode=ambient --overwrite=true
#kubectl apply -f $COMMON_SCRIPTS/bookinfo/bookinfo.yaml -n bookinfo

# in ambient mode 
# curl httpbin.httpbin:8000/status/200
kubectl create namespace httpbin --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace httpbin  istio.io/dataplane-mode=ambient --overwrite=true
kubectl apply -f $COMMON_SCRIPTS/httpbin/httpbin.yaml -n httpbin

# in sidecar mode
# curl helloworld.helloworld:5000/hello
kubectl create namespace helloworld --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace helloworld istio-injection=enabled --overwrite=true
kubectl apply -f $COMMON_SCRIPTS/helloworld/helloworld.yaml -n helloworld

# curl in ambient
# kubectl run netshoot -n httpbin --image=nicolaka/netshoot -i --tty --rm

# curl in sidecar 
# kubectl run netshoot -n helloworld --image=nicolaka/netshoot -i --tty --rm