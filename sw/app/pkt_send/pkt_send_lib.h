/*
 * Copyright (c) 2024 Gregory Watson
 * All rights reserved.
 *
 *  File:
 *        pkt_send_lib.h
 *
 * $Id:$
 *
 * Author:
 *        Greg Watson
 *
 * Function library for pkt_send.
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
*/
#ifndef PKT_SEND_LIB_H
#define PKT_SEND_LIB_H

#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/ether.h>

// Address space within the card in which nf_data_sink is located.
#define NF_DATA_SINK_BASE_ADDR 0x10000

#define NF_DATA_SINK_ENABLE_ACTIVATE 1
#define NF_DATA_SINK_ENABLE_DEACTIVATE 0
#define NF_DATA_SINK_ENABLE_SAMPLE (1<<1)

#define NF_CLOCK_DIV 8

// Sampled data from the Datasink module
typedef struct {
    uint32_t num_packets;    // number of packets received
    uint64_t num_bytes; // number of bytes received
    uint32_t num_ds_periods; // number of clocks/NF_CLOCK_DIV from 1st to last byte.
} ds_sample_t;

uint32_t ps_get_id_ds(char *ifnam);
int ps_enable_ds(char *ifnam);
int ps_disable_ds(char *ifnam);
int ps_sample_ds(char *ifnam);
int ps_get_sample_ds(char *ifnam, ds_sample_t *sample_data);
int ps_send_pkt_socket(char *ifnam, uint32_t num_bytes);
int ps_get_tkeep_ds(char *ifnam, uint64_t *tkeep);


#endif