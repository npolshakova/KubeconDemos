# Provide the pi address and username as an argument
if [ $# -ne 2 ]; then
    echo "Usage: $0 <pi_address> <pi_username>" 
    exit 1
fi

# Store the provided address in a variable
export PI_ADDRESS="$1"
export PI_USERNAME="$2"

# Enable IP forwarding (if not already enabled)
sudo sysctl net.ipv4.ip_forward=1

# Define the pod/service CIDR
export SERVICE_POD_CIDR="10.0.0.0/8" # change this based on kind config

# Add a route for the pod/service CIDR

# Opt 1: add via bridge device explictly (you can skip this part)
# sudo ip route add $SERVICE_CIDR via $NODE_IP dev $BRIDGE_DEVICE

# Opt 2: add just via node ip
sudo ip route add $SERVICE_POD_CIDR via $NODE_IP

# Print the added routes for confirmation
echo "Routes added:"
ip route | grep "$SERVICE_POD_CIDR"

sudo iptables -t filter -A FORWARD -d "$SERVICE_POD_CIDR" -j ACCEPT

# So linux doesn't drop packets coming from the pi:
iptables -t filter -L FORWARD | grep "$SERVICE_POD_CIDR"

# ssh into the pi and setup networking 

# Only set for ztunnel case
# ssh $PI_USERNAME@$PI_ADDRESS sudo iptables -t nat -A OUTPUT ! -o lo -p udp -m udp --dport 53 -m owner ! --uid-owner 999 -j DNAT --to-destination $PI_ADDRESS:15053

# switch to: ip -j address show 
export CLUSTER_ADDRESS=$(sudo ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n 1)
ssh $PI_USERNAME@$PI_ADDRESS sudo ip route add $SERVICE_POD_CIDR via $CLUSTER_ADDRESS