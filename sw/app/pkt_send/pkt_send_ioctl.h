/*
 * Copyright (c) 2024 Gregory Watson
 * All rights reserved.
 *
 *  File:
 *        pkt_send_ioctl.h
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

#ifndef PKT_SEND_IOCTL_H
#define PKT_SEND_IOCTL_H

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

struct xlni_ioctl_ifreq {
	uint32_t addr;
	uint32_t val;
};

//#define	NFPLUS_DEFAULT_TEST_ADDR		0x44020000
#define NFDP_IOCTL_CMD_WRITE_REG        (SIOCDEVPRIVATE+1)
#define NFDP_IOCTL_CMD_READ_REG         (SIOCDEVPRIVATE+2)

#define OP_IS_READ 0
#define OP_IS_WRITE 1


// Provide register address and interface name (e.g. 'nf0')
// If it's a reg read then provide addr of integer variable rd_wr_data.
// If it's a write then provide write data.

int read_register (char *ifnam, uint32_t addr, uint32_t *rd_data);
int write_register (char *ifnam, uint32_t addr, uint32_t wr_data);

#endif /* pkt_send_ioctl.h */

