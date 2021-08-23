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

#ifdef _LINUX_
#include <stdint.h>
#endif /* _LINUX_ */

#ifdef _DARWIN_
#include <inttypes.h>
#endif /* _DARWIN_ */

#include <sys/time.h>
#include <pcap.h>

#define PCAP_VERSION_MAJOR 2
#define PCAP_VERSION_MINOR 4
#define PCAP_ETHA_LEN 6
#define PCAP_PROTO_LEN 2

#define TCPDUMP_MAGIC 0xa1b2c3d4

#define LINKTYPE_ETHERNET 1

#define min(a,b) ( (a) < (b) ? (a) : (b) )

#define SR_PACKET_DUMP_SIZE 1514


/*
 * This is a timeval as stored in disk in a dumpfile.
 * It has to use the same types everywhere, independent of the actual
 * `struct timeval'
 */
struct pcap_timeval {
    int tv_sec;           /* seconds */
    int tv_usec;          /* microseconds */
};


/*
 * How a `pcap_pkthdr' is actually stored in the dumpfile.
 */
struct pcap_sf_pkthdr {
    struct pcap_timeval ts;     /* time stamp */
    uint32_t caplen;         /* length of portion present */
    uint32_t len;            /* length this packet (off wire) */
};

/* Given sr instance, log packet to logfile */
struct sr_instance; /* forward declare */
void sr_log_packet(struct sr_instance* sr, uint8_t* buf, int len );

/**
 * Open a dump file and initialize the file.
 */
FILE* sr_dump_open(const char *fname, int thiszone, int snaplen);

/**
 * Write data into the log file
 */
void sr_dump(FILE *fp, const struct pcap_pkthdr *h, const unsigned char *sp);

/**
 * Close the file
 */
void sr_dump_close(FILE *fp);
