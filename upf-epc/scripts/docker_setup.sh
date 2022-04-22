#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2019 Intel Corporation

# set -e
# TCP port of bess/web monitor
# gui_port=8000
# bessd_port=10514
# metrics_port=8080

# Driver options. Choose any one of the three
#
# "dpdk" set as default
# "af_xdp" uses AF_XDP sockets via DPDK's vdev for pkt I/O. This version is non-zc version. ZC version still needs to be evaluated.
# "af_packet" uses AF_PACKET sockets via DPDK's vdev for pkt I/O.
# "sim" uses Source() modules to simulate traffic generation
# mode="dpdk"
#mode="af_xdp"
#mode="af_packet"
#mode="sim"

# Gateway interface(s)
#
# In the order of ("s1u" "sgi")
# ifaces=("s1u" "sgi")

# Static IP addresses of gateway interface(s) in cidr format
#
# In the order of (s1u sgi)
# ipaddrs=(10.0.28.4/24 10.0.25.4/24)

# MAC addresses of gateway interface(s)
#
# In the order of (s1u sgi)
# macaddrs=(00:15:4d:12:14:f6 00:15:4d:12:14:f7)

# Static IP addresses of the neighbors of gateway interface(s)
#
# In the order of (n-s1u n-sgi)
# nhipaddrs=(10.0.28.5 10.0.25.5)

# Static MAC addresses of the neighbors of gateway interface(s)
#
# In the order of (n-s1u n-sgi)
# nhmacaddrs=(22:53:7a:15:58:50 22:53:7a:15:58:50)

# IPv4 route table entries in cidr format per port
#
# In the order of ("{r-s1u}" "{r-sgi}")
# routes=("11.1.1.128/25" "0.0.0.0/0")

# num_ifaces=${#ifaces[@]}
# num_ipaddrs=${#ipaddrs[@]}

# # Set up static route and neighbor table entries of the SPGW
# function setup_trafficgen_routes() {
# 	for ((i = 0; i < num_ipaddrs; i++)); do
# 		sudo ip netns exec pause ip neighbor add "${nhipaddrs[$i]}" lladdr "${nhmacaddrs[$i]}" dev "${ifaces[$i % num_ifaces]}"
# 		routelist=${routes[$i]}
# 		for route in $routelist; do
# 			sudo ip netns exec pause ip route add "$route" via "${nhipaddrs[$i]}" metric 100
# 		done
# 	done
# }

# function setup_trafficgen_routes_on_host() {
# 	for ((i = 0; i < num_ipaddrs; i++)); do
# 		sudo ip neighbor add "${nhipaddrs[$i]}" lladdr "${nhmacaddrs[$i]}" dev "${ifaces[$i % num_ifaces]}"
# 		routelist=${routes[$i]}
# 		for route in $routelist; do
# 			sudo ip route add "$route" via "${nhipaddrs[$i]}" metric 100
# 		done
# 	done
# }

# Assign IP address(es) of gateway interface(s) within the network namespace
# function setup_addrs() {
# 	for ((i = 0; i < num_ipaddrs; i++)); do
# 		sudo ip netns exec pause ip addr add "${ipaddrs[$i]}" dev "${ifaces[$i % $num_ifaces]}"
# 	done
# }

# function setup_addrs_on_host() {
# 	for ((i = 0; i < num_ipaddrs; i++)); do
# 		sudo ip addr add "${ipaddrs[$i]}" dev "${ifaces[$i % $num_ifaces]}"
# 	done
# }

# Set up mirror links to communicate with the kernel
#
# These vdev interfaces are used for ARP + ICMP updates.
# ARP/ICMP requests are sent via the vdev interface to the kernel.
# ARP/ICMP responses are captured and relayed out of the dpdk ports.
# function setup_mirror_links() {
# 	for ((i = 0; i < num_ifaces; i++)); do
# 		sudo ip netns exec pause ip link add "${ifaces[$i]}" type veth peer name "${ifaces[$i]}"-vdev
# 		sudo ip netns exec pause ip link set "${ifaces[$i]}" up
# 		sudo ip netns exec pause ip link set "${ifaces[$i]}-vdev" up
# 		sudo ip netns exec pause ip link set dev "${ifaces[$i]}" address "${macaddrs[$i]}"
# 	done
# 	setup_addrs
# }

