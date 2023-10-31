#!/bin/bash

# Setup linux networking for kind cluster
kind_setup() {
  echo "Running Kind cluster networking setup"
  
  NODE_IP="172.18.0.2" # change this based on kind config 
  BRIDGE_DEVICE="br-2fd217eb467" # change this based on docker config

  # Enable IP forwarding (if not already enabled)
  sudo sysctl net.ipv4.ip_forward=1

  # Define the pod/service CIDR
  SERVICE_POD_CIDR="10.0.0.0/8" # change this based on kind config

  # Add a route for the pod/service CIDR

  # Opt 1: add via bridge device explictly (you can skip this part)
  # sudo ip route add $SERVICE_POD_CIDR via $NODE_IP dev $BRIDGE_DEVICE

  # Opt 2: add just via node ip without bridge device if there is only one thing routable to the node ip.
  sudo ip route add $SERVICE_POD_CIDR via $NODE_IP

  # Print the added routes for confirmation
  echo "Routes added:"
  ip route | grep "$SERVICE_POD_CIDR"

  sudo iptables -t filter -A FORWARD -d "$SERVICE_POD_CIDR" -j ACCEPT

  # So linux doesn't drop packets coming from the pi:
  iptables -t filter -L FORWARD | grep "$SERVICE_POD_CIDR"
}

# SSH and setup raspberry pi networking
pi_setup() {
  if [ "$run_local_pi" = true ]; then
    echo "Running pi networking setup locally"
    echo "CLUSTER_ADDRESS: $CLUSTER_ADDRESS"
    sudo ip route add $SERVICE_POD_CIDR via $CLUSTER_ADDRESS
  else
    echo "Running pi networking setup via ssh"
    echo "PI_ADDRESS: $PI_ADDRESS"
    echo "PI_USERNAME: $PI_USERNAME"
    echo "CLUSTER_ADDRESS: $CLUSTER_ADDRESS"

    # Fix how ztunnel handles dns queries
    # NOTE: Only set for ztunnel case
    # example: iptables -t nat -A OUTPUT ! -o lo -p udp -m udp --dport 53 -m owner ! --uid-owner 999 -j DNAT --to-destination 192.168.0.58:15053
    # ssh $PI_USERNAME@$PI_ADDRESS sudo iptables -t nat -A OUTPUT ! -o lo -p udp -m udp --dport 53 -m owner ! --uid-owner 999 -j DNAT --to-destination $PI_ADDRESS:15053

    # example: ip route add 10.0.0.0/8 via 192.168.8.168
    ssh $PI_USERNAME@$PI_ADDRESS sudo ip route add $SERVICE_POD_CIDR via $CLUSTER_ADDRESS
  fi 
}

# Check the number of arguments when --all or --pi is used
if [[ ( "$1" == "--all" || "$1" == "--pi" ) ]]; then
  if [ "$2" == "local-pi" ]; then 
    if [ "$#" -ne 3 ]; then
      echo "Usage: $0 --pi local-pi <cluster_address>"
      exit 1
    fi
    run_local_pi=true
  elif [ "$#" -ne 3 ]; then
    echo "Usage: $0 <flag> <pi_address> <pi_username>"
    exit 1
  fi
fi

# Parse command line arguments
case "$1" in
  --all)
    run_all=true
    ;;
  --pi)
    run_pi=true
    ;;
  --kind)
    run_kind=true
    ;;
  *)
    echo "Invalid argument: $1"
    exit 1
    ;;
esac

# Alternative: sudo ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n 1
# Or: ip -j address show dev eth0 | jq -r '.[0].addr_info[0].local' 
CLUSTER_ADDRESS=$(ip route | grep default | awk '{print $9}' | head -n 1)


if [ "$1" == "--all" ] || [ "$1" == "--pi" ]; then
  if [ "$1" == "--all" ] || [ "$2" != "local-pi" ]; then
    # running script via ssh
    PI_ADDRESS="$2"
    PI_USERNAME="$3"
  else
    # running script locally on pi
    PI_ADDRESS=$(ip route | grep default | awk '{print $9}' | head -n 1)
    CLUSTER_ADDRESS="$3"
    PI_USERNAME=""
  fi
fi

# Check which functions to run
if [ "$run_all" = true ]; then
  kind_setup
  pi_setup
elif [ "$run_pi" = true ]; then
  pi_setup
elif [ "$run_kind" = true ]; then
  kind_setup
else
  echo "No valid flags provided. Use --all, --pi, or --kind."
fi
