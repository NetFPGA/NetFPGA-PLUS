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

#ifndef OR_UTILS_H_
#define OR_UTILS_H_

#include "or_data_types.h"

node* node_create(void);
void node_push_back(node* head, node* n);
void node_remove(node** head, node* n);
int node_length(node* head);

void populate_eth_hdr(eth_hdr* ether_hdr, uint8_t* dhost, uint8_t *shost, uint16_t type);
void populate_arp_hdr(arp_hdr* arp_header, uint8_t* arp_tha, uint32_t arp_tip, uint8_t* arp_sha, uint32_t arp_sip, uint16_t op);
void populate_ip(ip_hdr* ip, uint16_t payload_size, uint8_t protocol, uint32_t source_ip, uint32_t dest_ip);
void populate_icmp(icmp_hdr* icmp, 	uint8_t icmp_type, uint8_t icmp_code, uint8_t* payload, int payload_len);
void populate_pwospf(pwospf_hdr*pwospf, uint8_t type, uint16_t len, uint32_t rid, uint32_t aid);
void populate_pwospf_hello(pwospf_hello_hdr* hello, uint32_t mask, uint16_t helloint);
void populate_pwospf_lsu(pwospf_lsu_hdr* lsu, uint16_t seq, uint32_t num);
void populate_padding(uint8_t *start, unsigned int len);

void populate_nat_packet(ip_hdr *ip, const uint8_t *packet, unsigned int len,  nat_entry *ne, int nat_type);

char* mallocCopy(const char* c);
void register_cli_command(node** head, char* command, cli_command_handler handler);
void cleanCRLFs(char* c);
void send_to_socket(int sockfd, char *buf, int len);
char* my_strncat(char* left, char* right, int* left_alloc_size);
char* urlencode(char* str);
char* urldecode(char* str);
int getMax(int* int_array, int len);
#endif /*OR_UTILS_H_*/
