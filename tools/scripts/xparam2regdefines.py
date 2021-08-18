#!/usr/bin/python3

#
# Copyright (c) 2015 Neelakandan Manihatty Bojan
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
################################################################################
#  Description:
#        This is used to convert xparameters.h to reg_defines.h
#

import re

input_file = open("nf_register_defines.h", "r")
output_file = open("reg_defines.h", "w")
baseaddr = 0
baseaddr_int = 0
highaddr = 0
highaddr_int = 0
sizeaddr = 0
sizeaddr_int = 0
default = 0
default_int = 0
width = 0
width_int = 0 
 
offset_int =0

for line in input_file:
    match_baseaddr = re.match(r'\s*#define .*_BASEADDR (0x[a-zA-Z_0-9]{8})', line)
    match_highaddr = re.match(r'\s*#define .*_HIGHADDR (0x[a-zA-Z_0-9]{8})', line)
    match_sizeaddr = re.match(r'\s*#define .*_SIZEADDR (0x[a-zA-Z_0-9])', line)
    match_default = re.match(r'\s*#define .*_DEFAULT (0x[a-zA-Z_0-9])', line)
    match_width = re.match(r'\s*#define .*_WIDTH ([a-zA-Z_0-9])', line)
    match_offset = re.match(r'\s*#define (.*)_OFFSET (0x[a-zA-Z_0-9]+)', line)
    match_comment = re.match(r'\s*//', line)

    if match_baseaddr:
        baseaddr = match_baseaddr.group(1)
        baseaddr_int= int(baseaddr,16)	
        output_file.write(line)

    elif match_highaddr:
        highaddr = match_highaddr.group(1)
        highaddr_int= int(highaddr,16)	
        output_file.write(line)

    elif match_sizeaddr:
        sizeaddr = match_sizeaddr.group(1)
        sizeaddr_int= int(sizeaddr,16)	
        output_file.write(line)

    elif match_default:
        default = match_default.group(1)
        default_int = int(default,16)	
        output_file.write(line)

    elif match_width:
        width = match_width.group(1)
        width_int= int(width,16)	
        output_file.write(line)

    elif match_comment:	
        output_file.write(line)

    elif match_offset:
        offset = match_offset.group(2)
        offset_int=int(offset,16)
        new_val = hex(baseaddr_int+offset_int)     
        newline= "#define %s %s\n" % (match_offset.group(1),new_val)
        output_file.write(newline)

    else:
        output_file.write(line)


