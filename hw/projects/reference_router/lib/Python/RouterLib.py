#!/usr/bin/env python3
#
# Copyright (c) 2015 University of Cambridge
# Copyright (c) Salvator Galea
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

import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from NFTest import *
from NFTest.hwRegLib import regread
import NFTest.simReg

import sys
import os

import re

import socket
import struct

from ctypes import *
from reg_defines_reference_router import *

# Number of entries in each table (default=32)
LPM_LUT_ROWS = NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_LPM_TCAM_DEPTH()
ARP_LUT_ROWS = NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_ARP_CAM_DEPTH()
FILTER_ROWS  = NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_DEST_IP_CAM_DEPTH()

# Check the reg_defines_reference_router.py 
# for the address space of these memories
# LPM_TABLE 	= int("0",16)<<28
# ARP_TABLE 	= int("1",16)<<28
# FILTER_TABLE 	= int("2",16)<<28
LPM_TABLE 	= NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_LPM_TCAM_ADDRESS()
ARP_TABLE 	= NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_ARP_CAM_ADDRESS()
FILTER_TABLE 	= NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_DEST_IP_CAM_ADDRESS()

# Write and read command for the indirect register access
WR_IND_COM		= 0x0001
RD_IND_COM		= 0x0011

################################################################
#
# Setting and getting the router MAC addresses
#
################################################################
def set_router_MAC(port, MAC):
	port = int(port)
	if port < 1 or port > 4:
		print('bad port number')
		sys.exit(1)
	mac = MAC.split(':')
	mac_hi = int(mac[0],16)<<8 | int(mac[1],16)
	mac_lo = int(mac[2],16)<<24 | int(mac[3],16)<<16 | int(mac[4],16)<<8 | int(mac[5],16)

	port -= 1

	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_0_HI() + port * 8, mac_hi)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_0_LOW() + port * 8, mac_lo)

def get_router_MAC(port, MAC):
	port = int(port)
	if port < 1 or port > 4:
		print('bad port number')
	port -= 1
	mac_hi = nftest_regread(NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_0_HI() + port * 8)
	mac_lo = nftest_regread(NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_0_LOW() + port * 8)
	mac_tmp = "%04x%08x"%(mac_hi, mac_lo)
	grp_mac = re.search("^(..)(..)(..)(..)(..)(..)$", mac_tmp).groups()
	str_mac = ''
	for octet in grp_mac:
		str_mac += grp_mac + ":"
	str_mac.rstrip(':')
	return str_mac

################################################################
#
# LPM table stuff
#
################################################################
def add_LPM_table_entry(index, IP, mask, next_IP, next_port):
	if index < 0 or index > LPM_LUT_ROWS - 1 or next_port < 0 or next_port > 255:
		print('Bad data')
		sys.exit(1)
	if re.match("(\d+)\.", IP):
		IP = dotted(IP)
	if re.match("(\d+)\.", mask):
		mask = dotted(mask)
	if re.match("(\d+)\.", next_IP):
		next_IP = dotted(next_IP)

	# Configuration for the Register Table (write data)
	# |-- 						INDIRECTWRDATA 128bit							--|
	# |- -INDIRECTWRDATA_A_HI 32bit- -INDIRECTWRDATA_A_LOW 32bit- -INDIRECTWRDATA_B_HI 32bit- -INDIRECTWRDATA_B_LOW 32bit-	 -|
	# |-- 		IP 		-- 	next_IP 	     -- 	mask 		 -- 	next_port 	      	--|	
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI(),	IP)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_HI(),	mask)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW(),	next_IP)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW(),	next_port)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS(),	LPM_TABLE | index)	# Address of the table + index
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND(),	WR_IND_COM)	# Configure command - WRITE

def invalidate_LPM_table_entry(index):
	if index < 0 or index > LPM_LUT_ROWS-1:
		print('Bad data')
		sys.exit(1)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI(),	0)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_HI(),	0xffffffff)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW(),	0)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW(),	0)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS(),	LPM_TABLE | index)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND(),	WR_IND_COM)

def invalidate_LPM_table():
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_RESET(),0x0200)		# Configure lpm_table reset
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND(), WR_IND_COM)# Configure command - WRITE

def get_LPM_table_entry(index):
	if index < 0 or index > LPM_LUT_ROWS - 1:
		print('get_LPM_table_entry_generic: Bad data')
		sys.exit(1)

	# Configuration for the Register Table (read data)
	# |-- 						INDIRECTREPLY 128bit						  --|
	# |- -INDIRECTREPLY_A_HI 32bit- -INDIRECTREPLY_A_LOW 32bit- -INDIRECTREPLY_B_HI 32bit- -INDIRECTREPLY_B_LOW 32bit- -|
	# |-- 		IP 		-- 	next_IP 	     -- 	mask 		 -- 	next_port 	  --|	
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS(),	LPM_TABLE | index)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND(),	RD_IND_COM)	
	IP 		= nftest_regread(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_HI())
	mask 		= nftest_regread(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_HI())
	next_hop	= nftest_regread(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_LOW())
	output_port	= nftest_regread(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_LOW())

	ip_str = socket.inet_ntoa(struct.pack('!L', IP))
	mask_str = socket.inet_ntoa(struct.pack('!L', mask))
	next_hop_str = socket.inet_ntoa(struct.pack('!L', next_hop))
	return ip_str + '-' + mask_str + '-' + next_hop_str + "-0x%02x"%output_port

