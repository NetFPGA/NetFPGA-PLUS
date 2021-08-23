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

#ifndef OR_RTABLE_H_
#define OR_RTABLE_H_

#include "or_data_types.h"
#include "sr_base_internal.h"

int get_next_hop(struct in_addr* next_hop, char* next_hop_iface, int len, router_state* rs, struct in_addr* destination);
int add_route(router_state* rs, struct in_addr* dest, struct in_addr* gateway, struct in_addr* mask, char* interface);
int del_route(router_state* rs, struct in_addr* dest, struct in_addr* mask);

int deactivate_routes(router_state* rs, char* interface);
int activate_routes(router_state* rs, char* interface);

void trigger_rtable_modified(router_state* rs);
void write_rtable_to_hw(router_state* rs);

void lock_rtable_rd(router_state *rs);
void lock_rtable_wr(router_state *rs);
void unlock_rtable(router_state *rs);

void cli_show_ip_rtable(router_state *rs, cli_request *req);
void cli_show_ip_rtable_help(router_state *rs, cli_request *req);

void cli_ip_route_add(router_state *rs, cli_request *req);
void cli_ip_route_del(router_state *rs, cli_request *req);

void cli_ip_route_help(router_state *rs, cli_request *req);
void cli_ip_route_add_help(router_state *rs, cli_request *req);
void cli_ip_route_del_help(router_state *rs, cli_request *req);

void cli_show_hw_rtable(router_state *rs, cli_request *req);

#endif /*OR_RTABLE_H_*/
