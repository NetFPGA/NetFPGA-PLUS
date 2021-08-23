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

#ifndef OR_NETFPGA_H_
#define OR_NETFPGA_H_

#include "sr_base_internal.h"
#include "or_data_types.h"

#define CPU0 "cpu0"
#define CPU1 "cpu1"

#define ETH0 "eth0"
#define ETH1 "eth1"

unsigned char getPortNumber(char* name);
unsigned int getOneHotPortNumber(char* name);
void getIfaceFromOneHotPortNumber(char *name, unsigned int len, unsigned int port);

void netfpga_input(struct sr_instance* sr);
void* netfpga_input_threaded(void* arg);
void netfpga_input_threaded_np(void* arg);
int netfpga_output(struct sr_instance* sr, uint8_t* packet, unsigned int len, const char* iface);



/* helper functions */
unsigned get_rd_data_reg(unsigned int queue);
unsigned get_rd_ctrl_reg(unsigned int queue);
unsigned get_rd_num_of_words_avail_reg(unsigned int queue);
unsigned get_rd_num_of_pckts_in_queue_reg(unsigned int queue);
void get_incoming_interface(char *iface, unsigned int len, unsigned int queue);

void lock_netfpga_stats(router_state* rs);
void unlock_netfpga_stats(router_state* rs);
void* netfpga_stats(void* arg);

/* ip filter functions */
void trigger_local_ip_filters_change(router_state* rs);
int add_local_ip_filter(router_state* rs, struct in_addr* ip, char* name);
local_ip_filter_entry* get_local_ip_filter_by_name(router_state*rs, char* name);
local_ip_filter_entry* get_local_ip_filter_by_ip(router_state*rs, struct in_addr* ip);
void lock_local_ip_filters(router_state* rs);
void unlock_local_ip_filters(router_state* rs);

/* Functions for writing packets out */
unsigned int get_wr_num_pkts_in_q(int nf, unsigned char port);
unsigned int get_wr_num_words_left(int nf, unsigned char port);
unsigned int set_wr_data_word(int nf, unsigned char port, unsigned int val);
unsigned int set_wr_ctrl_word(int nf, unsigned char port, unsigned int val);

/* Stats Functions 0-3 eth 4-7 cpu */
unsigned int get_rx_queue_num_pkts_received(int nf, unsigned char port);
unsigned int get_tx_queue_num_pkts_sent(int nf, unsigned char port);
unsigned int get_rx_queue_num_bytes_received(int nf, unsigned char port);
unsigned int get_tx_queue_num_bytes_sent(int nf, unsigned char port);
unsigned int get_rx_queue_num_pkts_dropped_full(int nf, unsigned char port);
unsigned int get_rx_queue_num_pkts_dropped_bad(int nf, unsigned char port);
unsigned int get_oq_num_pkts_dropped(int nf, unsigned char port);

void cli_hw_info(router_state *rs, cli_request *req);

#endif
