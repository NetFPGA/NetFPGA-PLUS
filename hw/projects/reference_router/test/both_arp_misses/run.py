#!/usr/bin/env python3
#
# Copyright (c) 2015 University of Cambridge
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

if isHW():
	# asserting the reset_counter to 1 for clearing the registers
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_RESET(), 0x1)
	nftest_regwrite(NFPLUS_INPUT_ARBITER_0_RESET(), 0x1)
	nftest_regwrite(NFPLUS_OUTPUT_QUEUES_0_RESET(), 0x1)

routerMAC	= ["00:0a:35:03:00:00", "00:0a:35:03:00:01"]
routerIP	= ["192.168.0.40", "192.168.1.40"]

# Clear all tables in a hardware test (not needed in software)
if isHW():
	nftest_invalidate_all_tables()
else:
	simReg.regDelay(2000)

# Write the mac and IP addresses
for port in range(2):
	nftest_add_dst_ip_filter_entry (port, routerIP[port])
	nftest_set_router_MAC ('nf%d'%port, routerMAC[port])

index		= 0
subnetIP	= "192.168.1.0"
subnetMask	= "255.255.255.0"
nextHopIP	= "192.168.1.54"
outPort		= 0x4
nextHopMAC	= "dd:55:dd:66:dd:77"

nftest_add_LPM_table_entry(index, subnetIP, subnetMask, nextHopIP, outPort)

nftest_barrier()

DA		= routerMAC[0]
SA		= "aa:bb:cc:dd:ee:ff"
TTL		= 64
DST_IP		= "192.168.1.1"
#DST_IP = "192.168.5.1"
SRC_IP		= "192.168.0.1"
nextHopMAC	= "dd:55:dd:66:dd:77"
sent_pkts	= []
pkts_num	= 30

print("Sending packets")

for i in range(pkts_num):
	sent_pkt = make_IP_pkt(src_MAC=SA, dst_MAC=DA, dst_IP=DST_IP, src_IP=SRC_IP, pkt_len=random.randint(60,1514))
	if isHW():
		nftest_send_phy('nf0', sent_pkt)
		nftest_expect_dma('nf0', sent_pkt)
	else:
		sent_pkt.time = ((i*(1e-8)) + (2e-6))
		sent_pkts.append(sent_pkt)

if not isHW():
	nftest_send_phy('nf0', sent_pkts)
	nftest_expect_dma('nf0', sent_pkts)
    
nftest_barrier()

if isHW():
	rres1=nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_PKT_SENT_TO_CPU_ARP_MISS_CNTR(), pkts_num)
	mres=[rres1]
else:
	simReg.regDelay(300)
	nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_PKT_SENT_TO_CPU_ARP_MISS_CNTR(), pkts_num)
	mres=[]

nftest_finish(mres)
