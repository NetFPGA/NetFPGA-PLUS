/*
 * Copyright (c) 2024 Gregory Watson
 * All rights reserved.
 *
 *  File:
 *        pkt_send_lib.c
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

// #include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>


#include <err.h>
// #include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "pkt_send_ioctl.h"
#include "pkt_send_lib.h"
#include "nf_data_sink_regs_defines.h"

extern int debug;

// Get the module ID value to check it is NF_DATA_SINK.
uint32_t ps_get_id_ds(char *ifnam) {
    uint32_t id;
    read_register   (ifnam, 
                    (uint32_t)(NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_ID_0_OFFSET), 
                     &id
                    );
    if (id != SUME_NF_DATA_SINK_ID_0_DEFAULT) {
        fprintf(stderr, "ERROR: ID register value does not match expected DATA_SINK value of 0x%0x. Saw 0x%0x.\n",
                SUME_NF_DATA_SINK_ID_0_DEFAULT, id
        );
    }
    return id;
}

// Enable DataSink module to start collecting data on packets sent via DMA.
int ps_enable_ds(char *ifnam) {
    return 
    write_register  (ifnam, 
                    (uint32_t)(NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_ENABLE_0_OFFSET), 
                    (uint32_t) NF_DATA_SINK_ENABLE_ACTIVATE
                    );
}

// Disable DataSink module. Resets all counters
int ps_disable_ds(char *ifnam) {
    return 
    write_register  (ifnam, 
                    (uint32_t)(NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_ENABLE_0_OFFSET), 
                    (uint32_t) NF_DATA_SINK_ENABLE_DEACTIVATE
                    );
}

// After packets have been sent, use this to make shadow copies of all registers.
// Data capture will continue.
int ps_sample_ds(char *ifnam) {
    return 
    write_register  (ifnam, 
                    (uint32_t)(NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_ENABLE_0_OFFSET), 
                    (uint32_t) NF_DATA_SINK_ENABLE_SAMPLE | NF_DATA_SINK_ENABLE_ACTIVATE
                    );
}

// After registers have been sampled, read them.
int ps_get_sample_ds(char *ifnam, ds_sample_t *sample_data) {
    int rc;
    uint32_t i32;
    rc = read_register  (ifnam, 
                        (uint32_t)(NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_PKTIN_0_OFFSET), 
                        &i32
                        );
    sample_data->num_packets = i32;
    if (rc == 0) {
        rc |= read_register  (ifnam, 
                            (uint32_t)(NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_BYTESINLO_0_OFFSET), 
                            &i32
                            );
        sample_data->num_bytes = (uint64_t) i32;
    };
    if (rc == 0) {
        rc = read_register  (ifnam, 
                            (uint32_t)(NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_BYTESINHI_0_OFFSET), 
                            &i32
                            );
        sample_data->num_bytes |= ((uint64_t) i32) << 32;
    };
    if (rc == 0) {
        rc = read_register  (ifnam, 
                            (uint32_t)(NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_TIME_0_OFFSET), 
                            &i32
                            );
        sample_data->num_ds_periods = i32;
    };
    return rc;
}

int ps_get_tkeep_ds(char *ifnam, uint64_t *tkeep) {
    int rc;
    uint32_t i32;
	rc = read_register  (ifnam, 
						(uint32_t)(NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_TKEEP_LAST_LO_0_OFFSET), 
						&i32
						);
	*tkeep = (uint64_t) i32;
    if (rc == 0) {
        rc = read_register  (ifnam, 
                            (uint32_t)(NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_TKEEP_LAST_HI_0_OFFSET), 
                            &i32
                            );
        *tkeep |= ((uint64_t) i32) << 32;
    };
	return rc;
}
int ps_compute_freqs_Hz(char *ifnam, float *axi_Hz, float *axis_Hz){
		uint32_t axi_clk_freq [2];
		uint32_t axis_clk_freq[2];
		int rc;
		if ((rc = read_register (ifnam, NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_AXI_CLK_0_OFFSET, &axi_clk_freq[0])))
			err(rc,"Unable to get axi clock count values from registers");
		if ((rc = read_register (ifnam, NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_AXIS_CLK_0_OFFSET, &axis_clk_freq[0])))
			err(rc,"Unable to get axis clock count values from registers");
		sleep(1);
		if ((rc = read_register (ifnam, NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_AXI_CLK_0_OFFSET, &axi_clk_freq[1])))
			err(rc,"Unable to get axi clock count values from registers");
		if ((rc = read_register (ifnam, NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_AXIS_CLK_0_OFFSET, &axis_clk_freq[1])))
			err(rc,"Unable to get axis clock count values from registers");
        *axi_Hz =  (float)(axi_clk_freq[1] -axi_clk_freq[0]);
        *axis_Hz = (float)(axis_clk_freq[1]-axis_clk_freq[0]);
        return 0;
};

// Create packet, populating DA, SA, Ethtype and data. 
// Also populate socket_address though not used for raw.
int ps_build_raw_packet(char *ifnam, int sockfd, char *sendbuf, struct sockaddr_ll *socket_address, uint32_t num_bytes) {
	struct ifreq if_idx;
	struct ifreq if_mac;
	int tx_len = 0;

	/* Get the index of the interface to send on */
	memset(&if_idx, 0, sizeof(struct ifreq));
	strncpy(if_idx.ifr_name, ifnam, IFNAMSIZ-1);
	if (ioctl(sockfd, SIOCGIFINDEX, &if_idx) < 0)
	    perror("SIOCGIFINDEX");
	/* Get the MAC address of the interface to send on */
	memset(&if_mac, 0, sizeof(struct ifreq));
	strncpy(if_mac.ifr_name, ifnam, IFNAMSIZ-1);
	if (ioctl(sockfd, SIOCGIFHWADDR, &if_mac) < 0)
	    perror("SIOCGIFHWADDR");

	/* Construct the Ethernet header */
	memset(sendbuf, 0, BUFSIZ);
	/* Ethernet header - DA */
	sendbuf[0] = 0;
	sendbuf[1] = 1;
	sendbuf[2] = 2;
	sendbuf[3] = 3;
	sendbuf[4] = 4;
	sendbuf[5] = 0;
	/* Ethernet header - SA */
	sendbuf[6] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[0];
	sendbuf[7] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[1];
	sendbuf[8] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[2];
	sendbuf[9] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[3];
	sendbuf[10] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[4];
	sendbuf[11] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[5];
	/* Ethertype field */
	sendbuf[12] = htons(ETH_P_IP) >> 8;
	sendbuf[13] = htons(ETH_P_IP) & 0xff;
	tx_len += 14;

	/* Packet data */
	sendbuf[tx_len++] = 0xde;
	sendbuf[tx_len++] = 0xad;
	sendbuf[tx_len++] = 0xbe;
	sendbuf[tx_len++] = 0xef;
    while (tx_len < num_bytes) sendbuf[tx_len++] = 0xdd;

    /* Index of the network device */
	socket_address->sll_ifindex = if_idx.ifr_ifindex;
	/* Address length*/
	socket_address->sll_halen = ETH_ALEN;
	/* Destination MAC - should be irrelevant as RAW should just send the sendbuf as raw packet*/
	socket_address->sll_addr[0] = 0;
	socket_address->sll_addr[1] = 1;
	socket_address->sll_addr[2] = 2;
	socket_address->sll_addr[3] = 3;
	socket_address->sll_addr[4] = 4;
	socket_address->sll_addr[5] = 0;

	return 0;
}


