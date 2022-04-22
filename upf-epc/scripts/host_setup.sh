#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2019 Intel Corporation

set -e
# TCP port of bess/web monitor
gui_port=8000
bessd_port=10514
metrics_port=8080

# Driver options. Choose any one of the three
#
# "dpdk" set as default
# "af_xdp" uses AF_XDP sockets via DPDK's vdev for pkt I/O. This version is non-zc version. ZC version still needs to be evaluated.
# "af_packet" uses AF_PACKET sockets via DPDK's vdev for pkt I/O.
# "sim" uses Source() modules to simulate traffic generation
mode="dpdk"
#mode="af_xdp"
#mode="af_packet"
#mode="sim"

# Gateway interface(s)
#
# In the order of ("s1u" "sgi")
ifaces=("s1u" "sgi")

# Static IP addresses of gateway interface(s) in cidr format
#
# In the order of (s1u sgi)
ipaddrs=(10.0.28.4/24 10.0.25.4/24)

# MAC addresses of gateway interface(s)
#
# In the order of (s1u sgi)
# macaddrs=(00:15:4d:12:14:f6 00:15:4d:12:14:f7) # agilio
macaddrs=(00:15:4d:12:14:f8 00:15:4d:12:14:f9) # net_nfp_vf
# macaddrs=(3c:fd:fe:9e:78:98 3c:fd:fe:9e:78:99) # intel
# macaddrs=(0c:42:a1:ca:e8:c0 0c:42:a1:ca:e8:c1) # BF

# Static IP addresses of the neighbors of gateway interface(s)
#
# In the order of (n-s1u n-sgi)
nhipaddrs=(10.0.28.5 10.0.25.5)

# Static MAC addresses of the neighbors of gateway interface(s)
#
# In the order of (n-s1u n-sgi)
nhmacaddrs=(22:53:7a:15:58:50 22:53:7a:15:58:50)

# IPv4 route table entries in cidr format per port
#
# In the order of ("{r-s1u}" "{r-sgi}")
routes=("11.1.1.128/25" "0.0.0.0/0")

num_ifaces=${#ifaces[@]}
num_ipaddrs=${#ipaddrs[@]}

# Set up static route and neighbor table entries of the SPGW

function setup_trafficgen_routes_on_host() {
	for ((i = 0; i < num_ipaddrs; i++)); do
		sudo ip neighbor add "${nhipaddrs[$i]}" lladdr "${nhmacaddrs[$i]}" dev "${ifaces[$i % num_ifaces]}"
		routelist=${routes[$i]}
		for route in $routelist; do
			sudo ip route add "$route" via "${nhipaddrs[$i]}" metric 100
		done
	done
}

# Delete previous links, if exists
for ((i = 0; i < num_ifaces; i++)); do
    sudo ip link delete "${ifaces[$i]}" || true
done

# Set up mirror links to communicate with the kernel
#
# These vdev interfaces are used for ARP + ICMP updates.
# ARP/ICMP requests are sent via the vdev interface to the kernel.
# ARP/ICMP responses are captured and relayed out of the dpdk ports.

for ((i = 0; i < num_ifaces; i++)); do
    sudo ip link add "${ifaces[$i]}" type veth peer name "${ifaces[$i]}"-vdev
    sudo ip link set "${ifaces[$i]}" up
    sudo ip link set "${ifaces[$i]}-vdev" up
    sudo ip link set dev "${ifaces[$i]}" address "${macaddrs[$i]}"
done


# Assign IP address(es) of gateway interface(s) within the network namespace

for ((i = 0; i < num_ipaddrs; i++)); do
    sudo ip addr add "${ipaddrs[$i]}" dev "${ifaces[$i % $num_ifaces]}"
done

# Setup trafficgen routes
if [ "$mode" != 'sim' ]; then
	setup_trafficgen_routes_on_host
fi

python3 ../../bess/bin/bessctl run up4
sleep 10

python3 ../../bess/route_control.py -i "${ifaces[@]}" &

../pfcpbin/pfcpiface -config ../../bess/bessctl/conf/upf.json
