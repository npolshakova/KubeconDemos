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
  name: teapot-pi
  namespace: pi-namespace
  labels:
    app: teapot-pi
spec:
  ports:
  - port: 80
    name: http-pi
    targetPort: 80
  selector:
    app: "${PI_APP}"
EOF

# On the pi side, run sudo python3 ./msn_switch_server/msn_switch_server.py <switch-ip>
# Test with: curl http://teapot-pi.pi-namespace:80/switchOne/toggle