/*******************************************************************************
*
* Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
*                          Junior University
* Copyright (C) David Erickson, Filip Paun
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

#ifndef OR_MAIN_H_
#define OR_MAIN_H_

#include "sr_base_internal.h"
#include "or_data_types.h"

/* Default setting for ARP */
#define INITIAL_ARP_TIMEOUT 300

void init(struct sr_instance* sr);
void init_add_interface(struct sr_instance* sr, struct sr_vns_if* vns_if);
iface_entry* get_interface(struct sr_instance* sr, const char* name);
void init_router_list(struct sr_instance* sr);
void init_rtable(struct sr_instance* sr);
void init_cli(struct sr_instance* sr);
void init_hardware(router_state* rs);
void init_rawsockets(router_state* rs);
void init_libnet(router_state* rs);
void init_pcap(router_state* rs);
void process_packet(struct sr_instance* sr, const uint8_t * packet, unsigned int len, const char* interface);

int send_ip(struct sr_instance* sr, uint8_t* packet, unsigned int len, struct in_addr* next_hop, const char* out_iface);
int send_packet(struct sr_instance* sr, uint8_t* packet, unsigned int len, const char* iface);

uint32_t find_srcip(uint32_t dest);
uint32_t integ_ip_output(uint8_t *payload, uint8_t proto, uint32_t src, uint32_t dst, int len);

void destroy(struct sr_instance* sr);
router_state* get_router_state(struct sr_instance* sr);

#endif /*OR_MAIN_H_*/
