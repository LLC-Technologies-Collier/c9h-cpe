#!/bin/bash

# Copyright 2025 Collier Technologies LLC

set +x
umask 077

date

IP_NUM=2

echo " == Installing c9h wireguard client == "

mkdir -p /etc/wireguard

echo -n "installing debian packages..."
apt-get install -yq wireguard > /dev/null 2>&1
echo "done"

[[ -f /etc/wireguard/wireguard.ini ]] || {

  echo "generating /etc/wireguard/wireguard.ini for use with c9h"
  cat << EOF > /etc/wireguard/wireguard.ini
[Interface]
PrivateKey = $(wg genkey | tee /etc/wireguard.key)
ListenPort = 51820

[Peer]
PublicKey = 4VOqItLQYl2P0D/ljir5td7qtJZDttY0QUaNuAHEXD4=
Endpoint = 74.120.12.135:51820
AllowedIPs = 100.65.12.0/24, 23.181.112.0/24, 44.32.94.0/23, 2602:fc6d::0/40, 10.65.42.1/32
EOF

  echo "extracting pubkey from private key"
  wg pubkey < /etc/wireguard.key > /etc/wireguard.pub

  cp "$0" /etc/wireguard/c9h-wireguard.sh
  perl -i."${IP_NUM}" -p -e 's/IP_NUM=(\d+)\b/"IP_NUM=" . ($1+1)/e' /etc/wireguard/c9h-wireguard.sh 2>/dev/null
  chmod u+x /etc/wireguard/c9h-wireguard.sh

  umask 0022
  echo "generating /etc/network/interfaces entry"
  cat << "EOF" >> /etc/network/interfaces
auto wg0
iface wg0 inet manual
  pre-up ip link add dev \${IFACE} type wireguard
  pre-up ip addr add 10.65.42.${IP_NUM}/24 dev \${IFACE}
  pre-up wg setconf \${IFACE} /etc/wireguard/wireguard.ini
  up ip link set up dev \${IFACE}
  post-up ip route add 100.65.12.0/24 dev \${IFACE}
  post-up ip route add 23.181.112.0/24 dev \${IFACE}
  post-up ip route add 44.32.94.0/23 dev \${IFACE}
  post-up ip route add 2602:fc6d::0/40 dev ${IFACE}
  down ip link del dev \${IFACE}
EOF
}

printf "Configuration written.\n\n\n"

printf "return the following to Collier Technologies LLC:\n\n10.65.42.${IP_NUM}: "

cat /etc/wireguard.pub

printf "\n\n\n"

echo "to deploy to another host, 'scp /etc/wireguard/c9h-wireguard.sh \$hostname:/tmp'"
echo "and execute /tmp/c9h-wireguard.sh on new host"
