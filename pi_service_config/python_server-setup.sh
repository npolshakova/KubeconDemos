#!/bin/bash

if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <pi_addrees>"
    exit 1
fi

PI_ADDRESS="$1"
PI_APP="hello-pi-${PI_ADDRESS}"

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: hello-pi
  namespace: pi-namespace
  labels:
    app: hello-pi
spec:
  ports:
  - port: 9080
    name: http-pi
    targetPort: 9080
  selector:
    app: "${PI_APP}"
EOF

# On the pi side, run: sudo python3 -m http.server 9080
# Test with: curl http://hello-pi.pi-namespace:9080/