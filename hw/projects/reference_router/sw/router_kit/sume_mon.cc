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

#include "sume_mon.hh"

#include <stdio.h>
#include <fcntl.h>

using namespace rk;
using namespace std;

//-----------------------------------------------------------------------------
sume_mon::sume_mon()
{

        sume = socket(AF_INET6, SOCK_DGRAM, 0);
        if (sume == -1) {
        	sume = socket(AF_INET, SOCK_DGRAM, 0);
        	if (sume == -1){
                	printf("ERROR socket failed for AF_INET6 and AF_INET");
                	return;
        	}
   	}

  	clear_hw_rtable();
  	clear_hw_arptable();
  	clear_dst_filter_rtable();

	// Assumption here that interface name will always be nfX
	int base = atoi(&(this->interface[4]));
	char iface_name[32] = "nf";
	sprintf(&(iface_name[2]), "%i", base);
    	devtoport[iface_name] = 1;
	sprintf(&(iface_name[2]), "%i", base+1);
    	devtoport[iface_name] = 4;
	sprintf(&(iface_name[2]), "%i", base+2);
    	devtoport[iface_name] = 16;
	sprintf(&(iface_name[2]), "%i", base+3);
    	devtoport[iface_name] = 64;

}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
void
sume_mon::rtable_update(const rtable& rt_)
{
    rtable local;
    for(size_t i = 0; i < rt_.size(); ++i){
        if (devtoport.find(rt_[i].dev) != devtoport.end()){
            local.add(rt_[i]);
        }
    }

    if(rt != local){
        // update routing table
        update_routing_table(local);
    }

    rt = local;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
void
sume_mon::arptable_update(const arptable& at_)
{
    arptable local;
    for(size_t i = 0; i < at_.size(); ++i){
        if (devtoport.find(at_[i].dev) != devtoport.end()){
            local.add(at_[i]);
        }
    }

    if(at != local){
        // update arpcache
        update_arp_table(local);
    }

    at = local;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
void
sume_mon::interface_update(const iflist& ifl_)
{
    iflist local;
    for(size_t i = 0; i < ifl_.size(); ++i){
        if (devtoport.find(ifl_[i].name) != devtoport.end()){
            local.add_entry(ifl_[i]);
        }
    }

    if(!(ifl == local)){
        // update interface routing table
        update_interface_table(local);
    }

    ifl = local;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
void
sume_mon::clear_dst_filter_rtable()
{
    for(size_t i = 0; i < FIXME_DST_FILTER_MAX; ++i){
    	writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW, 0);
  	writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_DEST_IP_CAM_ADDRESS | i);
  	writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, 1);
    }
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
void
sume_mon::clear_hw_rtable()
{
    for(size_t i = 0; i < FIXME_RT_MAX; ++i){
    	writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI, 0);
  	writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_HI, 0xffffffff);
  	writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW, 0);
  	writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW, 0);
	writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_LPM_TCAM_ADDRESS | i);
  	writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, 1);
    }
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
void
sume_mon::clear_hw_arptable()
{
    for(size_t i = 0; i < FIXME_ARP_MAX; ++i){
    	writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW, 0);
  	writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI,  0);
  	writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW, 0);
	writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_ARP_CAM_ADDRESS | i);
  	writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, 1);
    }
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
void
sume_mon::nf_set_mac(const uint8_t* addr, int index)
{
    uint32_t mac_hi = 0;
    uint32_t mac_lo = 0;

    mac_hi |= ((unsigned int)addr[0]) << 8;
    mac_hi |= ((unsigned int)addr[1]);

    mac_lo |= ((unsigned int)addr[2]) << 24;
    mac_lo |= ((unsigned int)addr[3]) << 16;
    mac_lo |= ((unsigned int)addr[4]) << 8;
    mac_lo |= ((unsigned int)addr[5]);

    switch(index)
    {
        case 0:
            writeReg(sume, NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_0_HI, mac_hi);
            writeReg(sume, NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_0_LOW, mac_lo);
            break;

        case 1:
            writeReg(sume, NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_1_HI, mac_hi);
            writeReg(sume, NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_1_LOW, mac_lo);
            break;

        case 2:
            writeReg(sume, NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_2_HI, mac_hi);
            writeReg(sume, NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_2_LOW, mac_lo);
            break;
        case 3:
            writeReg(sume, NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_3_HI, mac_hi);
            writeReg(sume, NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_3_LOW, mac_lo);
            break;
        default:
            printf("Unknown port, Failed to write hardware registers\n");
            break;
    }
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
void
sume_mon::update_interface_table(const iflist& newlist)
{

    // Delete old entries ....
    for(size_t i = 0; i < ifl.size(); ++i){
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW, 0);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_DEST_IP_CAM_ADDRESS | i);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, 1);
    }

    // Create new entries ....
    size_t i = 0;
    for(; i < newlist.size(); ++i){
        // set IP address in hardware
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW, htonl(newlist[i].ip.addr));
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_DEST_IP_CAM_ADDRESS | i);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, 1);

        // set MAC address in hardware
        nf_set_mac(&(newlist[i].etha.octet[0]), i);
    }

    // Also add the OSPF ip
    ipaddr ospf("224.0.0.5");
    writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW, htonl(ospf.addr));
    writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_DEST_IP_CAM_ADDRESS | i);
    writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, 1);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
void
sume_mon::update_routing_table(const rtable& newrt)
{
    // Delete old entries ....
    for(size_t i = 0; i < rt.size(); ++i){
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI, 0);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_HI, 0xffffffff);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW, 0);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW, 0);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_LPM_TCAM_ADDRESS | i);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, 1);
    }

    // Create new entries ....
    size_t i = 0;
    for(; i < newrt.size(); ++i){
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI, htonl(newrt[i].dest.addr));
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_HI, htonl(newrt[i].mask.addr));
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW, htonl(newrt[i].gw.addr));
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW, devtoport[newrt[i].dev]);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_LPM_TCAM_ADDRESS | i);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, 1);
    }

}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void
sume_mon::update_arp_table(const arptable& newat)
{
    for(size_t i = 0; i < at.size(); ++i){
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW, 0);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI,  0);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW, 0);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_ARP_CAM_ADDRESS | i);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, 1);
    }

    // Create new entries ....
    size_t i = 0;
    for(; i < newat.size(); ++i){

        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW, ntohl(newat[i].ip.addr));
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI,  newat[i].etha.octet[0] << 8 | newat[i].etha.octet[1]);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW, newat[i].etha.octet[2] << 24 |
                                                     newat[i].etha.octet[3] << 16 |
                                                     newat[i].etha.octet[4] << 8  |
                                                     newat[i].etha.octet[5]);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_ARP_CAM_ADDRESS | i);
        writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, 1);
    }

}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
void
sume_mon::sync_routing_table()
{
}
//-----------------------------------------------------------------------------