################################################################
#
# Destination IP filter table stuff
#
################################################################
def add_dst_ip_filter_entry(index, IP):
	if index < 0 or index > FILTER_ROWS - 1:
		print('Bad data')
		sys.exit(1)
	if re.match("(\d+)\.", IP):
		IP = dotted(IP)
	# Configuration for the Register Table (write data)
	# |-- 						INDIRECTWRDATA 128bit						      --|
	# |- -INDIRECTWRDATA_A_HI 32bit- -INDIRECTWRDATA_A_LOW 32bit- -INDIRECTWRDATA_B_HI 32bit- -INDIRECTWRDATA_B_LOW 32bit- -|
	# |-- 		0x0000 		-- 		0x0000 	      -- 	0x0000 		   -- 		IP 	      --|	
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW(),	IP)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS(),	FILTER_TABLE | index)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND(),	WR_IND_COM)

def invalidate_dst_ip_filter_entry(index):
	if index < 0 or index > FILTER_ROWS-1:
		print('Bad data')
		sys.exit(1)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW(), 0)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS(), FILTER_TABLE | index)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND(), WR_IND_COM)

def invalidate_dst_ip_filter_table():
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_RESET(), 0x0800) 		# Configure dst_ip_filter reset
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND(), WR_IND_COM)# Configure command - WRITE	

def get_dst_ip_filter_entry(index):
	if index < 0 or index > FILTER_ROWS-1:
		print('Bad data')
		sys.exit(1)
	# Configuration for the Register Table (read data)
	# |-- 						INDIRECTREPLY 128bit						  --|
	# |- -INDIRECTREPLY_A_HI 32bit- -INDIRECTREPLY_A_LOW 32bit- -INDIRECTREPLY_B_HI 32bit- -INDIRECTREPLY_B_LOW 32bit- -|
	# |-- 		0x0000 		-- 		0x0000 	      -- 	0x0000 		   -- 		IP 	  --|	
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS(), FILTER_TABLE | index)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND(), RD_IND_COM)
	return nftest_regread(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_LOW())


################################################################
#
# ARP stuff
#
################################################################
def add_ARP_table_entry(index, IP, MAC):
	if index < 0 or index > ARP_LUT_ROWS-1:
		print('Bad data')
		sys.exit(1)
	if re.match("(\d+)\.", IP):
		IP = dotted(IP)
	mac = MAC.split(':')
	mac_hi = int(mac[0],16)<<8 | int(mac[1],16)
	mac_lo = int(mac[2],16)<<24 | int(mac[3],16)<<16 | int(mac[4],16)<<8 | int(mac[5],16)

	# Configuration for the Register Table (write data)
	# |-- 						INDIRECTWRDATA 128bit						      --|
	# |- -INDIRECTWRDATA_A_HI 32bit- -INDIRECTWRDATA_A_LOW 32bit- -INDIRECTWRDATA_B_HI 32bit- -INDIRECTWRDATA_B_LOW 32bit- -|
	# |-- 		mac_hi 		-- 		mac_lo 	      -- 	0x0000 		   -- 		IP 	      --|
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW(),	IP)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI(),	mac_hi)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW(),	mac_lo)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS(),	ARP_TABLE | index)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND(),	WR_IND_COM)

def invalidate_ARP_table_entry(index):
	if index < 0 or index > ARP_LUT_ROWS-1:
		print('Bad data')
		sys.exit(1)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW(),	0)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI(),	0)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW(),	0)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS(), ARP_TABLE | index)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND(), WR_IND_COM)

def invalidate_ARP_table():
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_RESET(),0x0400) 		# Configure arp_table reset
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND(), WR_IND_COM)# Configure command - WRITE	


def get_ARP_table_entry(index):
	if index < 0 or index > ARP_LUT_ROWS-1:
		print('check_ARP_table_entry: Bad data')
		sys.exit(1)

	# -- Configuration for the Register Table (read data)
	# |-- 						INDIRECTREPLY 128bit						  --|
	# |- -INDIRECTREPLY_A_HI 32bit- -INDIRECTREPLY_A_LOW 32bit- -INDIRECTREPLY_B_HI 32bit- -INDIRECTREPLY_B_LOW 32bit- -|
	# |-- 		mac_hi 		-- 		mac_lo 	      -- 	0x0000 		   -- 		IP 	  --|
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS(), ARP_TABLE | index)
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND(), RD_IND_COM)
	IP = nftest_regread(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_LOW())
	mac_hi = nftest_regread(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_HI())
	mac_lo = nftest_regread(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_LOW())

	IP_str = socket.inet_ntoa(struct.pack('!L', IP))
	mac_tmp = "%04x%08x"%(mac_hi, mac_lo)
	grp_mac = re.search("^(..)(..)(..)(..)(..)(..)$", mac_tmp).groups()
	str_mac = ''
	for octet in grp_mac:
		str_mac += octet + ":"
	str_mac = str_mac.rstrip(':')
	return IP_str + '-' + str_mac


################################################################
#
# Misc routines
#
################################################################
def dotted(strIP):
	octet = strIP.split('.')
	newip = int(octet[0])<<24 | int(octet[1])<<16 | int(octet[2])<<8 | int(octet[3])
	return newip


def invalidate_all_tables():
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_RESET(), 0x0e00) 	# Configure reset in all tables
	nftest_regwrite(NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND(), 0x1)# Configure command - WRITE	