# function setup_mirror_links_on_host() {
# 	for ((i = 0; i < num_ifaces; i++)); do
# 		sudo ip link add "${ifaces[$i]}" type veth peer name "${ifaces[$i]}"-vdev
# 		sudo ip link set "${ifaces[$i]}" up
# 		sudo ip link set "${ifaces[$i]}-vdev" up
# 		sudo ip link set dev "${ifaces[$i]}" address "${macaddrs[$i]}"
# 	done
# 	setup_addrs_on_host
# }

# Set up interfaces in the network namespace. For non-"dpdk" mode(s)
# function move_ifaces() {
# 	for ((i = 0; i < num_ifaces; i++)); do
# 		sudo ip link set "${ifaces[$i]}" netns pause up
# 		sudo ip netns exec pause ip link set "${ifaces[$i]}" promisc off
# 		sudo ip netns exec pause ip link set "${ifaces[$i]}" xdp off
# 		if [ "$mode" == 'af_xdp' ]; then
# 			sudo ip netns exec pause ethtool --features "${ifaces[$i]}" ntuple off
# 			sudo ip netns exec pause ethtool --features "${ifaces[$i]}" ntuple on
# 			sudo ip netns exec pause ethtool -N "${ifaces[$i]}" flow-type udp4 action 0
# 			sudo ip netns exec pause ethtool -N "${ifaces[$i]}" flow-type tcp4 action 0
# 			sudo ip netns exec pause ethtool -u "${ifaces[$i]}"
# 		fi
# 	done
# 	setup_addrs
# }

# Stop previous instances of bess* before restarting
# docker stop pause bess bess-routectl bess-web bess-pfcpiface || true
# docker rm -f pause bess bess-routectl bess-web bess-pfcpiface || true
# sudo rm -rf /var/run/netns/pause

docker stop bess-web bess-pfcpiface || true
docker rm -f bess-web bess-pfcpiface || true

# Build
make docker-build

# if [ "$mode" == 'dpdk' ]; then
# 	DEVICES=${DEVICES:-'--device=/dev/vfio/91 --device=/dev/vfio/92 --device=/dev/vfio/vfio'}
# 	PRIVS='--cap-add IPC_LOCK --privileged --cap-add=SYS_ADMIN --cap-add=SYS_PTRACE'

# elif [ "$mode" == 'af_xdp' ]; then
# 	PRIVS='--privileged'

# elif [ "$mode" == 'af_packet' ]; then
# 	PRIVS='--cap-add IPC_LOCK'
# fi

# Run pause

	# -p $bessd_port:$bessd_port \
	# -p $gui_port:$gui_port \

# docker run --name pause -td --restart unless-stopped \
# 	--cpuset-cpus=19 \
# 	-p $metrics_port:$metrics_port \
# 	--hostname $(hostname) \
# 	k8s.gcr.io/pause

# Emulate CNI + init container
# sudo mkdir -p /var/run/netns
# sandbox=$(docker inspect --format='{{.NetworkSettings.SandboxKey}}' pause)
# sudo ln -s "$sandbox" /var/run/netns/pause

# case $mode in
# # "dpdk" | "sim") setup_mirror_links ;;
# "dpdk" | "sim") setup_mirror_links_on_host ;;
# "af_xdp" | "af_packet")
# 	move_ifaces
# 	# Make sure that kernel does not send back icmp dest unreachable msg(s)
# 	sudo ip netns exec pause iptables -I OUTPUT -p icmp --icmp-type port-unreachable -j DROP
# 	;;
# *) ;;

# esac

