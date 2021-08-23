/*******************************************************************************
*
* Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
*                          Junior University
* Copyright (C) Martin Casado
* All rights reserved.
*
* This software was developed by
* Stanford University and the University of Cambridge Computer Laboratory
* under National Science Foundation under Grant No. CNS-0855268,
* the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
* by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
* as part of the DARPA MRC research programme.
*
* @NETFPGA_LICENSE_HEADER_START@
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*  http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
* @NETFPGA_LICENSE_HEADER_END@
*
*
******************************************************************************/

#include <cstdio>

#include "linux_proc_net.hh"
#include "netinet++/ipaddr.hh"
#include "netinet++/ethernetaddr.hh"

#include <cstring>

extern "C"
{
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
}

using namespace std;

namespace rk
{

void
linux_proc_net_load_rtable(rtable& rt)
{
    char     buf[BUFSIZ], dev[16];
    uint32_t dest, gw, mask;
    ipaddr   idest, igw, imask;
    int toss;

	FILE* fd = ::fopen(PROC_ROUTE_FILE, "r");

	rt.clear();

	// -- throw away first line
	::fgets(buf, BUFSIZ, fd);
	while( ::fgets(buf, BUFSIZ, fd))
	{
		// yummy
		::sscanf(buf,"%s%x%x%d%d%d%d%x%d%d%d",  dev, &dest, &gw,
				&toss,&toss,&toss,&toss,&mask,&toss,&toss,&toss);
		idest = dest; igw = gw; imask = mask;

		rt.add(ipv4_entry(idest, igw, imask, dev));
	}
	::fclose(fd);
}

void
linux_proc_net_load_arptable(arptable& at)
{
    char buf[BUFSIZ], dev[16];
	FILE* fd = ::fopen(PROC_ARP_FILE, "r");
	char ip[32], mac[32], toss[32];

	at.clear();

	// -- throw away first line
	::fgets(buf, BUFSIZ, fd);
	while( ::fgets(buf, BUFSIZ, fd)){
		::sscanf(buf,"%s%s%s%s%s%s",  ip, toss, toss, mac, toss,dev);

		if(ethernetaddr(mac)){
			at.add(arp_entry(ip, mac, dev));
		}
	}
	::fclose(fd);
}

}