// Send <num_to_send> packets of size <num_bytes> + 4 bytes.
// (4 bytes of CRC32 will be added to num_bytes user data.)
int ps_send_pkt_socket(char *ifnam, uint32_t num_bytes, uint32_t num_to_send) {
	int sockfd;
	char sendbuf[BUFSIZ];
	struct sockaddr_ll socket_address;
	int rc;

	if (num_bytes < 60 || num_bytes > ETH_FRAME_LEN) {
		fprintf(stderr,"ERROR: ps_send_pkt_socket: packet length must >= 60 and <= ETH_FRAME_LEN (1514)");
		return 1;
	}
	if (num_to_send < 1) {
		fprintf(stderr,"ERROR: ps_send_pkt_socket: number of pkts to send must be 1 or more.");
		return 1;
	}
    if (debug) fprintf(stderr,"INFO:ps_send_pkt_socket %s. pkt size: %0d bytes.\n", ifnam, num_bytes);

	/* Open RAW socket to send on */
	if ((sockfd = socket(AF_PACKET, SOCK_RAW, IPPROTO_RAW)) == -1) {
	    perror("socket");
	}

	/* Build the raw packet that will be sent many times */
	if ((rc = ps_build_raw_packet(ifnam, sockfd, sendbuf, &socket_address, num_bytes))) 
		err(rc, "Error creating raw packet.");

	/* Send packets. sendto is blocking */
    for (uint32_t i=0; i < num_to_send; i++)
    	if (sendto(sockfd, sendbuf, num_bytes, 0, (struct sockaddr*)&socket_address, sizeof(struct sockaddr_ll)) < 0) {
	        printf("Send failed\n");
            return 1;
        }

    close(sockfd);
    return 0;
}

// Compute performance in bits per second
float ps_compute_performance_bps(float axis_Hz, ds_sample_t *sampled_regs) {
	float time_secs;
	float bits_sent;
	time_secs = sampled_regs->num_ds_periods / axis_Hz;
	bits_sent = (float)(sampled_regs->num_bytes * 8);
	return bits_sent / time_secs;
}
