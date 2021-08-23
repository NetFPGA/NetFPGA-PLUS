#/*******************************************************************************
#*
#* Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
#*                          Junior University
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

all : nfplus_util.o libnfplus.so

libnfplus.so: nfplus_util.c nfplus_util.h nf_util.c nf_util.h
	gcc -fpic -c nfplus_util.c nf_util.c
	gcc -shared nfplus_util.o nf_util.o -o $@

clean :
	rm -rf nfplus_util.o nf_util.o libnfplus.so

install: libnfplus.so
	install -d /usr/local/lib
	install -m 644 libnfplus.so /usr/local/lib
	ln -s -f /usr/local/lib/libnfplus.so /usr/local/lib/libnfplusregs.so
	ldconfig

.PHONY: clean 
