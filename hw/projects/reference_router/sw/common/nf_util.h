/*******************************************************************************
*
* Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
*                          Junior University
* All rights reserved.
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
*
******************************************************************************/


#ifndef _NF_UTIL_H
#define _NF_UTIL_H	1

/* Include for socket IOCTLs */
#include <linux/sockios.h>

#define PATHLEN		80
#define DEVICE_STR_LEN 120


/*
 * Structure to represent an nf device to a user mode programs
 */
struct nf_device {
	char *device_name;
	int fd;
	int net_iface;
};
typedef struct nf_device nf_device;

/*
 *   IOCTLs
 */
#define SIOCREGSTAT 		(SIODEVPRIVATE+0)
#define SIOCREGREAD             (SIOCDEVPRIVATE+2)
#define SIOCREGWRITE            (SIOCDEVPRIVATE+1)


/*
 * Structure for transferring register data via an IOCTL
 */
struct nf_reg {
        unsigned int    reg;
        unsigned int    val;
};


/* Function declarations */

int check_iface(struct nf_device *nf);
int openDescriptor(struct nf_device *nf);
int closeDescriptor(struct nf_device *nf);

extern char nf_device_str[DEVICE_STR_LEN];

#endif
