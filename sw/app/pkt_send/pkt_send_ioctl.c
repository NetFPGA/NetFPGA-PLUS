/*
 * Copyright (c) 2024 Gregory Watson
 * All rights reserved.
 *
 *  File:
 *        pkt_send_ioctl.c
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

#include "pkt_send_ioctl.h"

extern int debug;

int call_ioctl (uint32_t addr, uint32_t op, char *ifnam, uint32_t *rd_data, uint32_t wr_data)
{
	struct xlni_ioctl_ifreq sifr;
	struct ifreq ifr;
	size_t ifnamlen;
	static int fd;
	int rc, req;

	req = NFDP_IOCTL_CMD_READ_REG; // default to read
	if (op == OP_IS_WRITE) req = NFDP_IOCTL_CMD_WRITE_REG;

	ifnamlen = strlen(ifnam);
	if (ifnamlen >= sizeof(ifr.ifr_name))
		errx(1, "Interface name too long");

	if (fd == 0) {
		fd = socket(AF_INET6, SOCK_DGRAM, 0);
		if (fd == -1) {
			fd = socket(AF_INET, SOCK_DGRAM, 0);
			if (fd == -1)
				err(1, "socket failed for AF_INET6 and AF_INET");
		}
	}

	memset(&sifr, 0, sizeof(sifr));
	sifr.addr = addr;
	if (op == OP_IS_WRITE) {
		sifr.val = wr_data;
		req = NFDP_IOCTL_CMD_WRITE_REG;
	}

	memset(&ifr, 0, sizeof(ifr));
	memcpy(ifr.ifr_name, ifnam, ifnamlen);
	ifr.ifr_name[ifnamlen] = '\0';
	ifr.ifr_data = (char *)&sifr;

	rc = ioctl(fd, req, &ifr);
	if (rc == -1)
		err(1, "ioctl");
	
	if (op == OP_IS_READ) *rd_data = sifr.val;
	return (0);
}

int
read_register (char *ifnam, uint32_t addr, uint32_t *rd_data)
{
	if (debug) printf("DEBUG: read_register: reading address 0x%0x.\n",addr);
	return call_ioctl (addr, OP_IS_READ, ifnam, rd_data, addr/*unused*/);
}

int
write_register (char *ifnam, uint32_t addr, uint32_t wr_data)
{
	if (debug) printf("DEBUG: write_register: Write value 0x%0x to address 0x%0x.\n", wr_data, addr);
	return call_ioctl (addr, OP_IS_WRITE, ifnam, NULL, wr_data);
}



/* end */
