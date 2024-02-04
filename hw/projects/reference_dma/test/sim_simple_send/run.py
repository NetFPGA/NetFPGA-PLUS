#!/usr/bin/env python3

#
# Copyright (c) 2015 University of Cambridge
# Copyright (c) 2015 Neelakandan Manihatty Bojan, Georgina Kalogeridou
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
import sys
import os
from scapy.layers.all import Ether
from reg_defines_reference_dma import *

conn = ('../connections/conn', [])
nftest_init(sim_loop = ['nf0', 'nf1'], hw_config = [conn])

if isHW():
   # reset_counters (triggered by Write only event) for all the modules 
   nftest_regwrite(NFPLUS_INPUT_ARBITER_0_RESET(), 0x1)
   nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_RESET(), 0x1)
   nftest_regwrite(NFPLUS_OUTPUT_QUEUES_0_RESET(), 0x1)

nftest_start()


# set parameters
SA = "aa:bb:cc:dd:ee:ff"
nextHopMAC = "dd:55:dd:66:dd:77"
if isHW():
    NUM_PKTS = 1454
else:
    NUM_PKTS = 1
num_ports = 1

pkts = []

print("Sending now: ")
totalPktLengths = [0,0]
# send NUM_PKTS from ports nf2c0...nf2c1
for i in range(NUM_PKTS):
    if isHW():
        for port in range(num_ports):
            DA = "00:0a:35:03:00:%02x"%port
            pkt = make_IP_pkt(dst_MAC=DA, src_MAC=SA, dst_IP=DST_IP,
                             src_IP=SRC_IP, TTL=TTL,
                             pkt_len=60+i) 
            totalPktLengths[port] += len(pkt)

            nftest_send_dma('nf' + str(port), pkt)
            nftest_expect_dma('nf' + str(port), pkt)
    else:
        DA = "00:ca:fe:00:00:00"
        pkt = Ether()/'012345678901234567890123456789012345678901234567890123456789'
        pkt.time = ((i*(1e-8)) + (1e-6)) 
        pkts.append(pkt)

if not isHW():  
    # nftest_send_phy('nf0', pkts) 
    # nftest_expect_dma('nf0', pkts) 
    nftest_send_dma('nf0', pkts) 

print("")

nftest_barrier()

if isHW():
    rres1=nftest_regread_expect(NFPLUS_INPUT_ARBITER_0_PKTIN(), NUM_PKTS*num_ports*2)
    rres2=nftest_regread_expect(NFPLUS_INPUT_ARBITER_0_PKTOUT(), NUM_PKTS*num_ports*2)
    rres3=nftest_regread_expect(NFPLUS_OUTPUT_QUEUES_0_PKTSTOREDPORT2(), NUM_PKTS*num_ports)
    rres4=nftest_regread_expect(NFPLUS_OUTPUT_QUEUES_0_PKTREMOVEDPORT2(), NUM_PKTS*num_ports) 
    rres5=nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_PKTIN(), NUM_PKTS*num_ports*2) 
    rres6=nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_PKTOUT(), NUM_PKTS*num_ports*2) 
    mres=[rres1,rres2,rres3,rres4,rres5,rres6]
else:
    nftest_regread_expect(NFPLUS_INPUT_ARBITER_0_PKTIN(), NUM_PKTS)
    nftest_regread_expect(NFPLUS_INPUT_ARBITER_0_PKTOUT(), NUM_PKTS)
    nftest_regread_expect(NFPLUS_OUTPUT_QUEUES_0_PKTSTOREDPORT2(), NUM_PKTS)
    nftest_regread_expect(NFPLUS_OUTPUT_QUEUES_0_PKTREMOVEDPORT2(), NUM_PKTS) 
    nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_PKTIN(), NUM_PKTS) 
    nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_PKTOUT(), NUM_PKTS) 
    mres=[]
