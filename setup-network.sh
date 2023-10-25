# Enable IP forwarding (if not already enabled)
sudo sysctl net.ipv4.ip_forward=1

# Define the pod CIDR and node IP
export POD_CIDR="10.244.0.0/16" # change this based on kind config
export NODE_IP="172.18.0.2"

# Get the name of the Docker bridge device
# export BRIDGE_DEVICE=$(ip link | grep "br-" | awk -F: '{print $2}' | tr -d ' ')

# Add a route for the pod CIDR

# Opt 1: add via bridge device explictly (you can skip this part)
# sudo ip route add $POD_CIDR via $NODE_IP dev $BRIDGE_DEVICE

# Opt 2: add just via node ip
sudo ip route add $POD_CIDR via $NODE_IP

# Define the service CIDR
export SERVICE_CIDR="10.0.0.0/8" # change this based on kind config

# Add a route for the service CIDR

# Opt 1: add via bridge device explictly (you can skip this part)
# sudo ip route add $SERVICE_CIDR via $NODE_IP dev $BRIDGE_DEVICE

# Opt 2: add just via node ip
sudo ip route add $SERVICE_CIDR via $NODE_IP

# Print the added routes for confirmation
echo "Routes added:"
ip route | grep "$POD_CIDR\|$SERVICE_CIDR"

# So linux doesn't drop packets coming from the pi:
iptables -t filter -L FORWARD | grep "10.0.0.0/8"
