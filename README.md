# KubeconDemos

# Requirements 

- [Kind (Kubernetes in Docker)](#kind)
- [Istioctl](#istioctl)
- [Raspberry Pi ARM 64-bit](#pi)

## Kind
[Kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker) is a tool for running local Kubernetes clusters using Docker container “nodes”.  Kind was primarily designed for testing Kubernetes itself, but may be used for local development or CI.

## jq 

``` 
apt-get install jq
```

## Istioctl

First install `istioctl`:

```bash
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.19.0  sh -
```

Remember to export the Istio path:
``` 
export PATH="$PATH:<path-to-istio>"
```

## Rasberry Pi ARM 64-bit

Download Raspberry pi imager: https://www.raspberrypi.com/software/
Select Raspberry pi OS (64-bit) Debian Bullseye with Raspberry Pi Desktop and write to microSD card. Use advanced setup to set hostname, username, password, and enable ssh.
Connect microSD card to pi, complete setup
Test ssh to make sure you can connect with the pi. Find ip address


# Running

Before you get started, clone the repo on the local linux machine and make sure you have `sudo` access.

1. Setup kind and metallb 

```bash
NOMETALBINSTALL=true ./kind-provisioner.sh
```

2. Setup networking

There are two parts to setting up networking, enable the pod and services on the Kind cluster to be reachable from the host running the docker container, and the enable the pi to reach pods and services in the Kind cluster via the linux machine running the cluster. 

### Host machine -> Docker steps:

1. Edit `/etc/sysctl.conf` to enable ip forwarding by uncommenting this line: 
``` 
net.ipv4.ip_forward = 1
```

You can also do this via, but setting it in `/etc/sysctl.conf` will save you the headache of having to set it again: 
``` 
sudo sysctl net.ipv4.ip_forward=1
```

2. Add the following ip route rules to enable the pod/service CIDR to be reachable from the host machine:

Add the routing rule:
``` 
sudo ip route add $SERVICE_POD_CIDR via $NODE_IP dev $BRIDGE_DEVICE
```

You may be able to skip the `dev $BRIDGE_DEVICE` part if only one device is routable to the docker container IP, since linux *should* infer it needs to send packets to it on its own.

Add rule so we don't drop packets coming from the pi: 
```bash
sudo iptables -t filter -A FORWARD -d "$SERVICE_POD_CIDR" -j ACCEPT
```

### Pi -> Cluster 

1. Add routing rule to allow the pi to access the Pods and Service IPs running in the kind cluster: 

```bash
sudo ip route add $SERVICE_POD_CIDR via $CLUSTER_ADDRESS
```

Where the `CLUSTER_ADDRESS` is the address of your host linux machine running the kind cluster. This can be found with `ip addr show` or `ifconfig`.

All of this can also be done using the script:

**Note**: For ztunnel mode, uncomment this line in the setup-network script:
```bash 
ssh $PI_USERNAME@$PI_ADDRESS sudo iptables -t nat -A OUTPUT ! -o lo -p udp -m udp --dport 53 -m owner ! --uid-owner 999 -j DNAT --to-destination $PI_ADDRESS:15053
```
There is a known bug where DNS requests are captured by the ztunnel and not handled correctly. 

```bash
sudo ./setup-network.sh <pi-address>  <pi-username>
```

3. Setup Istio 

```bash
./istio-setup.sh <pi-address> <pi-username>
```

4. Setup example apps (httpbin, helloworld, etc.)

```bash
./example-app-install.sh
```

5. Setup pi 

Copy the setup file over to the pi with `scp`:

```bash
scp pi-setup-sidecar.sh <username>@<pi-addr>:<path-to-script-dir>
```

### Running in sidecar mode

```bash 
./pi-setup-sidecar.sh <istio-ew-svc-internal-address> <opt-path-to-pi-files>
```

### Running in ztunnel mode


```bash 
./pi-setup-ztunnel.sh <istio-ew-svc-internal-address> <opt-path-to-pi-files>
```