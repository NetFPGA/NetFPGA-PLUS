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

nftest_start()   # BARRIER 1

# Enable the datasink counters
nftest_regwrite(NFPLUS_NF_DATA_SINK_0_RESET(), 0x1) # reset counters
nftest_regwrite(NFPLUS_NF_DATA_SINK_0_ENABLE(), 0x1)

nftest_barrier() # BARRIER 2

# set parameters
SA = "aa:bb:cc:dd:ee:ff"
nextHopMAC = "dd:55:dd:66:dd:77"
NUM_PKTS = 5
num_ports = 1
pkts = []

print("Sending now: ")
totalPktLengths = [0,0]
# send NUM_PKTS from ports nf2c0...nf2c1
for i in range(NUM_PKTS):
    DA = "00:ca:fe:00:00:00"
    pkt = Ether()/'012345678901234567890123456789012345678901234567890123456789'
    pkt.time = ((i*(1e-8)) + (2e-7)) 
    pkts.append(pkt)

nftest_send_dma('nf0', pkts) 

print("")

nftest_barrier()  # BARRIER 3

# sample the counters registers
nftest_regwrite(NFPLUS_NF_DATA_SINK_0_ENABLE(), 0x3)

nftest_regread_expect(NFPLUS_NF_DATA_SINK_0_ENABLE(), 0x503) # 5 pkts. active. enabled.
nftest_regread_expect(NFPLUS_NF_DATA_SINK_0_BYTESINLO(), 0x140)
nftest_regread_expect(NFPLUS_NF_DATA_SINK_0_BYTESINHI(), 0x0)
time_clocks = nftest_regread_expect(NFPLUS_NF_DATA_SINK_0_TIME(), 0x2)
print(f"Number of clocks sampled is {time_clocks}.")

# Disable collection and reset counters and state.
nftest_regwrite(NFPLUS_NF_DATA_SINK_0_ENABLE(), 0x0)
# Enable collection
nftest_regwrite(NFPLUS_NF_DATA_SINK_0_ENABLE(), 0x1)

nftest_barrier()  # BARRIER 4

pkts = []
pkt = Ether()/('012345678901234567890123456789012345678901234567890123456789'*20)
pkt.time = ((1e-8) + (2e-7)) 
pkts.append(pkt)

nftest_send_dma('nf0', pkts) 

nftest_barrier()  # BARRIER 5

nftest_regread_expect(NFPLUS_NF_DATA_SINK_0_ENABLE(), 0x1)
nftest_regread_expect(NFPLUS_NF_DATA_SINK_0_ENABLE(), 0x1)

# sample the counters registers
nftest_regwrite(NFPLUS_NF_DATA_SINK_0_ENABLE(), 0x3)

nftest_regread_expect(NFPLUS_NF_DATA_SINK_0_ENABLE(), 0x503) # 5 pkts. active. enabled.
nftest_regread_expect(NFPLUS_NF_DATA_SINK_0_BYTESINLO(), 0x40)
nftest_regread_expect(NFPLUS_NF_DATA_SINK_0_BYTESINHI(), 0x0)
time_clocks = nftest_regread_expect(NFPLUS_NF_DATA_SINK_0_TIME(), 0x0)
print(f"Number of clocks sampled is {time_clocks}.")

mres=[]

nftest_finish(mres) # BARRIER FINAL
