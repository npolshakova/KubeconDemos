# Enable IP forwarding (if not already enabled)
sudo sysctl net.ipv4.ip_forward=1

# Define the pod CIDR and node IP
POD_CIDR="10.244.0.0/16"
NODE_IP="172.18.0.2"

# Get the name of the Docker bridge device
BRIDGE_DEVICE=$(ip link | grep "br-" | awk -F: '{print $2}' | tr -d ' ')

# Add a route for the pod CIDR
sudo ip route add $POD_CIDR via $NODE_IP dev $BRIDGE_DEVICE

# Define the service CIDR
SERVICE_CIDR="10.0.0.0/8"

# Add a route for the service CIDR
sudo ip route add $SERVICE_CIDR via $NODE_IP dev $BRIDGE_DEVICE

# Print the added routes for confirmation
echo "Routes added:"
ip route | grep "$POD_CIDR\|$SERVICE_CIDR"

# So linux doesn't drop packets coming from the pi:
iptables -t filter -L FORWARD | grep "10.0.0.0/8"
