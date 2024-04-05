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
#ifndef NFDS_LIB_H
#define NFDS_LIB_H


// Address space within the card in which nf_data_sink is located. (BAR2)
#define NF_DATA_SINK_BASE_ADDR 0x10000
#define NF_DATA_SINK_BAR 2

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

uint32_t nfds_get_id(int port_id);
void nfds_enable(int port_id);
void nfds_disable(int port_id);
void nfds_sample(int port_id);
void nfds_get_sample(int port_id, ds_sample_t *sample_data);
// int nfds_compute_freqs_Hz(char *ifnam, float *axi_Hz, float *axis_Hz);
// int nfds_build_raw_packet(char *ifnam, int sockfd, char *sendbuf, struct sockaddr_ll *socket_address, uint32_t num_bytes);
// int nfds_send_pkt_socket(char *ifnam, uint32_t num_bytes, uint32_t num_to_send);
// int nfds_get_tkeep_ds(char *ifnam, uint64_t *tkeep);
float nfds_compute_performance_bps(float axis_Hz, ds_sample_t *sampled_regs);


#endif