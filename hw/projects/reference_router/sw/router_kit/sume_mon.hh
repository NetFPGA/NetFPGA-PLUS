/*******************************************************************************
*
* Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
*                          Junior University
* Copyright (C) Martin Casado
* Copyright (C) 2015 Gianni Antichi
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

#ifndef SUME_MON_HH__
#define SUME_MON_HH__

#include "rtable.hh"
#include "iflist.hh"
#include "arptable.hh"

#include <map>

extern "C"
{
#include "../common/reg_defines.h"
#include "../common/nfplus_util.h"
}


namespace rk
{

static const char NF_DEV_PREFIX[]  = "nf";
static const char NF_DEFAULT_DEV[] = "nf10";

class sume_mon
{
  public:

    static const unsigned int FIXME_RT_MAX         = 32;
    static const unsigned int FIXME_ARP_MAX        = 32;
    static const unsigned int FIXME_DST_FILTER_MAX = 32;

	protected:
		// base NF2 interface name
		char interface[32];

    int sume;

    std::map<std::string,int> devtoport;
    std::map<int,std::string> porttodev;

		// SW copies of hardware routing and forwarding table
		rtable   rt;
		arptable at;

    // SW copy of interfacelist ... we're only interested
    // in keeping track of nf interfaces
    iflist   ifl;


    // Utility
    void update_interface_table(const iflist&);
    void update_routing_table  (const rtable&);
    void update_arp_table      (const arptable&);
    void nf_set_mac(const uint8_t* addr, int index);

    void clear_dst_filter_rtable();
    void clear_hw_rtable();
    void clear_hw_arptable();

    void sync_routing_table();

	public:

		sume_mon(); //char* interface);

    // --
    // Events
    // --
    		void rtable_update   (const rtable& rt);
    		void arptable_update (const arptable& at);
    		void interface_update(const iflist& at);

};


} // -- namespace rk

#endif  // -- NF10_MON_HH__
