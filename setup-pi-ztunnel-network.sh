# Get the internal IP address of the PI. You can remove `head -n 1` if only one ip is assigned
# Alternative: ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n 1
PI_ADDRESS=$(ip route | grep default | awk '{print $3}' | head -n 1)

# setup networking rules (if not already setup)
sudo iptables-apply ztunnel-iptables-rules
sudo iptables -t nat -A OUTPUT ! -o lo -p udp -m udp --dport 53 -m owner ! --uid-owner 999 -j DNAT --to-destination $PI_ADDRESS:15053
