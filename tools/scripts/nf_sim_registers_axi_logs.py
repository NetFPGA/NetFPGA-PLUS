#!/usr/bin/env python3
#
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

import glob
import os
import sys
import csv, collections
import re

REG_STIM     = 'reg_stim.log'    
REG_EXPECT   = 'reg_expect.axi'
REG_AXI      = 'reg_stim.axi'

def expected():
    i = 0
    with open(REG_EXPECT) as f:
        for line in f.readlines():
            i = i + 1
    return i

def main():
    reg_stim = '%s' % (REG_STIM)
    print('Check registers')

    with open(REG_EXPECT) as g:
        r = 0
        w = 0
        for line in g.readlines():
            if 'R 00000001' in line:
                r = r + 1 # read
            elif 'W 00000002' in line:
                w = w + 1 # write

    with open(REG_AXI) as k:
        h = 0
        t = 0
        for line in k.readlines():
            if 'R 00000001' in line:
                h = 1 # read
            elif 'W 00000002' in line:
                t = 1 # write

    with open( reg_stim ) as output:
        f = output.readlines()    	
        a = 0
        b = 0
        c = 0
        d = 0
        e = 0 
        lines = 0

        for line in f:
            lines = lines + 1
            if 'Error' in line:
                e = 1
                if '<' in line: 
                    c = c + 1 # write
                elif '>' in line:
                    d = d + 1 # read
                else:
                    c = c
                    d = d

            elif 'WARNING' in line:
                e = 2

            else:
                if '<' in line:
                    a = a + 1 # write
                elif '>' in line:
                    b = b + 1 # read
                else:
                    a = a
                    b = b

        if e == 1 or w != a or r != b:	
            print('\tFAIL ( Check reg_stim.log file!!!! )')
        elif e == 2:
            print('\tPASS ( WARNING! Check reg_stim.log file!!!! )')
        elif lines == 0 and expected() != 0:
            print('\tFAIL ( Did not get any results! )')
        elif h != 1 and t != 1:
            print('\tPASS ( No registers checked )')
        else:
            print('\tPASS')

    print()
    return 0

if __name__ == '__main__':
    main()
