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


all : scone

CC  = gcc

OSTYPE = $(shell uname)

ifeq ($(OSTYPE),Linux)
ARCH = -D_LINUX_
SOCK = -lnsl
endif

ifeq ($(OSTYPE),SunOS)
ARCH =  -D_SOLARIS_
SOCK = -lnsl -lsocket
endif

ifeq ($(OSTYPE),Darwin)
ARCH = -D_DARWIN_
SOCK =
endif

CFLAGS = -g -Wall -D_DEBUG_ $(ARCH) -I lwtcp -D_GNU_SOURCE
#Define _NOLWIP_ to bind to use linux sockets and bind to localhost
CFLAGS = -no-pie -g -Wall -D_DEBUG_ $(ARCH) -I lwtcp -I ../common -D_GNU_SOURCE -D_CPUMODE_

LIBS= $(SOCK) -lm -lresolv -lpthread -lpcap -lnet
PFLAGS= -follow-child-processes=yes -cache-dir=/tmp/${USER}
PURIFY= purify ${PFLAGS}

#------------------------------------------------------------------------------
LWTCP_SRCS = lwtcp/tcp.c lwtcp/tcp_input.c lwtcp/tcp_output.c\
             lwtcp/mem.c lwtcp/memp.c lwtcp/stats.c lwtcp/sys.c\
             lwtcp/inet.c lwtcp/pbuf.c lwtcp/sys_arch.c\
			 lwtcp/sockets.c lwtcp/api_lib.c lwtcp/api_msg.c\
			 lwtcp/transport_subsys.c lwtcp/udp.c lwtcp/icmp.c lwtcp/ip_addr.c\
			 lwtcp/err.c

LWTCP_OBJS = $(patsubst lwtcp/%.c, %.o, $(LWTCP_SRCS))


liblwtcp.a : $(LWTCP_OBJS)
	ar rcu liblwtcp.a $(LWTCP_OBJS)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
SR_BASE_SRCS = sr_base.c sr_dumper.c sr_integration.c sr_lwtcp_glue.c\
               sr_vns.c sr_cpu_extension_nf.c or_main.c or_utils.c\
               or_arp.c or_icmp.c or_ip.c or_iface.c or_rtable.c\
		       or_output.c or_cli.c or_vns.c or_sping.c or_pwospf.c\
		       or_dijkstra.c or_netfpga.c or_www.c or_nat.c

SR_BASE_OBJS = $(patsubst %.c,%.o,$(SR_BASE_SRCS)) ../common/nfplus_util.o ../common/nf_util.o

libsr_base.a : $(SR_BASE_OBJS)
	ar rcu libsr_base.a $(SR_BASE_OBJS)
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
SR_SRCS =  sr_main.c

SR_OBJS = $(patsubst %.c,%.o,$(SR_SRCS))

scone : $(SR_OBJS) libsr_base.a liblwtcp.a
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS)

purify : $(SR_OBJS) libsr_base.a liblwtcp.a
	purify $(CC) $(CFLAGS) -o $@.purify $^ $(LIBS)

#------------------------------------------------------------------------------

DIJKSTRA_SRCS = or_dijkstra_test.c

DIJKSTRA_OBJS = $(patsubst %.c,%.o,$(DIJKSTRA_SRCS))

dijkstra-test : $(DIJKSTRA_OBJS) libsr_base.a liblwtcp.a -lnet
	$(CC) $(CFLAGS) -o dijkstra-test $^ $(LIBS)

RAWSOCK_SRCS = rawsock.c

RAWSOCK_OBJS = $(patsubst %.c,%.o,$(RAWSOCK_SRCS)) ../common/sume_util.o ../common/nf_util.o

rawsock : $(RAWSOCK_OBJS) libsr_base.a liblwtcp.a -lnet
	$(CC) $(CFLAGS) -o rawsock $^ $(LIBS)

#------------------------------------------------------------------------------
ALL_SRCS   = $(sort $(SR_SRCS) $(SR_BASE_SRCS) $(LWTCP_SRCS))

ALL_LWTCP_SRCS = $(filter lwtcp/%.c, $(ALL_SRCS))
ALL_SR_SRCS    = $(filter-out lwtcp/%.c, $(ALL_SRCS))

ALL_LWTCP_OBJS = $(patsubst lwtcp/%.c,%.o, $(ALL_LWTCP_SRCS))
ALL_SR_OBJS    = $(patsubst %.c,%.o, $(ALL_SR_SRCS))

ALL_LWTCP_DEPS = $(patsubst lwtcp/%.c,.%.d,$(ALL_LWTCP_SRCS))
ALL_SR_DEPS    = $(patsubst %.c,.%.d,$(ALL_SR_SRCS))

$(ALL_SR_OBJS) : %.o : %.c
	$(CC) -c $(CFLAGS) $< -o $@
$(ALL_LWTCP_OBJS) : %.o : ./lwtcp/%.c
	$(CC) -c $(CFLAGS) $< -o $@

$(ALL_LWTCP_DEPS) : .%.d : ./lwtcp/%.c
	$(CC) -MM $(CFLAGS) -I lwtcp/ $<  > $@
$(ALL_SR_DEPS) : .%.d : %.c
	$(CC) -MM $(CFLAGS) -I lwtcp/ $<  > $@

include $(ALL_LWTCP_DEPS)
include $(ALL_SR_DEPS)

#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
.PHONY : clean clean-deps dist install

clean:
	rm -f *.o *~ core.* scone *.dump *.tar tags *.a test_arp_subsystem\
          lwcli lwtcpsr sr_base.tar.gz

clean-deps:
	rm -f .*.d

dist: clean clean-deps
	(cd ..; tar --exclude-from=base/exclude -cvf sr_base.tar base/; gzip sr_base.tar; mv\
    sr_base.tar.gz base/)

tags:
	ctags *.c

install:


#------------------------------------------------------------------------------
