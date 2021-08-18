#!/usr/bin/env python3
#
# Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
#                          Junior University
# Copyright (C) 2015 David J. Miller
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
#
#  File:
#        nf10_sim_reconcile_axi_logs.py
#
#  Description:
#         Reconciles *_log.axi with *_expected.axi.
#

import axitools
import glob
import os
import sys

EXPECTED_AXI = '_expected.axi'
LOG_AXI      = '_log.axi'

def reconcile_axi( log_pkts, exp_pkts ):
    """
    Reconcile list of logged AXI packets with list of expected packets.
    """
    if log_pkts == exp_pkts:
        print('\tPASS (%d packets expected, %d packets received)' % (len(exp_pkts), len(log_pkts)))
        return False
    else:
        print('\tFAIL (%d packets expected, %d packets received)' % (len(exp_pkts), len(log_pkts)))
        return True


def main():
    fail = False
    for expected_axi in glob.glob( '*%s' % EXPECTED_AXI ):
        # Find log/expected pairs
        log_axi = '%s%s' % (expected_axi[:-len(EXPECTED_AXI)], LOG_AXI)
        if not os.path.isfile( log_axi ):
            continue
        print('Reconciliation of %s with %s' % (log_axi, expected_axi))
        # Load packets (time is ignored, so period=1e-9 is hard-coded)
        with open( log_axi ) as f:
            log_pkts = axitools.axis_load( f, 1e-9 )
        with open( expected_axi ) as f:
            exp_pkts = axitools.axis_load( f, 1e-9 )
        fail |= reconcile_axi( log_pkts, exp_pkts )
        print()
    sys.exit( fail )

if __name__ == '__main__':
    main()
