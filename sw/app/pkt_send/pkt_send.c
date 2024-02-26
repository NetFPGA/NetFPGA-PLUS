/*
 * Copyright (c) 2024 Gregory Watson
 * All rights reserved.
 *
 *  File:
 *        pkt_send.c
 *
 * $Id:$
 *
 * Author:
 *        Greg Watson
 *
 * Based on rwaxi app in NetFPGA-PLUS/sw/app
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

#include <sys/types.h>
#include <sys/stat.h>

#include <net/if.h>

#include <err.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <net/ethernet.h>


#include "pkt_send_ioctl.h"
#include "pkt_send_lib.h"
#include "nf_data_sink_regs_defines.h"

#define MODE_GET_CLOCKS 1

int debug;
int mode = 0;

static void
usage(const char *progname)
{
	printf("Usage: %s [-b <pkt_len>] [-d]\n",
	    progname);
	exit(1);
}

int main(int argc, char *argv[])
{
	char *ifnam;
	int rc;
	uint32_t pkt_len; // without CRC
	ds_sample_t sampled_regs;

	pkt_len = 60;
	ifnam = "nf0";//NFPLUS_IFNAM_DEFAULT;
	while ((rc = getopt(argc, argv, "b:dhz")) != -1) {
		switch (rc) {
		case 'b':
			pkt_len = strtoul(optarg, NULL, 0);
			if (pkt_len < 60 || pkt_len > ETH_FRAME_LEN)
				errx(1, "Invalid packet length. Must be 60-1514");
			break;
		case 'd':
			debug = 1;
			printf("DEBUG set to 1\n");
			break;
		case 'z':
			mode = MODE_GET_CLOCKS;
			break;
		case 'h':
		case '?':
		default:
			usage(argv[0]);
			/* NOT REACHED */
		}
	}

	if (mode == MODE_GET_CLOCKS) {
		uint32_t axi_clk_freq [2];
		uint32_t axis_clk_freq[2];
		int rc;
		uint32_t c;
		if ((rc = read_register (ifnam, NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_AXI_CLK_0_OFFSET, &axi_clk_freq[0])))
			err(rc,"Unable to get axi clock count values from registers");
		if ((rc = read_register (ifnam, NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_AXIS_CLK_0_OFFSET, &axis_clk_freq[0])))
			err(rc,"Unable to get axis clock count values from registers");
		printf("axi: %d   axis: %d\n", axi_clk_freq[0], axis_clk_freq[0]);
		sleep(1);
		if ((rc = read_register (ifnam, NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_AXI_CLK_0_OFFSET, &axi_clk_freq[1])))
			err(rc,"Unable to get axi clock count values from registers");
		if ((rc = read_register (ifnam, NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_AXIS_CLK_0_OFFSET, &axis_clk_freq[1])))
			err(rc,"Unable to get axis clock count values from registers");
		printf("axi: %d   axis: %d\n", axi_clk_freq[1], axis_clk_freq[1]);
		printf("axi_clocks in 1 second  = %d\n", axi_clk_freq[1]-axi_clk_freq[0]);
		printf("axis_clocks in 1 second = %d\n", axis_clk_freq[1]-axis_clk_freq[0]);

		if ((rc = read_register (ifnam, NF_DATA_SINK_BASE_ADDR+SUME_NF_DATA_SINK_AXI_CLK_0_OFFSET, &c)))
			err(rc,"Unable to get axi clock count values from registers");
		printf("c reg: %d\n", c);
	}
	else {
		rc = ps_get_id_ds(ifnam);
		printf("Saw Module ID value 0x%0x\n", rc);

		// Enable collection
		if ((rc = ps_enable_ds(ifnam))) err(rc, "Unable to enable datasink module");

		// Send packet
		if ((rc = ps_send_pkt_socket(ifnam, pkt_len))) err(rc, "Unable to send packet");

		sleep(1);

		// Sample registers
		if ((rc = ps_sample_ds(ifnam ))) err(rc, "Unable to issue sample command to data_sink module.");

		// Load shadow registers into sample structure
		if ((rc = ps_get_sample_ds(ifnam, &sampled_regs))) err(rc, "Unable to read the sample shadow registers in data_sink module.");

		printf("Num pkts: %d\n", sampled_regs.num_packets);
		printf("Num bytes: %0lu\n", sampled_regs.num_bytes);
		printf("Num clk periods of activity: %d\n", sampled_regs.num_ds_periods);

		// DIsable collection and reset counters
		if ((rc = ps_disable_ds(ifnam))) err(rc, "Unable to disable datasink module");

	}

	exit(0);
}


