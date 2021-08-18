/*
 * Copyright (c) 2015 Bjoern A. Zeeb
 * All rights reserved.
 *
 *  File:
 *        sume_reg.c
 *
 * Author:
 *        Bjoern A. Zeeb
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
*/

#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#if defined(__linux__)
#include <errno.h>
#elif defined(__FreeBSD__)
#include <sys/errno.h>
#include <sys/sockio.h>
#endif

#include <net/if.h>

#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define NFPLUS_IFNAM_DEFAULT              "nf0"
//#include "nf_sume.h"
/*
 * We are trying to use the same (private, deprecated) IOCTLs NF10 is
 * using.  Unfortunately the old user space tools (rdax/wraxi) operated
 * on a dedicated device node, rather using netdevice(7).
 */
#if defined(__linux__)
#define NFPLUS_IOCTL_CMD_WRITE_REG        (SIOCDEVPRIVATE+1)
#define NFPLUS_IOCTL_CMD_READ_REG         (SIOCDEVPRIVATE+2)
#elif defined(__FreeBSD__)
#define NFPLUS_IOCTL_CMD_WRITE_REG        (SIOCGPRIVATE_0)
#define NFPLUS_IOCTL_CMD_READ_REG         (SIOCGPRIVATE_1)
#else
#error NetFPGA NFPLUS ioctls not supported on this OS
#endif

struct sume_ifreq {
        uint32_t        addr;
        uint32_t        val;
};

/*
 * This is based on the function declarations used by python in NF10
 * ("spec") to maintain the API and compatibility:
 * - uint32_t regread(uint32_t addr);
 * - int regwrite(uint32_t addr, uint32_t val);
 * - int regread_expect(uint32_t addr, uint32_t expval);
 * and the error value define:
 * - #define ERROR_CODE 0xdeadbeef
 * Ideally we'd give them better (prefixed) names and 64bit data variables
 * (if not address variables as well), to allow for a 20th century future.
 * Further we'd add an const char *ifname, to allow working on more than
 * one card.
 */

#define	_NFPLUS_REG_ERROR_CODE	0xdeadbeef

int
sume_do_register(struct sume_ifreq *sifr, unsigned long request, char *ifnam)
{
	struct ifreq ifr;
	size_t ifnamlen;
	int fd, rc;

	memset(&ifr, 0, sizeof(ifr));
	ifnamlen = strlen(ifnam);
	if (ifnamlen >= sizeof(ifr.ifr_name))
		return (EINVAL);
	memcpy(ifr.ifr_name, ifnam, ifnamlen);
	ifr.ifr_name[ifnamlen] = '\0';
	ifr.ifr_data = (char *)sifr;

	fd = socket(AF_INET6, SOCK_DGRAM, 0);
	if (fd == -1) {
		fd = socket(AF_INET, SOCK_DGRAM, 0);
		if (fd == -1)
			return (ENOPROTOOPT);
	}

	rc = ioctl(fd, request, &ifr);
	if (rc == -1)
		rc = ENOTTY;
        close(fd);

	return (rc);
}

uint32_t
regread(uint32_t addr)
{
	struct sume_ifreq sifr;
	int rc;

	sifr.addr = addr;
	sifr.val = 0;
	rc = sume_do_register(&sifr, NFPLUS_IOCTL_CMD_READ_REG,
	    NFPLUS_IFNAM_DEFAULT);
	if (rc != 0)
		return (_NFPLUS_REG_ERROR_CODE);
	return (sifr.val);
}

int
regread_expect(uint32_t addr, uint32_t expval)
{
	struct sume_ifreq sifr;
	int rc;

	/*
	 * We unfortunately cannot just call regread, as we lose the error
	 * information making it indistinguishable to an actual register value.
	 */
	sifr.addr = addr;
	sifr.val = 0;
	rc = sume_do_register(&sifr, NFPLUS_IOCTL_CMD_READ_REG,
	    NFPLUS_IFNAM_DEFAULT);
	if (rc != 0)
		return (_NFPLUS_REG_ERROR_CODE);

	if (sifr.val == expval)
		return (1);
	else
		return (0);
}

int
regwrite(uint32_t addr, uint32_t val)
{
	struct sume_ifreq sifr;
	int rc;

	sifr.addr = addr;
	sifr.val = val;
	rc = sume_do_register(&sifr, NFPLUS_IOCTL_CMD_WRITE_REG,
	    NFPLUS_IFNAM_DEFAULT);
	if (rc != 0)
		return (_NFPLUS_REG_ERROR_CODE);

	return (0);
}

/* end */
