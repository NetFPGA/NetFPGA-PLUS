#!/usr/bin/env python3

#
# Copyright (c) 2015 University of Cambridge
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

from . import hwPktLib
from .hwPktLib import scapy
from . import hwRegLib
from . import simLib
from . import simReg
from . import simPkt
import sys
import os

script_dir = os.path.dirname( sys.argv[0] )
# Add path *relative to this script's location* of axitools module
sys.path.append( os.path.join( script_dir, '..','..','..','..','tools','scripts' ) )
# Add project test folder
test_path = os.environ['NF_DESIGN_DIR']
hwlog_path = os.path.join(test_path,'test','hwreg.log')


# NB: axitools import must preceed any scapy imports
import axitools

sim = True # default, pass an argument if hardware is needed
iface_map = {} # key is interface specified by test, value is physical interface to use
connections = {} # key is an interface specified by test, value is connected interface specified by test

ifaceArray = []

sent_phy = {}
sent_dma = {}
expected_phy = {}
expected_dma = {}

CPCI_Control_reg = 0x08
CPCI_Interrupt_Mask = 0x40

############################
# Function: nftest_init
# Keyword Arguments: sim_loop - list of interfaces to put into loopback for simulation tests
#                               all 4 ports are automatically initialized for simulation
#                    hw_config - list of valid hardware configurations for hardware tests
#                                configurations are formatted ('path/to/conn/file', ['looped', 'ifaces'])
# Description: parses the configurations to find a valid configuration
#              populates iface_map and connections dictionaries
############################
def nftest_init(sim_loop = [], hw_config=None):
    global sim
    global ifaceArray
    global connections
    global sent_phy, sent_dma, expected_phy, expected_dma
    
    # handle simulation separately
    if not isHW():
        sim = True
        simLib.init()
        ifaceArray = ['nf0', 'nf1']
        for iface in ifaceArray:
            connections[iface] = 'phy_dummy'
            sent_phy[iface] = []
            sent_dma[iface] = []
            expected_phy[iface] = []
            expected_dma[iface] = []

        looped = [False, False, False, False]
        for iface in sim_loop:
            if not iface.startswith('nf'):
                print("Error1: Only nfX interfaces can be put in loopback")
                sys.exit(1)
            else:
                looped[int(iface[2])] = True
        portcfgfile = 'portconfig.sim'
        portcfg = open(portcfgfile, 'w')
        portcfg.write('LOOPBACK=')
        for loop_state in reversed(looped):
            if loop_state:
                portcfg.write('1')
            else:
                portcfg.write('0')
        portcfg.close()
        return 'sim'

    # running a hardware test, check connections
    else:
        ifaceTuple = ('nf0', 'nf1')
        if hw_config is None:
            print("Error: trying to run hardware test without specifying hardware configurations.  Verify the keyword argument hw_config is being used in nftest_init")
            sys.exit(1)
        sim = False
	
        # validate connections and process loopback
        portConfig = 0
        if '--conn' in sys.argv:
            specified_connections = {}
            # read specified connections
            fp = open(sys.argv[sys.argv.index('--conn')+1], 'r')
            for lineNum, tmp_line in enumerate(fp):
                if tmp_line.startswith(ifaceTuple):		
                    break
            fp.close()

	    # lines = open(sys.argv[sys.argv.index('--conn')+1], 'r').readlines()[29:]
            lines = open(sys.argv[sys.argv.index('--conn')+1], 'r').readlines()[lineNum:] 	
            for line in lines:
                conn = line.strip().split(':')
                specified_connections[conn[0]] = conn[1]

            # find matching configuration
            for portConfig in range(len(hw_config)):
                conns = {}
		# lines = open(hw_config[portConfig][0]).readlines()[29:]
                lines = open(hw_config[portConfig][0]).readlines()[lineNum:]
                for line in lines:
                    conn = line.strip().split(':')
                    conns[conn[0]] = conn[1]
                # physical connections match
                if conns == specified_connections:
                    connections = specified_connections
                    # check if we've got disconnected interfaces
                    for connection in connections:
                        if connections[connection] == '':
                            hwRegLib.phy_isolate(iface)
                    # specify loopback
                    for iface in hw_config[portConfig][1]:
                        if iface.startswith('nf'):
                            hwRegLib.phy_loopback(iface)
                        else:
                            print("Error2: Only nfX interfaces can be put in loopback")
                            sys.exit(1)
                    break
                # incompatible configuration
                elif portConfig == len(hw_config) - 1:
                    print("Specified connections file incompatible with this test.")
                    sys.exit(1)

        else:
            portConfig = 0
            # use the first valid_conn_file if not specified
            #lines = open(hw_config[0][0], 'r').readlines()[29:]
            fp = open(hw_config[0][0], 'r')
            for lineNum, tmp_line in enumerate(fp):
                if tmp_line.startswith(ifaceTuple):		
                    break
            fp.close()

            lines = open(hw_config[0][0], 'r').readlines()[lineNum:]    
            for line in lines:
                conn = line.strip().split(':')
                connections[conn[0]] = conn[1]
            # specify loopback

            if len(hw_config[0][1]) > 0:
                for iface in hw_config[0][1]:
                    if iface.startswith('nf'):
                        if isHW():
                            hwRegLib.phy_loopback(iface)
                        else:
                            looped[int(iface[2])] = True
                    else:
                        print("Error3: Only nfX interfaces can be put in loopback")
                        sys.exit(1)

        # avoid duplicating interfaces
        ifaces = list(set(list(connections.keys()) + list(connections.values()) + list(hw_config[portConfig][1])) - set(['']))

        global iface_map
        # populate iface_map
        if '--map' in sys.argv:
            fp = open(sys.argv[sys.argv.index('--map')+1], 'r')
            for lineNum, tmp_line in enumerate(fp):
                if tmp_line.startswith(ifaceTuple):		
                    break
            fp.close()

            mapfile = open(sys.argv[sys.argv.index('--map')+1], 'r')
            lines = mapfile.readlines()[lineNum:]
            for line in lines:
                mapping = line.strip().split(':')
                iface_map[mapping[0]] = mapping[1]
                if mapping[0] in ifaces:
                    ifaces.remove(mapping[0])
                    ifaces.append(mapping[1])
        else:
            for iface in ifaces:
                iface_map[iface] = iface

        ifaceArray = ifaces

        for iface in ifaces:
            sent_phy[iface] = []
            sent_dma[iface] = []
            expected_phy[iface] = []
            expected_dma[iface] = []

        hwPktLib.init(ifaces)
        # print setup for inspection
        print('Running test using the following physical connections:')
        for connection in list(connections.items()):
            try:
                print(iface_map[connection[0]] + ':' + iface_map[connection[1]])
            except KeyError:
                print(iface_map[connection[0]] + ' initialized but not connected')
        if len(list(hw_config[portConfig][1])) > 0:
            print('Ports in loopback:')
            for iface in list(hw_config[portConfig][1]):
                print(iface_map[iface])
        print('------------------------------------------------------')

        return portConfig

