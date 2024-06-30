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
from scapy.layers.all import Ether, IP, TCP
from reg_defines_reference_dma import *

phy2loop0 = ('../connections/conn', [])
nftest_init(sim_loop = [], hw_config = [phy2loop0])

if isHW():
   # reset_counters (triggered by Write only event) for all the modules 
   nftest_regwrite(NFPLUS_INPUT_ARBITER_0_RESET(), 0x1)
   nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_RESET(), 0x101)
   nftest_regwrite(NFPLUS_OUTPUT_QUEUES_0_RESET(), 0x1)

   # Reset the switch table lookup counters (value is reset every time is read)
   nftest_regread(NFPLUS_OUTPUT_PORT_LOOKUP_0_LUTHIT())
   nftest_regread(NFPLUS_OUTPUT_PORT_LOOKUP_0_LUTMISS())

nftest_start()


routerMAC = []
routerIP = []
for i in range(2):
    routerMAC.append("00:0a:35:03:00:0%d"%(i+1))
    routerIP.append("192.168.%s.40"%i)

num_broadcast = 20

pkts = []
for i in range(num_broadcast):
    pkt = make_IP_pkt(src_MAC="aa:bb:cc:dd:ee:ff", dst_MAC=routerMAC[0],
                      EtherType=0x800, src_IP="192.168.0.1",
                      dst_IP="192.168.1.1", pkt_len=60)

    pkt.time = ((i*(1e-8)) + (2e-6))
    pkts.append(pkt)
    if isHW():
        nftest_expect_phy('nf1', pkt)
        nftest_send_phy('nf0', pkt)
    
if not isHW():
    nftest_send_phy('nf0', pkts)
    nftest_expect_phy('nf1', pkts)

nftest_barrier()

if isHW():
    # Expecting the LUT_MISS counter to be incremented by 0x14, 20 packets
    rres1=nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_LUTMISS(), num_broadcast)
    rres2=nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_LUTHIT(), 0)
    mres=[rres1,rres2]
else:
    nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_LUTMISS(), num_broadcast) # lut_miss
    nftest_regread_expect(NFPLUS_OUTPUT_PORT_LOOKUP_0_LUTHIT(), 0) # lut_hit
    mres=[]

nftest_finish(mres)
