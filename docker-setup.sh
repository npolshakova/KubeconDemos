#!/bin/bash

sudo ip route add 10.0.0.0/8 via 172.18.0.2
sudo iptables -t filter -A FORWARD -d 10.0.0.0/8 -j ACCEPT