#!/bin/bash
# make sure you have the following dependencies installed on the pi 
# sudo apt-get install iptables cmake libclang-dev protobuf-compiler
# find the path to libclang.so and set the LIBCLANG_PATH environment variable (sudo find /usr /lib /lib64 /usr/local -name libclang.so):
# export LIBCLANG_PATH="<path to libclang.so>"

#cargo install cargo-deb

# if cross compiling, check you have the aarch64-unknown-linux-gnu target 
# rustup target add aarch64-unknown-linux-gnu

cargo deb 
# cargo deb --target=aarch64-unknown-linux-gnu

sudo dpkg -i out/rust/debian/ztunnel_0.0.0-1_arm64.deb

# old start script based on istio-start.sh
# sudo sed -i 's/logger -s/echo/g' /usr/local/bin/istio-ambient-start.sh

sudo bash /usr/local/bin/istio-ambient-start.sh ztunnel &
