#!/usr/bin/env python3
#
# Copyright (c) 2015 University of Cambridge
# Copyright (c) 2015 Neelakandan Manihatty Bojan, Georgina Kalogeridou, Salvator Galea
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory 
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
# as part of the DARPA MRC research programme,
# and by the University of Cambridge Computer Laboratory under EPSRC EARL Project
# EP/P025374/1 alongside support from Xilinx Inc.
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@
#
# Author:
#        Modified by Neelakandan Manihatty Bojan, Georgina Kalogeridou

import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from NFTest import *
from RegressRouterLib import *
import sys
import os
import random
from scapy.layers.all import Ether, IP, TCP
from reg_defines_reference_router import *

phy2loop0 = ('../connections/conn', [])
nftest_init(sim_loop = [], hw_config = [phy2loop0])
nftest_start()
mres=[]

if isHW():
	# asserting the reset_counter to 1 for clearing the registers
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_RESET(), 0x1)
	nftest_regwrite(NFPLUS_INPUT_ARBITER_0_RESET(), 0x1)
	nftest_regwrite(NFPLUS_OUTPUT_QUEUES_0_RESET(), 0x1)

# Write and read command for the indirect register access
WR_IND_COM		= 0x0001
RD_IND_COM		= 0x0011
NUM_PORTS 		= 2

dest_MACs	= ["00:0a:35:03:00:01", "00:0a:35:03:00:00"]
routerMAC	= ["00:0a:35:03:00:00", "00:0a:35:03:00:01"]
routerIP	= ["192.168.0.40", "192.168.1.40"]

ALLSPFRouters	= "224.0.0.5"

# Clear all tables in a hardware test (not needed in software)
if isHW():
	nftest_invalidate_all_tables()
else:
	simReg.regDelay(3000) # Give enough time to initiliaze all the memories

# Write the mac and IP addresses
for port in range(2):
	nftest_add_dst_ip_filter_entry (port, routerIP[port])
	nftest_set_router_MAC ('nf%d'%port, routerMAC[port])

nftest_add_dst_ip_filter_entry (2, ALLSPFRouters)

# router mac 0
reg0=nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_0_HI(), 0x000a)
reg1=nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_0_LOW(), 0x35030000)
# router mac 1
reg2=nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_1_HI(), 0x000a)
reg3=nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_1_LOW(),  0x35030001)
mres.extend([reg0, reg1, reg2, reg3])
## router mac 2
#nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_2_HI(), 0xca)
#nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_2_LOW(), 0xfe000003)
## router mac 3
#nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_3_HI(), 0xca)
#nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_3_LOW(), 0xfe000004)

# add LPM and ARP entries for each port
for i in range(NUM_PORTS):
	i_plus_1	= i + 1
	subnetIP 	= "192.168." + str(i_plus_1) + ".1"
	subnetMask	= "255.255.255.225"
	nextHopIP	= "192.168.5." + str(i_plus_1)
	outPort		= 1 << (2 * i)
	nextHopMAC	= dest_MACs[i]

	# add an entry in the routing table
	nftest_add_LPM_table_entry(i, subnetIP, subnetMask, nextHopIP, outPort)
	# add and entry in the ARP table
	nftest_add_ARP_table_entry(i, nextHopIP, nextHopMAC)


num = NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_ARP_CAM_DEPTH() - 1
# ARP table
mac_hi	= 0x000a
mac_lo	= [0x35030001, 0x35030000]
router_ip = [0xc0a80501, 0xc0a80502]

for i in range(num):
	#nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS(), int("0x10000000",16) | i)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS(), NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_ARP_CAM_ADDRESS() | i)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND(), RD_IND_COM)
	# ARP MAC
	# |- -INDIRECTREPLY_A_HI 32bit- -INDIRECTREPLY_A_LOW 32bit- -INDIRECTREPLY_B_HI 32bit- -INDIRECTREPLY_B_LOW 32bit- -|
	# |-- 		mac_hi 		-- 		mac_lo 	      -- 	0x0000 		   -- 		IP    --|
	if i < 2:
		reg0 = nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_HI(),	mac_hi)
		reg1 = nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_LOW(), mac_lo[i])
		reg2 = nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_LOW(), router_ip[i]) 
		mres.extend([reg0, reg1, reg2])
	else:
		reg0 = nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_HI(),	0)
		reg1 = nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_LOW(), 0)
		reg2 = nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_LOW(), 0)
		mres.extend([reg0, reg1, reg2])

# Routing table
router_ip 	= [0xc0a80101, 0xc0a80201]
subnet_mask	= [0xffffffe1, 0xffffffe1]
arp_port	= [1, 4]
next_hop_ip	= [0xc0a80501, 0xc0a80502]

for i in range(num):
	#nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS(), int("0x00000000",16) | i)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS(), NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_LPM_TCAM_ADDRESS() | i)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND(), RD_IND_COM)
	# |- -INDIRECTREPLY_A_HI 32bit- -INDIRECTREPLY_A_LOW 32bit- -INDIRECTREPLY_B_HI 32bit- -INDIRECTREPLY_B_LOW 32bit- -|
	# |-- 		IP 		-- 	next_IP 	     -- 	mask 		 -- 	next_port      --|	
	if i < 2:
		reg0 = nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_LOW(),	arp_port[i])
		mres.append(reg0)
	if i < 2:
		# Router IP
		reg0 = nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_HI(), router_ip[i])
		reg1 = nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_LOW(), next_hop_ip[i])
		# Router subnet mask
		reg2 = nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_HI(),	subnet_mask[i])
		mres.extend([reg0, reg1, reg2])
	else:
		# Router IP
		reg0 = nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_HI(), 0)
		reg1 = nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_LOW(), 0)
		# Router subnet mask
		reg2 = nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_HI(),	0xffffffff)
		mres.extend([reg0, reg1, reg2])

# IP filter
num	= NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_DEST_IP_CAM_DEPTH() - 1
filters	= [0xc0a80028, 0xc0a80128, 0xe0000005]

for i in range(num):
	#nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS(), int("0x20000000",16) | i)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS(), NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_DEST_IP_CAM_ADDRESS() | i)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND(), RD_IND_COM)
	# |- -INDIRECTREPLY_A_HI 32bit- -INDIRECTREPLY_A_LOW 32bit- -INDIRECTREPLY_B_HI 32bit- -INDIRECTREPLY_B_LOW 32bit- -|
	# |-- 		0x0000 		-- 		0x0000 	      -- 	0x0000 		   -- 		IP     --|	
	if i < 3:
		reg0 = nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_LOW(), filters[i])
		mres.append(reg0)
	else:
		reg0 = nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_LOW(), 0)
		mres.append(reg0)

nftest_finish(mres)