############################
# Function: nftest_start
# Arguments: none
# Description: performs initialization
############################
def nftest_start():
    logfile=open(hwlog_path,'w')
    logfile.write('\
#####################################################################\n\
# This log file is automatically Generated from NetFPGA Hardware Test\n\
# It is a test log for register dump reading, for debug purpose\n\
#####################################################################\n')
    logfile.close()
    if not sim:
        hwPktLib.start()
    nftest_barrier()

############################
# Function: nftest_send_phy
# Arguments: interface name
#            packet to send
# Description: send a packet from the phy
############################
def nftest_send_phy(ifaceName, pkt):
    if connections[ifaceName] == ifaceName:
        print("Error: cannot send on phy of a port in loopback")
        sys.exit(1)
    sent_phy[ifaceName].append(pkt)
    if sim:
        for pkt_s in pkt:
            pkt_s.tuser_sport = 1 << (int(ifaceName[2:3])*2) # physical ports are even-numbered

        for i in range(len(pkt)):
            simPkt.pktSendPHY(int(ifaceName[2:3])+1, pkt)
        f = simLib.fPort(int(ifaceName[2]) + 1)
        axitools.axis_dump( pkt, f, 512, 1e-9 )
    else:
        hwPktLib.send(iface_map[connections[ifaceName]], pkt)

############################
# Function: nftest_send_dma
# Arguments: interface name
#            packet to send
# Description: send a packet from the dma
############################
def nftest_send_dma(ifaceName, pkt):
    sent_dma[ifaceName].append(pkt)
    if sim:
        for pkt_s in pkt:
            pkt_s.tuser_sport = 1 << (int(ifaceName[2:3])%4*2 + 1) # PCI ports are odd-numbered

        for i in range(len(pkt)):
            simPkt.pktSendDMA(int(ifaceName[2:3])+1, pkt)
        f = simLib.fDMA()
        axitools.axis_dump( pkt, f, 512, 1e-9 )
    else:
        hwPktLib.send(iface_map[ifaceName], pkt)

############################
# Function: nftest_expect_phy
# Arguments: interface name
#            packet to expect
#            optional packet mask to ignore parts of packet
# Description: expect a packet on the phy
############################
def nftest_expect_phy(ifaceName, pkt, mask = None):
    expected_phy[ifaceName].append(pkt)
    if sim:
        for i in range(len(pkt)):
            simPkt.pktExpectPHY(int(ifaceName[2:3])+1, pkt, mask)
        f = simLib.fExpectPHY(int(ifaceName[2]) + 1)
        axitools.axis_dump( pkt, f, 512, 1e-9 )
    else:
        hwPktLib.expect(iface_map[connections[ifaceName]], pkt, mask)

