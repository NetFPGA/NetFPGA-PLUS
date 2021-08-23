#/*******************************************************************************
#*
#* Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
#*                          Junior University
#* Copyright (C) Martin Casado
#* All rights reserved.
#*
#* This software was developed by
#* Stanford University and the University of Cambridge Computer Laboratory
#* under National Science Foundation under Grant No. CNS-0855268,
#* the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
#* by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
#* as part of the DARPA MRC research programme.
#*
#* @NETFPGA_LICENSE_HEADER_START@
#*
#* Licensed under the Apache License, Version 2.0 (the "License");
#* you may not use this file except in compliance with the License.
#* You may obtain a copy of the License at
#*
#*  http://www.apache.org/licenses/LICENSE-2.0
#*
#* Unless required by applicable law or agreed to in writing, software
#* distributed under the License is distributed on an "AS IS" BASIS,
#* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#* See the License for the specific language governing permissions and
#* limitations under the License.
#*
#* @NETFPGA_LICENSE_HEADER_END@
#*
#*
#******************************************************************************/


all: rkd

HEADERS  = rtable.hh arptable.hh sume_mon.hh iflist.hh
CXXFLAGS = -g -Wall -ansi

rkd : rkd.cc linux_proc_net.o sume_mon.o ../common/nfplus_util.o $(HEADERS)
	g++ -g -Wall -o rkd rkd.cc sume_mon.o ../common/nfplus_util.o linux_proc_net.o

clean:
	rm -f *.o rkd

install:
