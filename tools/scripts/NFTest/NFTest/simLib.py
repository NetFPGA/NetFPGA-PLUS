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
#
################################################################################
#  Description:
#  	Overarching test module.
#  	Creates and maintains file objects through file writes during tests.
#  	python -m pdb
#

from NFTest import *
import os

NUM_PORTS = 2
NF2_MAX_PORTS = 2
DMA_QUEUES = 2

#instantiation
f_ingress = []
f_expectPHY = []
f_expectDMA = []
f_dma = []
f_regstim = []
f_regexpect = []

# directory = 'packet_data'
dma_stim = 'dma_0_stim.axi'
dma_expect = 'dma_'
ingress_fileHeader = 'nf_interface_' # 'ingress_port_'
expectPHY_fileHeader = 'nf_interface_' # 'expected_port_'
reg_expect = 'reg_expect.axi' 
reg_stim = 'reg_stim.axi'

############################
# Function: init()
#   Creates the hardware and simulation files to be read by ModelSim,
############################
def init():

    global f_dma; global f_regstim; global f_regexpect
    f_dma = open(dma_stim,'w')  
    f_regstim = open(reg_stim, 'w')
    f_regexpect = open(reg_expect, 'w')  

    for i in range(NUM_PORTS):
        filename = ingress_fileHeader + str(i) + "_stim.axi"
        f_ingress.append(open(filename, 'w'))
        
    for i in range(NUM_PORTS):
        filename = expectPHY_fileHeader + str(i) + "_expected.axi"
        f_expectPHY.append(open(filename, 'w'))
  
    for i in range(NUM_PORTS):
        filename = dma_expect + str(i) + "_expected.axi"
        f_expectDMA.append(open(filename, 'w'))
   
############################
# Function: writeFileHeader
#  Writes timestamp and general information to file head.
############################
def writeFileHeader(fp, filePath):
    from time import gmtime, strftime
    fp.write("//File " + filePath + " created " +
                strftime("%a %b %d %H:%M:%S %Y", gmtime())+"\n")
    fp.write("//\n//This is a data file intended to be read in by a " +
                "Verilog simulation.\n//\n")


############################
# Function: writeXMLHeader
#  Writes timestamp and general information to file head.
############################
def writeXMLHeader(fp, filePath):
    from time import gmtime, strftime
    fp.write("<?xml version=\"1.0\" standalone=\"yes\" ?>\n")
    fp.write("<!-- File "+filePath+" created "+
                strftime("%a %b %d %H:%M:%S %Y", gmtime())+" -->\n")
    if str.find(filePath, expectPHY_fileHeader)>0:
        fp.write("<!-- PHYS_PORTS = "+str(NUM_PORTS)+" MAX_PORTS = "+
                    str(NF2_MAX_PORTS)+" -->\n")
        fp.write("<PACKET_STREAM>\n")
    elif str.find(filePath, expectDMA_fileHeader)>0:
        fp.write("<!-- DMA_QUEUES = "+"%d"%DMA_QUEUES+" -->")
        fp.write("<DMA_PACKET_STREAM>\n")
    fp.write("\n")


############################
# Function: close()
#   Closes all file pointers created during initialization.
#   Must be called at the end of every test file.
############################
def close():
    f_dma.close()
    f_regstim.close()
    f_regexpect.close()

    for i in range(NUM_PORTS):
        f_ingress[i].close()

    for i in range(NUM_PORTS):
        f_expectPHY[i].close()

    for i in range(NUM_PORTS):
        f_expectDMA[i].close()

############################
# Function: fregstim(), fregexpect()
#  A Getter that returns the file pointer for file with
#  register read/write info.
############################
def fregstim():
    return f_regstim

def fregexpect():
    return f_regexpect

############################
# Function: fDMA
#  A Getter that returns the file pointer for file with DMA read/write info.
############################
def fDMA():
    return f_dma


############################
# Function: fPort
# Argument: port - int - port for which read/write is occurring
#                   (Should be 1-4, NOT THE INDEX OF ARRAY)
#  A Getter that returns the file pointer for file with PHY read/write info.
#
############################
def fPort(port):
    return f_ingress[port-1] # 0,1,2,3


############################
# Function: fExpectPHY
# Argument: port - int - port for which read/write is occurring
#                   (Should be 1-4, NOT THE INDEX OF ARRAY)
#  A Getter that returns the file pointer for file with PHY read/write info.
#
############################
def fExpectPHY(port):
    return f_expectPHY[port-1]


############################
# Function: fExpectDMA
# Argument: port - int - port for which read/write is occurring
#                   (Should be 1-4, NOT THE INDEX OF ARRAY)
#  A Getter that returns the file pointer for file with DMA read/write info.
#
############################
def fExpectDMA(port):
    return f_expectDMA[port-1]
