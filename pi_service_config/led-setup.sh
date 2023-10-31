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
  name: led-pi
  namespace: pi-namespace
  labels:
    app: led-pi
spec:
  ports:
  - port: 8080
    name: http-pi
    targetPort: 8080
  selector:
    app: hello-pi 
EOF

# On the pi side, run: sudo python3 ./pi_led_server/led_strip_rainbow.py
# Test with: curl http://led-pi.pi-namespace:8080/switch