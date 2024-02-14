/*
 * Copyright (c) 2024 Gregory Watson
 * All rights reserved.
 *
 *  File:
 *        pkt_send.c
 *
 * $Id$
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

#include <sys/ioctl.h>
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

#include "pkt_send_ioctl.h"

static void
usage(const char *progname)
{
	printf("Usage: %s -a <addr> [-d] [-w <value>] [-i <iface>]\n",
	    progname);
	exit(1);
}

int main(int argc, char *argv[])
{
	char *ifnam;
	uint32_t addr, value;
	unsigned long l;
	int rc, flags;

	flags = 0x00;
	addr = 0x10000;//NFPLUS_DEFAULT_TEST_ADDR;
	ifnam = "nf0";//NFPLUS_IFNAM_DEFAULT;
	value = 0;
	while ((rc = getopt(argc, argv, "+a:h")) != -1) {
		switch (rc) {
		case 'a':
			l = strtoul(optarg, NULL, 0);
			if (l == ULONG_MAX || l > UINT32_MAX)
				errx(1, "Invalid address - too long");
			addr = (uint32_t)l;
			break;
		case 'h':
		case '?':
		default:
			usage(argv[0]);
			/* NOT REACHED */
		}
	}

	rc = read_register (ifnam, addr, &value);
	printf("flags %0d  Read from 0x%0x returned 0x%0x\n",flags, addr, value);
	//rc = write_register (ifnam, addr, value);

	exit(0);
}
