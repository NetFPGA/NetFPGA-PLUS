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
#        axitools.py
#
#  Description:
#        A python module for manipulating AXI grammar formatted text.
#

import math
import sys
import os
from NFTest import *

# under cygwin, there is no hardware support - so suppress hardware initialisation
if sys.platform.startswith('cygwin'):
    import scapy.config
    scapy.config.conf.iface = ''

from scapy.layers.all import Ether, raw


class BadAXIDataException( Exception ):
    """
    AXI file format exceptions.
    """
    def __init__( self, filename, lineno, msg ):
        self.filename = filename
        self.lineno   = lineno
        self.msg      = msg

    def __str__( self ):
        return '%s: %d: bad AXI data: %s' % (self.filename, self.lineno, self.msg)


def axis_dump( packets, f, bus_width, period, tuser_width = 128 ):
    """
    Dumps the list of packets to an AXI Stream-grammar formatted text file.
    Attribute .tuser (array of 128-bit integers) will supply TUSER if present,
    and .tuser_sport and .tuser_dport, if present, will be applied (overriding)
    any .tuser.
    """

    def tuser_mask( partial_mask ):
        """
        Returns a full, tuser-width mask from partial_mask
        """
        return int( ('%x' % partial_mask).rjust( tuser_width//4, 'f' ), 16 )

    if bus_width % 8 != 0:
        print("bus_width must be a multiple of 8!")
        return

    bus_width = bus_width // 8
    strb_mask = (1 << bus_width) - 1
    last_ts   = None
    period    = int(period * 1e9)

    #Cope with the case of individual packets being sent instead of a list
    if isinstance(packets,Ether):
        packets = [packets]

    for packet in packets:
        # Output delay parameter
        if last_ts is not None:
            if (int(packet.time * 1e9)-last_ts) > 0 :
                f.write( '+ %d\n' % (int(packet.time * 1e9)-last_ts) )
        else:
            f.write( '@ %d\n' % (int(packet.time * 1e9)))
        last_ts = int(packet.time * 1e9)

        # Set up TUSER
        if hasattr( packet, 'tuser' ):
            if type(packet.tuser) == list and type(packet.tuser[0]) == int:
                tuser = packet.tuser
            elif type(packet.tuser) == int:
                tuser = [packet.tuser]
            elif type(packet.tuser) == str:
                tuser = [int(packet.tuser, 16)]
            else:
                raise TypeError( 'bad tuser data (not an array of ints)' )
        else:
            tuser = [0]
        # Override length, sport, dport fields as appropriate
        tuser[0] = (tuser[0] & tuser_mask(0xffffff0000) ) | len(packet)
        if hasattr( packet, 'tuser_sport' ):
            tuser[0] = (tuser[0] & tuser_mask(0xffff00ffff) ) | (packet.tuser_sport << 16)
        if hasattr( packet, 'tuser_dport' ):
            tuser[0] = (tuser[0] & tuser_mask(0xff00ffffff) ) | (packet.tuser_dport << 24)

        # Turn into a list of bytes
        packet = [x for x in bytes(packet)]
        # Dump word-by-word
        for i in range(0, len(packet), bus_width):
            if len(packet)-i < bus_width:
                padding = bus_width - (len(packet)-i)
                word = packet[i:] + [0] * padding
            else:
                padding = 0
                word = packet[i:i+bus_width]
            word.reverse()                            # TDATA is little-endian
            if i + bus_width >= len(packet):
                terminal = '.'
            else:
                terminal = ','

            # Add TUSER pad to guarantee something is there to pop
            tuser.append(0)
            f.write( '%s, %s, %s%s\n' % (
                    ''.join( '%02x' % x for x in word ),                # TDATA
                    ('%x' % (strb_mask >> padding)).zfill(bus_width//4), # TSTRB
                    ('%x' % tuser.pop(0)).zfill(tuser_width//4),         # TUSER
                    terminal ) )                                        # TLAST

            # one clock tick
            last_ts += period
        f.write( '\n' )

def axis_reg( packets, f ):
    last_ts   = None
    for packet in packets:
        if last_ts is not None:
            if (int(packet.time * 1e9)-last_ts) > 0 :
                f.write( '+ %d\n' % (int(packet.time * 1e9)-last_ts) )
        else:
            f.write( '@ %d\n' % (int(packet.time * 1e9)))
        last_ts = int(packet.time * 1e9)


def axis_load( f, period ):
    """
    Loads packets from an AXI Stream-grammar formatted text file as a list of
    Scapy packet instances.  The following extra attributes are added to each
    instance:
        .tuser          raw contents of TUSER, stored as array of 128-bit ints
        .tuser_len      packet length (from TUSER)
        .tuser_sport    source port (one-hot, from TUSER)
        .tuser_dport    dest port (one-hot, from TUSER)
    """
    def as_bytes(x):
        """
        Splits hex string X into list of bytes.
        """
        return [int(x[i:i+2],16) for i in range(0,len(x),2)]

    bus_width = None
    time = 0
    pkt_data = []
    tuser = []
    pkts = []
    for lno, line in enumerate(f):
        lno += 1
        try:
            # Look to see if a comment is present.  If not, index() will throw
            # an exception, and we skip this section.
            hash_index = line.index( '#' )
        except ValueError:
            pass
        else:
            line = line[:hash_index]
        line = line.strip()
        if not line:
            continue

        # Handle delay specs
        if   line[0] == '@':
            a = line.lstrip('@')
            b = a.lstrip(' ')
            time = int(b)
        elif line[0] == '+':
            time += int(line[1:])/1e9
        elif line[0] == '*':
            time += period * int(line[1:])
        else: # treat as data
            terminal = line[-1]
            line     = line[:-1]
            if terminal not in [',', '.']:
                raise BadAXIDataException( f.name, lno, 'unknown terminal %s' % terminal )
            line = [x.strip() for x in line.split(',')]
            if len(line) != 3:
                raise BadAXIDataException( f.name, lno, 'invalid data (expected 3 fields, got %d)' %len(line) )

            # handle start of packet
            if not pkt_data:
                SoP_time = time
            if bus_width is None:
                bus_width = len(line[0]) * 4
                if math.log(bus_width,2) - int(math.log(bus_width,2)) != 0:
                    print('%s: data bus not a power of two in width' % f.name)
            # accumulate packet and TUSER data
            pkt_data += reversed( as_bytes( line[0].zfill( bus_width//4 ) ) )
            tuser.append( int( line[2], 16 ) )
            # handle end of packet
            if terminal == '.':
                valid_bytes = int( math.log( int( line[1], 16 ) + 1, 2 ) )
                if valid_bytes < bus_width//8: # trim off any padding
                    del pkt_data[valid_bytes-bus_width//8:]
                pkts.append(Ether(raw(pkt_data)))
                pkts[-1].time        =  SoP_time
                pkts[-1].tuser       =  tuser
                pkts[-1].tuser_len   =  tuser[0] & 0xffff
                pkts[-1].tuser_sport = (tuser[0] >> 16) & 0xff
                pkts[-1].tuser_dport = (tuser[0] >> 24) & 0xff
                pkt_data = []
                tuser    = []
                if len(pkts[-1]) != pkts[-1].tuser_len:
                    print('*** warning: meta length (%d) disagrees with actual length (%d) -- %s, line: %d' % ( pkts[-1].tuser_len , len(pkts[-1]), f.name, lno))
            time += period
    return pkts
