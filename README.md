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
./kind-provisioner.sh
```

2. Setup networking

**Note**: For ztunnel mode, uncomment this line in the setup-network script:
``` 
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

5. Setup pi (running in sidecar mode)

```bash 
./pi-setup-sidecar <istio-ew-svc-internal-address>
```

5. Setup pi (running in ztunnel mode)

Copy the setup file over to the pi, then run:

```bash 
./pi-setup-ztunnel <istio-ew-svc-internal-address>
```