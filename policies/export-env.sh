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

# COMMON_SCRIPTS contains the directory this file is in.
COMMON_SCRIPTS=$(dirname "${BASH_SOURCE:-$0}")

cat <<EOF > $COMMON_SCRIPTS/helloworld_l7cluster_auth.yaml
# curl helloworld.helloworld:5000/hello -v 
# curl -H "X-Test: istio-is-cool" helloworld.helloworld:5000/hello -v
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: helloworld-l7-access
 namespace: helloworld
spec:
 selector:
   matchLabels:
     app: helloworld
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/pi-namespace/sa/$PI_SERVICE_ACCOUNT_ZTUNNEL"]
   when:
   - key: request.headers[X-Test]
     values: ["istio-is-cool"]
EOF

cat <<EOF > $COMMON_SCRIPTS/l4pi_auth.yaml
# Access policy applied to the ztunnel pod
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: hello-l4-pi
 namespace: ${PI_NAMESPACE}
spec:
 selector:
   matchLabels:
     app: ${PI_APP_ZTUNNEL}
 action: DENY
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep"]
EOF

cat <<EOF > $COMMON_SCRIPTS/l7pi_auth.yaml
# curl -H "X-Test: istio-is-cool" hello-pi.pi-namespace:80
# curl -H "X-Test: istio-is-cool" led-app.pi-namespace:80
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: hello-l7-pi
 namespace: ${PI_NAMESPACE}
spec:
 selector:
   matchLabels:
     app: ${PI_APP_SIDECAR}
 action: DENY
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep"]
   when:
   - key: request.headers[X-Test]
     values: ["istio-is-cool"]
EOF

cat <<EOF > $COMMON_SCRIPTS/l7pi_headers.yaml
# curl httpbin.httpbin:8000/status/200 -v
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin-headers
  namespace: ${PI_NAMESPACE}
spec:
  exportTo: 
  - "*"
  hosts:
  - httpbin
  http:
  - headers:
     response:
      add:
       test: "Hello from Pi!"
    route:
    - destination:
        host: httpbin # httpbin is running in ambient mode
        port:
          number: 8000
EOF

cat <<EOF > $COMMON_SCRIPTS/teapot_faultinject_cluster.yaml
# curl -H "tea-drinker: nina" teapot-pi.pi-namespace:80/switchOne/on
# curl teapot-pi.pi-namespace:80/switchOne/on
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: teapot-app-fault-injection
  namespace: ${PI_NAMESPACE}
spec:
  exportTo: 
  - "*"
  hosts:
  - teapot-pi
  http:
  - match:
    - headers:
        tea-drinker:
          exact: nina
    headers:
     response:
      add:
       test: "I'm a teapot!"
    fault:
     abort:
        httpStatus: 418
        percentage:
          value: 100
    route:
    - destination:
        host: teapot-pi
        port:
          number: 80
EOF