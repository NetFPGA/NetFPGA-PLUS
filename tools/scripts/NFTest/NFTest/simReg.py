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
from . import simPkt

# IOCTL Commands
SIOCREGREAD = 0x89F0
SIOCREGWRITE = 0x89F1

# Register Constants
CPCI_REG_CTRL = 0x008

# Register Values
CPCI_REG_CTRL_RESET = 0x00000100

NUM_PORTS = 4
CMD_READ = 1
CMD_WRITE = 2
CMD_DMA = 3
CMD_BARRIER = 4
CMD_DELAY = 5

NUM_PORTS = 4

############################
# Function: regDMA
# Arguments:
# queue is DMA queue #, length is packet length
############################
def regDMA(queue, length):
    f = simLib.fPCI()
    f.write("// DMA: QUEUE: "+hex(queue)+ " LENGTH: "+hex(length)+"\n")
    f.write("00000003 // DMA\n")
    f.write("%08x"%queue +" // Queue ("+hex(queue)+")\n")
    f.write("%08x"%length+" // Length ("+hex(length)+")\n")
    f.write("00000000"+" // Mask (0x0)\n")

############################
# Function: regRead
# Arguments:
# reg is an address, value is data
############################
def regRead(reg, val):
    f = simLib.fregexpect()
    simLib.fregexpect().write("# READ\n")
    f.write("R " + "%08x\n"%CMD_READ) # // READ
    f.write("%08x, "%reg) # // Address 
    f.write("%08x.\n"%val) # // Data
	
############################
# Frunction: regread 
# Arguments: address
############################
def regreadstim(reg):
    f = simLib.fregstim()
    simLib.fregstim().write("# READ\n")
    f.write("R " + "%08x\n"%CMD_READ) # // READ
    f.write("-, -, -, " + "%08x"%reg + ".\n")

############################
# Function: regWrite
# Arguments:
# reg is an address, value is data
############################
def regWrite(reg, value):
    f = simLib.fregstim()
    f.write("# WRITE\n")
    f.write("W " + "%08x\n"%CMD_WRITE)
    f.write("%08x, "%reg) # // Address
    f.write("%08x, "%value) # // Data 
    f.write("f, -.\n")
    g = simLib.fregexpect()
    g.write("# WRITE\n")
    g.write("W " + "%08x\n"%CMD_WRITE)
    g.write("%08x, "%reg) # // Address
    g.write("%08x, "%value) # // Data 
    g.write("f, -.\n")

# Synchronization ##################################

MSB_MASK = (0xFFFFFFFF00000000)
LSB_MASK = (0x00000000FFFFFFF)

############################
# Function: regDelay
# Parameters: nanoSeconds - time to delay the entire simulation (in ns)
# Writes
############################
def regDelay(nanoSeconds):
    simLib.fregstim().write("# DELAY \n")
    simLib.fregstim().write("D " + "%0d\n"%nanoSeconds)
    simLib.fregstim().write("# DELAY (MSB) " + "%08x, "%(MSB_MASK & nanoSeconds) + str(nanoSeconds) + " ns\n")
    simLib.fregstim().write("# DELAY (LSB) " + "%08x, "%(LSB_MASK & nanoSeconds) + str(nanoSeconds) + " ns\n")

