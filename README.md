# KubeconDemo: Istio Pi

You want to onboard your Raspberry Pi into your Istio mesh? Well, here ya go:

- [Requirements](#Requirements)
- [Running](#Running)
- [Testing](#Testing)
- [Fancy Testing](#✨-fancy-testing-✨)

# Requirements 

- [Docker](#docker)
- [Kind (Kubernetes in Docker)](#kind)
- [Kubectl](#kubectl)
- [Istioctl](#istioctl)
- [jq](#jq)
- [Raspberry Pi ARM 64-bit](#pi)

## Docker

The scripts (and Kind) require Docker Engine to be installed before getting started. You can follow `these instructions`(https://docs.docker.com/engine/install/ubuntu/) to install docker on linux.

```bash
sudo apt-get install docker-ce docker-ce-cli
```

Verify docker was installed:

```bash
docker version
```

## Kind
[Kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker) is a tool for running local Kubernetes clusters using Docker container “nodes”.  Kind was primarily designed for testing Kubernetes itself, but may be used for local development or CI. You will need the cli tool in order to run the scripts and setup the kind cluster.

Download the latest release with the command (for amd64):

```bash 
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
```

Move `kind` to `/usr/local/bin`: 

```bash
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

Validate `kind` was successfully installed: 

```bash
kind version
```

## Kubectl 

You will need the `kubectl` cli tool in order to run the scripts. You can follow [these instructions](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux) to install `kubectl` on linux.

Download the latest release with the command:

```bash 
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```

Move `kubectl` in `/local/bin`:

```bash 
chmod +x kubectl
mkdir -p ~/.local/bin
mv ./kubectl ~/.local/bin/kubectl
# and then append (or prepend) ~/.local/bin to $PATH
```

Validate `kubectl` was sucessfully installed: 

``` 
kubectl version
```

## Istioctl

In order to run Istio, we need to install [istioctl](https://istio.io/latest/docs/setup/getting-started/). The scripts will use this cli tool in order to install istio on the Kind cluster and onboard the Raspberry Pi into the mesh.

First install `istioctl`:

```bash
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.19.0  sh -
```

Remember to export the Istio path and add it to your bashrc/zshrc file:
``` 
export PATH="$PATH:<path-to-istio>"
```

## jq 

The scripts use [jq](https://manpages.org/jq) to format and parse JASON. Install `jq` with a package manager via: 

```bash 
sudo apt-get install jq
```


## Rasberry Pi ARM 64-bit

1. Download Raspberry pi imager: https://www.raspberrypi.com/software/
2. Select Raspberry pi OS (64-bit) Debian Bookwork with Raspberry Pi Desktop and write to microSD card. Use advanced setup to set hostname, username, password, and enable ssh.
3. Connect microSD card to pi, complete setup on the pi
4. Test ssh to make sure you can connect with the pi. 

If you are unsure of the IP address of the raspberry pi, you can find ip address by scanning what's running on the network via [nmap](https://linux.die.net/man/1/nmap) which you can get with your package-manager with `apt-get install nmap`:

```bash 
nmap -sP 192.168.0.1-255
```

## Building ztunnel on ARM64 

[ztunnel](https://github.com/istio/ztunnel) is the "zero-trust tunnel" that provides L4 policy enforcement in the ambient mesh. 

This repo includes a ztunnel arm64 build (ztunnel_0.0.0-1_arm64.deb) that will run on Raspian Bookworm. The scripts will use this build to run the ztunnel.  

If you wish to build your own ztunnel, clone the repo to where you want to build the ztunnel. There are a couple changes you may need to make to [disable fips](https://github.com/istio/ztunnel#non-fips) before building for the pi. 

```bash 
cargo build --no-default-features
```

# Running

***
KIND CLUSTER SETUP
***

Before you get started, clone the repo on the local linux machine with `git` and make sure you have `sudo` access.

## 1. Setup a kind cluster on the linux machine

```bash
./kind-provisioner.sh
```

## 2. Setup networking

There are two parts to setting up networking, enable the pod and services on the Kind cluster to be reachable from the host running the docker container, and the enable the pi to reach pods and services in the Kind cluster via the linux machine running the cluster. 

### Automatic script

All of the network setup (both on the linux machine and the pi) can be done using the script:

```bash
sudo ./setup-network.sh <pi-address>  <pi-username>
```

### Manual steps

If you want to manually set up the networking and understand what the script is doing, follow these steps:

#### Host machine -> Docker steps:

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

#### Pi -> Cluster 

1. Add routing rule to allow the pi to access the Pods and Service IPs running in the kind cluster: 

```bash
sudo ip route add $SERVICE_POD_CIDR via $CLUSTER_ADDRESS
```

Where the `CLUSTER_ADDRESS` is the address of your host linux machine running the kind cluster. This can be found with `ip addr show` or `ifconfig`.

## 3. Setup Istio 

```bash
./istio-setup.sh <pi-address> <pi-username>
```

## 4. Setup example apps (bookinfo, helloworld, sleep)

Apply some simple applications to the cluster to demonstrate ambient and sidecar modes in the cluster:

```bash
./example-app-install.sh
```

Now we're all done with the setup on the linux side! Before we head over to the pi, we need to grab the kubernetes cluster east-west gateway cluster IP address via: 

```bash 
kubectl get svc -n istio-system
```

Remember, since we are running on a flat network and have exposed our pod/service cidrs from the Kind cluster, we do not need the external IP for the gateway, just the Cluster-IP.

***
RASPBERRY PI SETUP
***

## 5. Setup pi 

Copy the setup file over to the pi with `scp`:

```bash
scp pi-setup-sidecar.sh <username>@<pi-addr>:<path-to-script-dir>
```

Now it's time to ssh into the pi and run the scripts to setup!

### Running in sidecar mode

In order to setup and run the sidecar version, run the following script with `sudo` permissions on the pi:

```bash 
sudo ./pi-setup-sidecar.sh <istio-ew-svc-internal-address> <opt-path-to-pi-files>
```

Where `istio-ew-svc-internal-address` is the Cluster-IP of the east-west gateway service running on the Kind cluster.

### Running in ztunnel mode

In order to setup and run the ztunnel version, run the following script with `sudo` permissions on the pi:

```bash 
sudo ./pi-setup-ztunnel.sh <istio-ew-svc-internal-address> <opt-path-to-pi-files>
```

Where `istio-ew-svc-internal-address` is the Cluster-IP of the east-west gateway service running on the Kind cluster.

**Note** There are some known issues running ztunnel from the home directory. If the script fails with permission errors, create a sub directory and run the ztunnel setup from there. Remember to include the path to the `pi-files` directory in this case.

# Testing 

Now that Istio is running, the Raspberry Pis' are recieving `xDS` (discovery service) updates. [xDS](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/operations/dynamic_configuration) is a group of APIs (endpoint/cluster/route/listener/secret/...) that are used to dynamically configured Envoy (or ztunnel).

You can view the logs of sidecar Istio running in the raspberry pi with: 

```bash  
cat /var/log/istio/istio.log
```

The admin pannel for both sidecar and ztunnel can be viewed on `localhost:15000`. The config dump is found at `localhost:15000/config_dump`. You can view these in a browser if you ssh into the pi with the port forwarding setup via: 

```
ssh -X -L 15000:localhost:15000 <username>@<pi-address>
```

## Pi -> Cluster 

You should now be able to hit services from the raspberry pi via their hostnames: 

```bash 
curl ratings.bookinfo:9080/ratings/1 -v
```

Policies applied to the mesh will also be applied to traffic coming from the pi.

## Cluster -> Pi 

Run a simple python server on the pi on the commandline via: 

```bash
sudo python3 -m http.server 80
```

Create a service for a simple python on the cluster:

```bash 
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: hello-pi
  labels:
    app: hello-pi
spec:
  ports:
  - port: 80
    name: http-pi
    targetPort: 80
  selector:
    app: hello-pi
EOF
```

Make sure your `default` namespace is labeled with either istio injection or for ambient mode. Then run a curl container (such as [netshoot](https://github.com/nicolaka/netshoot)) in the `default` namespace to test: 

``` 
kubectl run netshoot  --image=nicolaka/netshoot -i --tty --rm
```

Then send a request from the container: 

``` 
curl hello-pi.pi-namespace:80
```

## Pi -> Pi

Now that your Raspberry Pis are on the mesh, they also now know about applications running on each pi! After following the instructions described in the Cluster -> Pi, section keep the python3 server running, and run this directly from the second pi (the one *not* running the python server):

``` 
curl hello-pi.pi-namespace:80
```

# ✨ Fancy Testing ✨

## LEDs 

As part of our demo, we use NeoPixels and the WS2812b led strip. You can find a great (open source!) wiring guide here on [AdaFruit](https://learn.adafruit.com/neopixels-on-raspberry-pi/overview).

We wrap the WS2812b python library with a simple Flask webserver. To run this server:

```bash 
sudo python3 ./piWebServer/led_strip_rainbow.py 
```

This will run on port `8080` and will be reachable via: 

``` 
http://<raspberry-pi>:8080/switch
```

To apply the Kubernetes service, run: 

``` 
kubectl apply -f pi-service-config/teapot-setup.yaml
```

Then you will be able to curl once Istio is running via:
```bash 
curl led-pi.pi-namespace:8080/switch
```

## MSNSwitch

As part of our demo, we use a [MSNSwitch](https://msnswitch.com/) to control outlets remotely. 

We wrap the MSNSwitch APIs with a simple Flask webserver. To run this server:

```bash 
sudo python3 ./MSNSwitchServer/switch_app.py 
```

This has serveral paths:
``` 
switchOne/on
switchOne/off 
switchOne/toggle
switchTwo/on
switchTwo/off 
switchTwo/toggle
```

This will run on port `80` and will be reachable via: 

``` 
http://<raspberry-pi>:80/switchTwo/on
```

To apply the Kubernetes service, run: 

``` 
kubectl apply -f pi-service-config/teapot-setup.yaml
```

Then you will be able to curl once Istio is running via:
```bash 
curl teapot-pi.pi-namespace:80/switchTwo/on
```

## Resources 

- [Istio Virtual Machine Onboarding Guide](https://istio.io/latest/docs/setup/install/virtual-machine/)
- [Getting Started with Ambient Mesh](https://istio.io/latest/docs/ops/ambient/getting-started/)