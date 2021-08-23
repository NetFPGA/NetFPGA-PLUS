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


#ifndef OR_ICMP_H_
#define OR_ICMP_H_

#include "or_data_types.h"
#include "sr_base_internal.h"

void process_icmp_packet(struct sr_instance* sr, const uint8_t * packet, unsigned int len, const char* interface);

int send_icmp_packet(struct sr_instance* sr, const uint8_t* src_packet, unsigned int len, uint8_t icmp_type, uint8_t icmp_code);
uint16_t compute_icmp_checksum(icmp_hdr* icmp, int payload_len);
icmp_hdr* get_icmp_hdr(const uint8_t* packet, unsigned int len);

int send_icmp_echo_request_packet(struct sr_instance* sr, struct in_addr dest, unsigned short id);
int process_icmp_echo_reply_packet(struct sr_instance* sr, const uint8_t* packet, unsigned int len);

#endif /*OR_ICMP_H_*/
