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


#ifndef OR_IP_H_
#define OR_IP_H_

#include "or_data_types.h"
#include "sr_base_internal.h"

void process_ip_packet(struct sr_instance* sr, const uint8_t * packet, unsigned int len, const char* interface);
uint32_t send_ip_packet(struct sr_instance* sr, uint8_t proto, uint32_t src, uint32_t dest, uint8_t *payload, int len);


int is_packet_valid(const uint8_t * packet, unsigned int len);
ip_hdr* get_ip_hdr(const uint8_t* packet, unsigned int len);
uint16_t compute_ip_checksum(ip_hdr* iphdr);
int verify_checksum(uint8_t *data, unsigned int len);

void cli_show_ip_help(router_state *rs, cli_request *req);
void cli_ip_help(router_state *rs, cli_request *req);

#endif /*OR_IP_H_*/