############################
# Function: nftest_expect_dma
# Arguments: interface name
#            packet to expect
#            optional packet mask to ignore parts of packet
# Description: expect a packet on dma
############################
def nftest_expect_dma(ifaceName, pkt, mask = None):
    expected_dma[ifaceName].append(pkt)
    if sim:
        for i in range(len(pkt)):
            simPkt.pktExpectDMA(int(ifaceName[2:3])+1, pkt, mask)
        f = simLib.fExpectDMA(int(ifaceName[2]) + 1)
        axitools.axis_dump( pkt, f, 512, 1e-9 )
    else:
        hwPktLib.expect(iface_map[ifaceName], pkt, mask)

############################
# Function: nftest_barrier
# Arguments: none
# Description: pauses execution until expected packets arrive
############################
def nftest_barrier():
    if sim:
        simPkt.barrier()
    else:
        hwPktLib.barrier()

############################
# Function: nftest_finish
# Arguments: none
# Description: (sim) finalizes simulation files
#              (hw) performs finalization, writes pcap files and prints success
############################
def nftest_finish(reg_list):
    total_errors = 0
    nftest_barrier()
    reg_errors = 0
    reg_status = 0
    

    if sim:
        simLib.close()
        return 0
    else:

	# write out the sent/expected pcaps for easy viewing
        if not os.path.isdir("./source_pcaps"):
            os.mkdir("./source_pcaps")
        for iface in ifaceArray:
            if len(sent_phy[iface]) > 0:
                scapy.wrpcap("./source_pcaps/%s_sent_phy.pcap"%iface,
		                 sent_phy[iface])
            if len(sent_dma[iface]) > 0:
                scapy.wrpcap("./source_pcaps/%s_sent_dma.pcap"%iface,
		                 sent_dma[iface])
            if len(expected_phy[iface]) > 0:
                scapy.wrpcap("./source_pcaps/%s_expected_phy.pcap"%iface,
		                 expected_phy[iface])
            if len(expected_dma[iface]) > 0:
                scapy.wrpcap("./source_pcaps/%s_expected_dma.pcap"%iface,
		                 expected_dma[iface])

        total_errors += hwPktLib.finish()
        for i in range(len(reg_list)):
            if(reg_list[i]!=1):
                reg_errors += 1	
        reg_status = reg_read_result(reg_list)
        print('\n'+'*****************')
        print('HW Test results')
        print('*****************')
        if total_errors == 0 and reg_status == 1:
            print('Test status : SUCCESS!')
            sys.exit(0)
        else:
            print('\n'+'Test status : FAIL')
            print('packet_missed errors : '+str(total_errors))
            print('register_read errors : '+str(reg_errors))
            print('Please check '+hwlog_path+' for details')
            sys.exit(1)

############################
# Function: nftest_regread_expect
# Arguments: address to read
#            value expected
# Description: reads the specified address and compares with passed value
#              (hw) returns read data
############################
def nftest_regread_expect(addr, val):
    if sim:
        #nftest_regread(addr)
        simReg.regreadstim(addr)
        simReg.regRead(addr, val)
        return 1
    else:
        read_value = hwRegLib.regread(addr)
        logfile = open (hwlog_path,'a')
        logfile.write('Read register address '+format(addr,'#08x')+': expected value -> '+format(val, '#08x')+', read as -> '+format(read_value, '#08x')+' ')
        if (read_value == val):
            logfile.write('<<PASS>>\n')
            logfile.close()
            return 1
        else:
            logfile.write('<<FAIL>>\n')
            logfile.close()
            return 0
#       return hwRegLib.regread_expect(addr, val)

############################
# Function: nftest_regread
# Arguments: address to read
############################
def nftest_regread(addr):
    if sim:
        #simReg.regreadstim(addr)
        return 0
    return hwRegLib.regread(addr)

############################
# Function: regread_result
# Arguments: list containing the status of regread_expect
# Description: returns the status of the regread_expect functionality
#              1 indicates all the regread_expects has passed
#              0 indicates the reg_read_expects has failed
############################
def reg_read_result(nreg_list):
         nreg_status = 1
         for i in range(len(nreg_list)):
                nreg_status &= nreg_list[i]
         return nreg_status


############################
# Function: regwrite
# Arguments: address to write
#            value to write
# Description: writes a value to a register
############################
def nftest_regwrite(addr, val):
    if sim:
        simReg.regWrite(addr, val)
    else:
        hwRegLib.regwrite(addr, val)

############################
# Function: nftest_fpga_reset
# Arguments: none
# Description: resets the fpga
############################
def nftest_fpga_reset():
    if sim:
        simReg.regWrite(simReg.CPCI_REG_CTRL, simReg.CPCI_REG_CTRL_RESET)
    else:
        hwRegLib.fpga_reset()

############################
# Function: isHW
# Arguments: none
# Description: helper for HW specific tasks in tests supporting hw and sim
############################
def isHW():
    if '--hw' in sys.argv:
        return True
    return False
