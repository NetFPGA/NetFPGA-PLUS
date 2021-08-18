#!/usr/bin/env python3

#
# Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
#                          Junior University
# Copyright (C) 2011 James Hsi, Eric Lo
# Copyright (c) 2015 Georgina Kalogeridou
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory 
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
# as part of the DARPA MRC research programme.
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

from NFTest import *

from . import simLib
from . import simReg
import os
import sys

script_dir = os.path.dirname( sys.argv[0] )
# Add path *relative to this script's location* of axitools module
sys.path.append( os.path.join( script_dir, '..','..','..','..','tools','scripts' ) )

# NB: axitools import must preceed any scapy imports
import axitools

NUM_PORTS = 2

CMD_SEND = 1
CMD_BARRIER = 2
CMD_DELAY = 3

CMD_BARRIER_REG = 4
CMD_PCI_DELAY = 5

f = []

# Global counters for synchronization
numExpectedPktsPHY = [0, 0, 0, 0]; numExpectedPktsDMA = [0, 0, 0, 0]
numSendPktsPHY = [0, 0, 0, 0]; numSendPktsDMA = [0, 0, 0, 0]

# Packet counters
SentPktsPHYcount = [0, 0, 0, 0]; SentPktsDMAcount = [0, 0, 0, 0]
ExpectedPktsPHYcount = [0, 0, 0, 0]; ExpectedPktsDMAcount = [0, 0, 0, 0]


############################
# Function: pktSendPHY
# Arguments: toPort - the port the packet will be sent to (1-4)
#            pkt - the packet data, class scapy.Packet
#
############################
def pktSendPHY(toPort, pkt):
    numSendPktsPHY[toPort-1] += 1

############################
# Function: pktSendDMA
# Arguments: toPort - the port the packet will be sent to (1-4)
#            pkt - the packet data, class scapy.Packet
#
############################
def pktSendDMA(toPort, pkt):
    numSendPktsDMA[toPort-1] += 1

############################
# Function: pktExpectPHY
# Arguments: atPort - the port the packet will be sent at (1-4)
#            pkt - the packet data, class scapy.Packet
#            mask - mask packet data, class scapy.Packet
#
############################
def pktExpectPHY(atPort, pkt, mask = None):
    numExpectedPktsPHY[atPort-1] += 1
   
############################
# Function: pktExpectDMA
# Arguments: atPort - the port the packet will be expected at (1-4)
#            pkt - the packet data, class scapy.Packet
#            mask - mask packet data, class scapy.Packet
#
############################
def pktExpectDMA(atPort, pkt, mask = None):
    numExpectedPktsDMA[atPort-1] += 1
   
# Synchronization ########################################################

############################
# Function: resetBarrier()
#
#  Private function to be called by pktBarrier
############################
def resetBarrier():
    global numExpectedPktsPHY; global numExpectedPktsDMA; global numSendPktsDMA; global numSendPktsPHY
    numExpectedPktsPHY = [0, 0, 0, 0]
    numExpectedPktsDMA = [0, 0, 0, 0]
    numSendPktsPHY = [0, 0, 0, 0]
    numSendPktsDMA = [0, 0, 0, 0]

############################
# Function: barrier
# Parameters: num - number of packets that must arrive
#   Modifies appropriate files for each port and ingress_dma to denote
#   a barrier request
############################
def barrier():
    for i in range(NUM_PORTS): # 0,1,2,3
        simLib.fPort(i + 1).write("# BARRIER\n")
        simLib.fPort(i + 1).write("B " + "%d\n"%CMD_BARRIER)   
        simLib.fPort(i + 1).write("# EXPECTED\n") 
        simLib.fPort(i + 1).write("N " + "%d\n"%(numExpectedPktsPHY[i]))
        simLib.fPort(i + 1).write("# SENT\n") 
        simLib.fPort(i + 1).write("S " + "%d\n\n"%(numSendPktsPHY[i]))
    simLib.fDMA().write("# BARRIER\n")
    simLib.fDMA().write("B " + "%d\n"%CMD_BARRIER)   
    simLib.fDMA().write("# EXPECTED\n") 
    simLib.fDMA().write("N " + "%d\n"%(numExpectedPktsDMA[0]))
    simLib.fDMA().write("# SENT\n") 
    simLib.fDMA().write("S " + "%d\n\n"%(numSendPktsDMA[0]))
    simLib.fregstim().write("# BARRIER\n")
    simLib.fregstim().write("B " + "%d\n"%CMD_BARRIER_REG)
    for i in range(NUM_PORTS):
        simLib.fregstim().write("# Interface " + "%d\n"%(i)) 
        simLib.fregstim().write("N " + "%d\n"%(numExpectedPktsPHY[i]))
        simLib.fregstim().write("S " + "%d\n"%(numSendPktsPHY[i]))
    simLib.fregstim().write("# DMA\n")
    simLib.fregstim().write("N " + "%d\n"%(numExpectedPktsDMA[i])) 
    simLib.fregstim().write("S " + "%d\n"%(numSendPktsDMA[i]))

    resetBarrier()

MSB_MASK = (0xFFFFFFFF00000000)
LSB_MASK = (0x00000000FFFFFFF)

###########################
# Function: pktDelay
#
###########################
def delay(nanoSeconds):
    for i in range(NUM_PORTS):
        simLib.fPort(i+1).write("%08d"%CMD_DELAY + " // DELAY\n")
        simLib.fPort(i+1).write("%08x"%(MSB_MASK & nanoSeconds) +
                                " // Delay (MSB) " + str(nanoSeconds)+" ns\n")
        simLib.fPort(i+1).write("%08x"%(MSB_MASK & nanoSeconds) +
                                " // Delay (LSB) " + str(nanoSeconds)+" ns\n")

    simLib.fPCI().write("%08d"%CMD_PCI_DELAY+" // DELAY\n")
    simLib.fPCI().write("%08x"%(MSB_MASK & nanoSeconds) + " // Delay (MSB) " +
                        str(nanoSeconds) + " ns\n")
    simLib.fPCI().write("%08x"%(LSB_MASK & nanoSeconds) + " // Delay (LSB) " +
                        str(nanoSeconds) + " ns\n")
