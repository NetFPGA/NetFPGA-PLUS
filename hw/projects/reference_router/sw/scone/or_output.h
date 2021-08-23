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

#ifndef OR_OUTPUT_H_
#define OR_OUTPUT_H_

#include "sr_base_internal.h"
#include "or_data_types.h"

void sprint_arp_cache(router_state *rs, char **buf, int *len);
void sprint_if_list(router_state *rs, char **buf, int *len);
void sprint_pwospf_if_list(router_state *rs, char **buf, int *len);
void sprint_pwospf_router_list(router_state *rs, char **buf, int *len);
void sprint_rtable(router_state *rs, char **buf, int *len);
void print_arp_queue(struct sr_instance* sr);
void print_sping_queue(struct sr_instance* sr);
void sprint_nat_table(router_state *rs, char **buf, unsigned int *len);

void sprint_hw_rtable(router_state *rs, char **buf, unsigned int *len);
void sprint_hw_arp_cache(router_state *rs, char **buf, unsigned int *len);
void sprint_hw_iface(router_state *rs, char **buf, unsigned int *len);
void sprint_hw_nat_table(router_state *rs, char **buf, unsigned int *len);
void sprint_hw_stats(router_state *rs, char **buf, unsigned int *len);
void sprint_hw_drops(router_state *rs, char **buf, unsigned int *len);
void sprint_hw_oq_drops(router_state *rs, char **buf, unsigned int *len);
void sprint_hw_local_ip_filter(router_state *rs, char **buf, unsigned int *len);

void print_packet(const uint8_t *packet, unsigned int len);
void print_eth_hdr(const uint8_t *packet, unsigned int len);
void print_arp_hdr(const uint8_t *packet, unsigned int len);
void print_ip_hdr(const uint8_t *packet, unsigned int len);
void print_icmp_load(const uint8_t *packet, unsigned int len);
void print_tcp_load(const uint8_t *packet, unsigned int len);
void print_pwospf_load(const uint8_t *packet, unsigned int len);
void print_pwospf(pwospf_hdr *pwospf);

void print_ip(ip_hdr *ip);
#endif