# # Setup trafficgen routes
# if [ "$mode" != 'sim' ]; then
# 	# setup_trafficgen_routes
# 	setup_trafficgen_routes_on_host
# fi

# # Setup cpu pinning
# taskset=0
# if [ "$taskset" == 1 ]; then
# 	TASKSET='taskset -c 19 '
# fi

# # Setup vtune parameters -resume-after=0
# vtune=0
# if [ "$vtune" == 1 ]; then
# 	VTUNE='vtune -c anomaly-detection -duration=60 '
# elif [ "$vtune" == 2 ]; then
# 	VTUNE='vtune -c hotspots -duration=60 '
# elif [ "$vtune" == 3 ]; then
# 	VTUNE='vtune -c threading -duration=60 '
# elif [ "$vtune" == 4 ]; then
# 	VTUNE='vtune -c memory-consumption -duration=60 '
# elif [ "$vtune" == 5 ]; then
# 	VTUNE='vtune -c hpc-performance -duration=60 '
# elif [ "$vtune" == 6 ]; then
# 	VTUNE='vtune -c uarch-exploration -duration=60 '
# elif [ "$vtune" == 7 ]; then
# 	VTUNE='vtune -c memory-access -duration=60 '
# elif [ "$vtune" == 8 ]; then
# 	VTUNE='vtune -c io -duration=60 '
# elif [ "$vtune" == 9 ]; then
# 	VTUNE='vtune -c system-overview -duration=60 '
# fi

# # Below are commands for vtune attach mode, please run them on container
# if [ "$vtune" == xx ]; then
# vtune -c hotspots -knob sampling-mode=hw \
# 	-knob enable-stack-collection=true -knob stack-size=4096 \
# 	-duration=60 -target-process bessd

# vtune -c memory-access -duration=60 -target-process bessd

# vtune -c io -duration=60 -target-process bessd

# vtune -c uarch-exploration -duration=60 -target-process bessd
# fi

# Run bessd
# docker run --name bess -td --restart unless-stopped \
# 	--cpuset-cpus=0-15 \
# 	--ulimit memlock=-1 -v /dev/hugepages:/dev/hugepages \
# 	-v "$PWD/conf":/opt/bess/bessctl/conf \
# 	--net container:pause \
# 	$PRIVS \
# 	$DEVICES \
# 	upf-epc-bess:"$(<VERSION)" -grpc-url=0.0.0.0:$bessd_port

# docker logs bess
# bessd -f -grpc-url=0.0.0.0:10514

# Sleep for a couple of secs before setting up the pipeline
# sleep 40
# docker exec bess ./bessctl run up4
# python3 /opt/bess/bessctl/bessctl run up4
# sleep 10

# Run bess-web
# docker run --name bess-web -d --restart unless-stopped \
# 	--cpuset-cpus=18 \
# 	--net container:bess \
# 	--entrypoint bessctl \
# 	upf-epc-bess:"$(<VERSION)" http 0.0.0.0 $gui_port
# python3 /opt/bess/bessctl/bessctl http 0.0.0.0 $gui_port


	# --net container:pause \

# Run bess-pfcpiface depending on mode type
docker run --name bess-pfcpiface -td --restart on-failure \
	--cpuset-cpus=16 \
	-v "$PWD/conf/upf.json":/conf/upf.json \
	upf-epc-pfcpiface:"$(<VERSION)" \
	-config /conf/upf.json

# Don't run any other container if mode is "sim"
# if [ "$mode" == 'sim' ]; then
# 	exit
# fi

# Run bess-routectl
# docker run --name bess-routectl -td --restart unless-stopped \
# 	--cpuset-cpus=17 \
# 	-v "$PWD/conf/route_control.py":/route_control.py \
# 	--net container:pause --pid container:bess \
# 	--entrypoint /route_control.py \
# 	upf-epc-bess:"$(<VERSION)" -i "${ifaces[@]}"
# python3 /opt/bess/route_control.py -i "${ifaces[@]}"