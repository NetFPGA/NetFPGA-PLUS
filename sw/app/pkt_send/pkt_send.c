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

#define MODE_SEND_PACKETS 1
#define MODE_GET_CLOCKS 2
#define MODE_SIZE_RANGE_REPORT 4

#define PERF_LOOPS 3

int debug;
int mode = MODE_SEND_PACKETS;

static void
usage(const char *progname)
{
	printf("Usage: %s [-d] [-b <pkt_len>] [-i <interface>] [-n <number_pkts>] [-r <number_pkts>] [-z] \n", progname);
	printf("\t-d : debug mode on (prints additional information. Performance results invalid.)\n");
	printf("\t-b : Specify the number of bytes in packet (length) 60-1514. 4 bytes extra will be added as CRC.\n");
	printf("\t-i : Specify the interface. Default is 'nf0'. See ifconfig.\n");
	printf("\t-n : Specify the number of packets to send for each test.\n");
	printf("\t-r : Report mode: measures performance over a range of packet sizes.\n");
	printf("\t     Specify number of packets per test.\n");
	printf("\t-z : Measure AXI and AXIS clocks and report their frequencies.\n");
	exit(1);
}

int main(int argc, char *argv[])
{
	char *ifnam;
	int rc;
	uint32_t pkt_len; // without CRC
	uint32_t num_to_send;
	ds_sample_t sampled_regs;
	float axi_Hz, axis_Hz;
	float perf_Mbps;

	pkt_len = 60;
	num_to_send = 1;
	ifnam = "nf0";//NFPLUS_IFNAM_DEFAULT;
	while ((rc = getopt(argc, argv, "b:i:n:r:dhz")) != -1) {
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
		case 'i':
			ifnam = optarg;
			break;
		case 'r': // report performance over packet size range
			mode |= MODE_SIZE_RANGE_REPORT;
			mode &= ~MODE_SEND_PACKETS;
		case 'n':
			num_to_send = strtoul(optarg, NULL, 0);
			if (num_to_send < 1)
				errx(1, "Invalid number to send - must be >= 1");
			break;
		case 'z':
			mode |= MODE_GET_CLOCKS;
			break;
		case 'h':
		case '?':
		default:
			usage(argv[0]);
			/* NOT REACHED */
		}
	}

	rc = ps_compute_freqs_Hz(ifnam, &axi_Hz, &axis_Hz);
	if (debug) { 
		rc = ps_get_id_ds(ifnam);
		printf("FPGA design reports Module ID value 0x%0x\n", rc);
	}


	if (mode & MODE_GET_CLOCKS) {
		printf("AXI clock:  %6.2f MHz\nAXIS clock: %6.2f MHz\n", axi_Hz/1000000.0, axis_Hz/1000000.0);
		exit(0);
	}


	if (mode & MODE_SEND_PACKETS) {

		// Enable collection
		if ((rc = ps_enable_ds(ifnam))) err(rc, "Unable to enable datasink module");
		// Send packets
		if ((rc = ps_send_pkt_socket(ifnam, pkt_len, num_to_send))) err(rc, "Error sending packets.");
		// Sample registers
		if ((rc = ps_sample_ds(ifnam ))) err(rc, "Unable to issue sample command to data_sink module.");
		// Load shadow registers into sample structure
		if ((rc = ps_get_sample_ds(ifnam, &sampled_regs))) err(rc, "Unable to read the sample shadow registers in data_sink module.");

		if (debug) {
			printf("Num pkts: %d\n", sampled_regs.num_packets);
			printf("Num bytes: %0lu\n", sampled_regs.num_bytes);
			printf("Num clk periods of activity: %d\n", sampled_regs.num_ds_periods);
		}

		perf_Mbps = ps_compute_performance_bps(axis_Hz, &sampled_regs)/1000000.0;
		printf("Performance was %6.1f Mbps (%6.2f Gbps)\n", perf_Mbps, perf_Mbps/1000.0);
		// Disable collection and reset counters (clean up)
		if ((rc = ps_disable_ds(ifnam))) err(rc, "Unable to disable datasink module");
	}


	if (mode & MODE_SIZE_RANGE_REPORT) {

		uint32_t pkt_len = 60;

		while (pkt_len <= ETH_FRAME_LEN) {

			perf_Mbps = 0.0;

			for (int avg_loop = 0; avg_loop < PERF_LOOPS; avg_loop++) {

				// Enable collection
				if ((rc = ps_enable_ds(ifnam))) err(rc, "Unable to enable datasink module");
				// Send packets
				if ((rc = ps_send_pkt_socket(ifnam, pkt_len, num_to_send))) err(rc, "Error sending packets.");
				// Sample registers
				if ((rc = ps_sample_ds(ifnam ))) err(rc, "Unable to issue sample command to data_sink module.");
				// Load shadow registers into sample structure
				if ((rc = ps_get_sample_ds(ifnam, &sampled_regs))) err(rc, "Unable to read the sample shadow registers in data_sink module.");

				if (debug) {
					printf("Num pkts: %d\n", sampled_regs.num_packets);
					printf("Num bytes: %0lu\n", sampled_regs.num_bytes);
					printf("Num clk periods of activity: %d\n", sampled_regs.num_ds_periods);
				}

				perf_Mbps += ps_compute_performance_bps(axis_Hz, &sampled_regs)/1000000.0;
				// Disable collection and reset counters (clean up)
				if ((rc = ps_disable_ds(ifnam))) err(rc, "Unable to disable datasink module");
			}
			perf_Mbps /= PERF_LOOPS;
			printf("%0d, %6.2f\n", pkt_len, perf_Mbps/1000.0);

			if ((pkt_len < 128) || ((pkt_len % 64) == 0))
				pkt_len++;
			else 
				pkt_len = (pkt_len + 16) & 0xfff0;
		}
	}

	exit(0);
}


