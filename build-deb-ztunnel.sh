#cargo install cargo-deb

cargo deb 

sudo dpkg -i out/rust/debian/ztunnel_0.0.0-1_arm64.deb

sudo sed -i 's/logger -s/echo/g' /usr/local/bin/istio-ambient-start.sh

sudo bash /usr/local/bin/istio-ambient-start.sh ztunnel &