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


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/ioctl.h>

#include <net/if.h>

#include <arpa/inet.h>

#include "nf_util.h"

/* Local variables */
char nf_device_str[DEVICE_STR_LEN];

/*
 * Check the iface name to make sure we can find the interface
 */
int check_iface(struct nf_device *nf)
{
	struct stat buf;
	char filename[PATHLEN];

	/* See if we can find the interface name as a network device */

	/* Test the length first of all */
	if (strlen(nf->device_name) > IFNAMSIZ)
	{
		fprintf(stderr, "Interface name is too long: %s\n", nf->device_name);
		return -1;
	}

	/* Check for /sys/class/net/iface_name */
	strcpy(filename, "/sys/class/net/");
	strcat(filename, nf->device_name);
	if (stat(filename, &buf) == 0)
	{
		fprintf(stderr, "Found net device: %s\n", nf->device_name);
		nf->net_iface = 1;
		return 0;
	}

	/* Check for /dev/iface_name */
	strcpy(filename, "/dev/");
	strcat(filename, nf->device_name);
	if (stat(filename, &buf) == 0)
	{
		fprintf(stderr, "Found dev device: %s\n", nf->device_name);
		nf->net_iface = 0;
		return 0;
	}

	fprintf(stderr, "Can't find device: %s\n", nf->device_name);
	return -1;
}

/*
 * Open the descriptor associated with the device name
 */
int openDescriptor(struct nf_device *nf)
{
        struct ifreq ifreq;
	char filename[PATHLEN];
	struct sockaddr_in address;
	int i;
	struct sockaddr_in *sin = (struct sockaddr_in *) &ifreq.ifr_addr;
	int found = 0;

	if (nf->net_iface)
	{
		/* Open a network socket */
		nf->fd = socket(AF_INET, SOCK_DGRAM, 0);
		if (nf->fd == -1)
		{
                	perror("socket: creating socket");
                	return -1;
		}
		else
		{
			/* Root can bind to a network interface.
			   Non-root has to bind to a network address. */
			if (geteuid() == 0)
			{
				strncpy(ifreq.ifr_ifrn.ifrn_name, nf->device_name, IFNAMSIZ);
				if (setsockopt(nf->fd, SOL_SOCKET, SO_BINDTODEVICE,
					(char *)&ifreq, sizeof(ifreq)) < 0) {
					perror(nf->device_name); 
					perror("setsockopt: setting SO_BINDTODEVICE");
					return -1;
				}

			}
			else
			{
				/* Attempt to find the IP address for the interface */
				for (i = 1; ; i++)
				{
					/* Find interface number i*/
					ifreq.ifr_ifindex = i;
					if (ioctl (nf->fd, SIOCGIFNAME, &ifreq) < 0)
						break;

					/* Check if we've found the correct interface */
					if (strcmp(ifreq.ifr_name, nf->device_name) != 0)
						continue;

					/* If we get to here we've found the IP */
					found = 1;
					break;
				}

				/* Verify that we found the interface */
				if (!found)
				{
					fprintf(stderr, "Can't find device: %s\n", nf->device_name);
					return -1;
				}

				/* Attempt to get the IP address associated with the interface */
				if (ioctl (nf->fd, SIOCGIFADDR, &ifreq) < 0)
				{
					perror("ioctl: calling SIOCGIFADDR");

					fprintf(stderr, "Unable to find IP address for device: %s\n", nf->device_name);
					fprintf(stderr, "Either run this program as root or ask an administrator\n");
					fprintf(stderr, "to assign an IP address to the device\n");
					return -1;
				}

				/* Set the addres and attempt to bind to the socket */
				address.sin_family = AF_INET;
				address.sin_addr.s_addr = sin->sin_addr.s_addr;
				address.sin_port = htons(0);
				if (bind(nf->fd,(struct sockaddr *)&address,sizeof(address)) == -1) {
					perror("bind: binding");
					return -1;
				}
			}
		}
	}
	else
	{
		strcpy(filename, "/dev/");
		strcat(filename, nf->device_name);
		nf->fd = fileno(fopen(filename, "w+"));
		if (nf->fd == -1)
		{
                	perror("fileno: creating descriptor");
                	return -1;
		}
	}

	return 0;
}

/*
 * Close the descriptor associated with the device name
 */
int closeDescriptor(struct nf_device *nf)
{
        struct ifreq ifreq;
	char filename[PATHLEN];

	if (nf->net_iface)
	{
		close(nf->fd);
	}
	else
	{
		close(nf->fd);
	}

	return 0;
}
