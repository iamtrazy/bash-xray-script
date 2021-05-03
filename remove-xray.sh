#!/bin/sh
#Remove old certificates
rm -rf /etc/xray
#remove acme.sh
acme.sh --uninstall
rm -rf ~/.acme.sh
#remove json configs
rm -rf  /usr/local/etc/xray
#remove xray-core
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove
