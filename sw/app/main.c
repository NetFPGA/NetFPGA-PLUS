/*
 * Copyright (c) 2015 Bjoern A. Zeeb
 * All rights reserved.
 *
 *  File:
 *        rwaxi.c
 *
 * $Id: rwaxi.c,v 1.3 2015/06/24 22:52:20 root Exp root $
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

#define	HAVE_ADDR			0x01
#define	HAVE_VALUE			0x02
#define	HAVE_IFACE			0x04
#define	HAVE_DEBUG 			0x08

static void
usage(const char *progname)
{
	struct xlni_ioctl_ifreq sifr;
	struct ifreq ifr;
	printf("Usage: %s -a <addr> [-d] [-w <value>] [-i <iface>]\n",
	    progname);
	printf("NFDP_IOCTL_CMD_WRITE_REG is %0d\n", NFDP_IOCTL_CMD_WRITE_REG);
	printf("NFDP_IOCTL_CMD_READ_REG is %0d\n", NFDP_IOCTL_CMD_READ_REG);
	printf("Size of ifr is %lu \n",sizeof(ifr));
	printf("Size of sifr is %lu \n",sizeof(sifr));
	_exit(1);
}

int
main(int argc, char *argv[])
{
	char *ifnam;
	struct xlni_ioctl_ifreq sifr;
	struct ifreq ifr;
	size_t ifnamlen;
	unsigned long l;
	uint32_t addr, value;
	int fd, flags, rc, req;
	int i;

	flags = 0x00;
	addr = 0;//NFPLUS_DEFAULT_TEST_ADDR;
	ifnam = "nf0";//NFPLUS_IFNAM_DEFAULT;
	req = NFDP_IOCTL_CMD_READ_REG;
	value = 0;
	while ((rc = getopt(argc, argv, "+a:dhi:w:")) != -1) {
		switch (rc) {
		case 'a':
			l = strtoul(optarg, NULL, 0);
			if (l == ULONG_MAX || l > UINT32_MAX)
				errx(1, "Invalid address");
			addr = (uint32_t)l;
			flags |= HAVE_ADDR;
			break;
		case 'd':
			flags |= HAVE_DEBUG;
			break;
		case 'i':
			ifnam = optarg;
			flags |= HAVE_IFACE;
			break;
		case 'w':
			l = strtoul(optarg, NULL, 0);
			if (l == ULONG_MAX || l > UINT32_MAX)
				errx(1, "Invalid value");
			value = (uint32_t)l;
			flags |= HAVE_VALUE;
			break;
		case 'h':
		case '?':
		default:
			usage(argv[0]);
			/* NOT REACHED */
		}
	}

	ifnamlen = strlen(ifnam);
#if 0
	if ((flags & HAVE_IFACE) == 0)
		fprintf(stderr, "WARNING: using default interface %s\n", ifnam);
#endif
	if ((flags & HAVE_ADDR) == 0)
		fprintf(stderr, "WARNING: using default test address 0x%08x\n",
		    addr);

	fd = socket(AF_INET6, SOCK_DGRAM, 0);
	if (fd == -1) {
		fd = socket(AF_INET, SOCK_DGRAM, 0);
		if (fd == -1)
			err(1, "socket failed for AF_INET6 and AF_INET");
	}

	memset(&sifr, 0, sizeof(sifr));
	sifr.addr = addr;
	if ((flags & HAVE_VALUE) != 0) {
		sifr.val = value;
		req = NFDP_IOCTL_CMD_WRITE_REG;
	}

	memset(&ifr, 0, sizeof(ifr));
	if (ifnamlen >= sizeof(ifr.ifr_name))
		errx(1, "Interface name too long");
	memcpy(ifr.ifr_name, ifnam, ifnamlen);
	ifr.ifr_name[ifnamlen] = '\0';
	ifr.ifr_data = (char *)&sifr;

	if ((flags & HAVE_DEBUG) != 0) {
		printf("IF: %s  Addr: 0x%08x   RD_IOCTL:%0d   WR_IOCTL:%0d\n",
	       ifnam, addr, NFDP_IOCTL_CMD_READ_REG,NFDP_IOCTL_CMD_WRITE_REG );
	}

	printf("Addr of sifr is %llx\n",(unsigned long long)(&sifr));
	printf("ifr before call: 0x");
	for (i=0; i < sizeof(ifr); i++) {
		printf("%02x ",(unsigned int)(((char *)&ifr)[i] & 0xff));
	}
	printf("\n");

	rc = ioctl(fd, req, &ifr);
	if (rc == -1)
		err(1, "ioctl");
	
	close(fd);

	printf("%s 0x%08x = 0x%04x\n", ((flags & HAVE_VALUE) != 0) ? "WROTE" :
	    "READ ", sifr.addr, sifr.val);

	return (0);
}

/* end */
