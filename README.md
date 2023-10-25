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

```bash
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.19.0  sh -
```

## Rasberry Pi ARM 64-bit

Download Raspberry pi imager: https://www.raspberrypi.com/software/
Select Raspberry pi OS (64-bit) Debian Bullseye with Raspberry Pi Desktop and write to microSD card. Use advanced setup to set hostname, username, password, and enable ssh.
Connect microSD card to pi, complete setup
Test ssh to make sure you can connect with the pi. Find ip address


# Running

1. Setup kind and metallb 

```bash
./kind-provisioner.sh
```

2. Setup Istio 

```bash
./istio-setup.sh <pi-address>
```

3. Setup example apps (httpbin, helloworld, etc.)
# TODO: ambient or injection mode? If ambient, can install before istio 

```bash
./example-app-install.sh
```

4. Setup pi 

```bash 
./pi-setup <istio-ew-address>
```