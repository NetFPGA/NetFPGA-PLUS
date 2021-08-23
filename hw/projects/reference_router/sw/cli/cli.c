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

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <net/if.h>
#include <time.h>
#include <inttypes.h>
#include "../common/reg_defines.h"
#include <string.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include "../common/nfplus_util.h"

#define READ_CMD	0x11
#define WRITE_CMD	0x01

static unsigned MAC_HI_REGS[] = {
  NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_0_HI,
  NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_1_HI,
  NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_2_HI,
  NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_3_HI
};

static unsigned MAC_LO_REGS[] = {
  NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_0_LOW,
  NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_1_LOW,
  NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_2_LOW,
  NFPLUS_OUTPUT_PORT_LOOKUP_0_MAC_3_LOW
};

/* Function declarations */
void prompt (void);
void help (void);
int  parse (char *);
void board (void);
void setip (void);
void setarp (void);
void setmac (void);
void setfilter (void);
void listip (void);
void listarp (void);
void listmac (void);
void listfilter (void);
void loadip (void);
void loadarp (void);
void loadmac (void);
void loadfilter (void);
void clearip (void);
void cleararp (void);
void clearfilter (void);
void showq(void);
uint8_t *parseip(char *str);
uint8_t * parsemac(char *str);

/* Global vars */
int sume;



int main(int argc, char *argv[])
{

  sume = socket(AF_INET6, SOCK_DGRAM, 0);
  if (sume == -1) {
  	sume = socket(AF_INET, SOCK_DGRAM, 0);
        if (sume == -1){
		printf("ERROR socket failed for AF_INET6 and AF_INET");
		return 0;
	}
   }                        
  
  prompt();

  return 0;
}


void prompt(void) {
  while (1) {
    printf("> ");
    char c[10];
    scanf("%s", c);
    int res = parse(c);
    switch (res) {
    case 0:
      listip();
      break;
    case 1:
      listarp();
      break;
    case 2:
      setip();
      break;
    case 3:
      setarp();
      break;
    case 4:
      loadip();
      break;
    case 5:
      loadarp();
      break;
    case 6:
      clearip();
      break;
    case 7:
      cleararp();
      break;
    case 12:
      listmac();
      break;
    case 13:
      setmac();
      break;
    case 14:
      loadmac();
      break;
    case 15:
      listfilter();
      break;
    case 16:
      setfilter();
      break;
    case 17:
      loadfilter();
      break;
    case 18:
      clearfilter();
      break;
    case 8:
      help();
      break;
    case 9:
      return;
    default:
      printf("Unknown command, type 'help' for list of commands\n");
    }
  }
}

void help(void) {
  printf("Commands:\n");
  printf("  listip        - Lists entries in IP routing table\n");
  printf("  listarp       - Lists entries in the ARP table\n");
  printf("  listmac       - Lists the MAC addresses of the router ports\n");
  printf("  listfilter    - Lists entries in Destination IP filter\n");
  printf("  setip         - Set an entry in the IP routing table\n");
  printf("  setarp        - Set an entry in the ARP table\n");
  printf("  setmac        - Set the MAC address of a router port\n");
  printf("  setfilter     - set an entry in Destination IP filter\n");
  printf("  loadip        - Load IP routing table entries from a file\n");
  printf("  loadarp       - Load ARP table entries from a file\n");
  printf("  loadmac       - Load MAC addresses of router ports from a file\n");
  printf("  loadfilter    - Load Destination IP filter from a file\n");
  printf("  clearip       - Clear an IP routing table entry\n");
  printf("  cleararp      - Clear an ARP table entry\n");
  printf("  clearfilter   - Clear a Destination IP filter entry\n");
  printf("  help          - Displays this list\n");
  printf("  quit          - Exit this program\n");
}


void addmac(int port, uint8_t *mac) {
  int err;

  err=writeReg(sume,MAC_HI_REGS[port], mac[0] << 8 | mac[1]);
  if(err) printf("0x%08x: ERROR\n", MAC_HI_REGS[port]);
  err=writeReg(sume,MAC_LO_REGS[port], mac[2] << 24 | mac[3] << 16 | mac[4] << 8 | mac[5]);
  if(err) printf("0x%08x: ERROR\n", MAC_LO_REGS[port]);
}

void addarp(int entry, uint8_t *ip, uint8_t *mac) {
  int err;

  uint32_t table_address;
  table_address = (uint32_t)NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_ARP_CAM_ADDRESS;
  table_address = table_address | entry;

  uint32_t cmd;
  cmd = (uint32_t)WRITE_CMD;

  // |-- 						INDIRECTWRDATA 128bit						      --|
  // |- -INDIRECTWRDATA_A_HI 32bit- -INDIRECTWRDATA_A_LOW 32bit- -INDIRECTWRDATA_B_HI 32bit- -INDIRECTWRDATA_B_LOW 32bit-      -|
  // |-- 		mac_hi 		-- 		mac_lo 	      -- 	0x0000 		   -- 		IP 	      --|
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW, ip[0] << 24 | ip[1] << 16 | ip[2] << 8 | ip[3]);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI,  mac[0] << 8 | mac[1]);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW, mac[2] << 24 | mac[3] << 16 | mac[4] << 8 | mac[5]);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW);

  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, table_address);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, cmd);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND);

}

void addip(int entry, uint8_t *subnet, uint8_t *mask, uint8_t *nexthop, int port) {
  int err;
  uint32_t table_address;

  table_address = (uint32_t)NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_LPM_TCAM_ADDRESS;
  table_address = table_address | entry;

  // |-- 						INDIRECTWRDATA 128bit							--|
  // |- -INDIRECTWRDATA_A_HI 32bit- -INDIRECTWRDATA_A_LOW 32bit- -INDIRECTWRDATA_B_HI 32bit- -INDIRECTWRDATA_B_LOW 32bit-	 -|
  // |-- 		IP 		-- 	next_IP 	     -- 	mask 		 -- 	next_port 	      	--|
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI, subnet[0] << 24 | subnet[1] << 16 | subnet[2] << 8 | subnet[3]);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_HI, mask[0] << 24 | mask[1] << 16 | mask[2] << 8 | mask[3]);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_HI);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW, nexthop[0] << 24 | nexthop[1] << 16 | nexthop[2] << 8 | nexthop[3]);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW, port);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW);

  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, table_address);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, WRITE_CMD);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND);
}

void addfilter(int entry, uint8_t *ip) {
  int err;
  uint32_t table_address;

  table_address = (uint32_t)NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_DEST_IP_CAM_ADDRESS;
  table_address = table_address | entry;

  // |-- 						INDIRECTWRDATA 128bit							--|
  // |- -INDIRECTWRDATA_A_HI 32bit- -INDIRECTWRDATA_A_LOW 32bit- -INDIRECTWRDATA_B_HI 32bit- -INDIRECTWRDATA_B_LOW 32bit-	 -|
  // |-- 	0x00000000	-- 	0x00000000 	     -- 	0x00000000 		 -- 	IP 	      	--|
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI, 0x0);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_HI, 0x0);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_HI);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW, 0x0);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW, ip[0] << 24 | ip[1] << 16 | ip[2] << 8 | ip[3]);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW);

  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, table_address);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, WRITE_CMD);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND);
}


void setip(void) {
  printf("Enter [entry] [subnet]      [mask]       [nexthop] [port]:\n");
  printf("e.g.     0   192.168.1.0  255.255.255.0  15.1.3.1     4:\n");
  printf(">> ");

  char subnet[15], mask[15], nexthop[15];
  int port, entry;
  scanf("%i %s %s %s %x", &entry, subnet, mask, nexthop, &port);

  if ((entry < 0) || (entry > (NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_LPM_TCAM_DEPTH-1))) {
    printf("Entry must be between 0 and 31. Aborting\n");
    return;
  }

  if ((port < 1) || (port > 255)) {
    printf("Port must be between 1 and ff.  Aborting\n");
    return;
  }

  uint8_t *sn = parseip(subnet);
  uint8_t *m = parseip(mask);
  uint8_t *nh = parseip(nexthop);

  addip(entry, sn, m, nh, port);
}

void setarp(void) {
  printf("Enter [entry] [ip] [mac]:\n");
  printf(">> ");

  char nexthop[15], mac[30];
  int entry;
  scanf("%i %s %s", &entry, nexthop, mac);

  if ((entry < 0) || (entry > (NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_ARP_CAM_DEPTH-1))) {
    printf("Entry must be between 0 and 31. Aborting\n");
    return;
  }

  uint8_t *nh = parseip(nexthop);
  uint8_t *m = parsemac(mac);

  addarp(entry, nh, m);
}

void setmac(void) {
  printf("Enter [port] [mac]:\n");
  printf(">> ");

  char mac[30];
  int port;
  scanf("%i %s", &port, mac);

  if ((port < 0) || (port > 3)) {
    printf("Port must be between 0 and 3. Aborting\n");
    return;
  }

  uint8_t *m = parsemac(mac);

  addmac(port, m);
}

void setfilter(void) {
  printf("Enter [entry] [ip]:\n");
  printf("e.g.     0   15.1.3.1:\n");
  printf(">> ");

  char ip[15];
  int entry;
  scanf("%i %s", &entry, ip);

  if ((entry < 0) || (entry > (NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_DEST_IP_CAM_DEPTH-1))) {
    printf("Entry must be between 0 and 31. Aborting\n");
    return;
  }

  uint8_t *destip = parseip(ip);

  addfilter(entry, destip);
}

void listip(void) {
  int i;
  int err;
  uint32_t table_address;
  for (i = 0; i < NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_LPM_TCAM_DEPTH; i++) {
    unsigned subnet, mask, nh, valport;
    table_address = (uint32_t)NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_LPM_TCAM_ADDRESS;
    table_address = table_address | i;

    err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, table_address);
    if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS);
    err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, READ_CMD);
    if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND);

    err=readReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_HI, &subnet);
    if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_HI);
    err=readReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_HI, &mask);
    if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_HI);
    err=readReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_LOW, &nh);
    if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_LOW);
    err=readReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_LOW, &valport);
    if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_LOW);
    
    printf("Entry #%i:   ", i);
    int port = valport & 0xff;
    if (subnet!=0 || mask!=0xffffffff || port!=0) {
      printf("Subnet: %i.%i.%i.%i, ", subnet >> 24, (subnet >> 16) & 0xff, (subnet >> 8) & 0xff, subnet & 0xff);
      printf("Mask: 0x%x, ", mask);
      printf("Next Hop: %i.%i.%i.%i, ", nh >> 24, (nh >> 16) & 0xff, (nh >> 8) & 0xff, nh & 0xff);
      printf("Port: 0x%02x\n", port);
    }
    else {
      printf("--Invalid--\n");
    }
  }
}

void listarp(void) {
  int i = 0;
  int err;
  uint32_t table_address;
  uint32_t cmd;
  for (i = 0; i < NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_ARP_CAM_DEPTH; i++) {
    unsigned ip, machi, maclo;

    table_address = (uint32_t)NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_ARP_CAM_ADDRESS;
    table_address = table_address | i;
    cmd = (uint32_t)READ_CMD;

    err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, table_address);
    if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS);
    err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, cmd);
    if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND);

    err=readReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_LOW, &ip);
    if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_LOW);
    err=readReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_HI, &machi);
    if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_HI);
    err=readReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_LOW, &maclo);
    if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_A_LOW);

    printf("Entry #%i:   ", i);
    if (ip!=0) {
      printf("IP: %i.%i.%i.%i, ", ip >> 24, (ip >> 16) & 0xff, (ip >> 8) & 0xff, ip & 0xff);
      printf("MAC: %x:%x:%x:%x:%x:%x\n", (machi >> 8) & 0xff, machi & 0xff,
              (maclo >> 24) & 0xff, (maclo >> 16) & 0xff,
              (maclo >> 8) & 0xff, (maclo) & 0xff);
    }
    else {
      printf("--Invalid--\n");
    }
  }
}

void listmac(void) {
  int i = 0;
  int err;
  for (i = 0; i < 4; i++) {
    unsigned machi, maclo;

    err=readReg(sume,MAC_HI_REGS[i], &machi);
    if(err) printf("0x%08x: ERROR\n", MAC_HI_REGS[i]);
    err=readReg(sume,MAC_LO_REGS[i], &maclo);
    if(err) printf("0x%08x: ERROR\n", MAC_LO_REGS[i]);

    printf("Port #%i:   ", i);
    printf("MAC: %x:%x:%x:%x:%x:%x\n", (machi >> 8) & 0xff, machi & 0xff,
              (maclo >> 24) & 0xff, (maclo >> 16) & 0xff,
              (maclo >> 8) & 0xff, (maclo) & 0xff);
  }
}

void listfilter(void) {
  int i;
  int err;
  uint32_t table_address;
  for (i = 0; i < NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_DEST_IP_CAM_DEPTH; i++) {
    unsigned ip;
    table_address = (uint32_t)NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_DEST_IP_CAM_ADDRESS;
    table_address = table_address | i;

    err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, table_address);
    if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS);
    err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, READ_CMD);
    if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND);

    err=readReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_LOW, &ip);
    if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTREPLY_B_LOW);
    
    printf("Entry #%i:   ", i);
    if (ip!=0) {
      printf("ip: %i.%i.%i.%i\n", ip >> 24, (ip >> 16) & 0xff, (ip >> 8) & 0xff, ip & 0xff);
    }
    else {
      printf("--Invalid--\n");
    }
  }
}

void loadip(void) {
  char fn[30];
  printf("Enter filename:\n");
  printf(">> ");
  scanf("%s", fn);

  FILE *fp;
  char subnet[20], mask[20], nexthop[20];
  int entry, port;
  if((fp = fopen(fn, "r")) ==NULL) {
    printf("Error: cannot open file %s.\n", fn);
    return;
  }
  while (fscanf(fp, "%i %s %s %s %x", &entry, subnet, mask, nexthop, &port) != EOF) {
    uint8_t *sn = parseip(subnet);
    uint8_t *m = parseip(mask);
    uint8_t *nh = parseip(nexthop);

    addip(entry, sn, m, nh, port);
  }
}

void loadarp(void) {
  char fn[30];
  printf("Enter filename:\n");
  printf(">> ");
  scanf("%s", fn);

  FILE *fp = fopen(fn, "r");
  char ip[20], mac[20];
  int entry;
  while (fscanf(fp, "%i %s %s", &entry, ip, mac) != EOF) {
    uint8_t *i = parseip(ip);
    uint8_t *m = parsemac(mac);

    addarp(entry, i, m);
  }
}

void loadmac(void) {
  char fn[30];
  printf("Enter filename:\n");
  printf(">> ");
  scanf("%s", fn);

  FILE *fp = fopen(fn, "r");
  char mac[20];
  int port;
  while (fscanf(fp, "%i %s", &port, mac) != EOF) {
    uint8_t *m = parsemac(mac);

    addmac(port, m);
  }
}

void loadfilter(void) {
  char fn[30];
  printf("Enter filename:\n");
  printf(">> ");
  scanf("%s", fn);

  FILE *fp;
  char ip[20];
  int entry;
  if((fp = fopen(fn, "r")) ==NULL) {
    printf("Error: cannot open file %s.\n", fn);
    return;
  }
  while (fscanf(fp, "%i %s", &entry, ip) != EOF) {
    uint8_t *filter = parseip(ip);

    addfilter(entry, filter);
  }
}

void clearip(void) {
  int entry;
  int err;
  printf("Specify entry:\n");
  printf(">> ");
  scanf("%i", &entry);


  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI, 0);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_HI, 0xffffffff);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_HI);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW, 0);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW, 0);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW);

  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_LPM_TCAM_ADDRESS | entry);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, 1);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND);
}

void cleararp(void) {
  int entry;
  int err;
  printf("Specify entry:\n");
  printf(">> ");
  scanf("%i", &entry);

  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW, 0);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI,  0);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW, 0);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW);

  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_IP_ARP_CAM_ADDRESS | entry);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, 1);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND);
}

void clearfilter(void) {
  int entry;
  int err;
  printf("Specify entry:\n");
  printf(">> ");
  scanf("%i", &entry);

  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI, 0);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_HI);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_HI, 0);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_HI);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW, 0);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_A_LOW);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW, 0);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTWRDATA_B_LOW);

  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS, NFPLUS_OUTPUT_PORT_LOOKUP_0_MEM_DEST_IP_CAM_ADDRESS | entry);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTADDRESS);
  err=writeReg(sume,NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND, 1);
  if(err) printf("0x%08x: ERROR\n", NFPLUS_OUTPUT_PORT_LOOKUP_0_INDIRECTCOMMAND);
}


int parse(char *word) {
  if (!strcmp(word, "listip"))
    return 0;
  if (!strcmp(word, "listarp"))
    return 1;
  if (!strcmp(word, "setip"))
    return 2;
  if (!strcmp(word, "setarp"))
    return 3;
  if (!strcmp(word, "loadip"))
    return 4;
  if (!strcmp(word, "loadarp"))
    return 5;
  if (!strcmp(word, "clearip"))
    return 6;
  if (!strcmp(word, "cleararp"))
    return 7;
  if (!strcmp(word, "listmac"))
    return 12;
  if (!strcmp(word, "setmac"))
    return 13;
  if (!strcmp(word, "loadmac"))
    return 14;
  if (!strcmp(word, "listfilter"))
    return 15;
  if (!strcmp(word, "setfilter"))
    return 16;
  if (!strcmp(word, "loadfilter"))
    return 17;
  if (!strcmp(word, "clearfilter"))
    return 18;
  if (!strcmp(word, "help"))
    return 8;
  if (!strcmp(word, "quit"))
    return 9;
  return -1;
}

uint8_t * parseip(char *str) {
  uint8_t *ret = (uint8_t *)malloc(4 * sizeof(uint8_t));
  char *num = (char *)strtok(str, ".");
  int index = 0;
  while (num != NULL) {
    ret[index++] = atoi(num);
    num = (char *)strtok(NULL, ".");
  }
  return ret;
}


uint8_t * parsemac(char *str) {
        uint8_t *ret = (uint8_t *)malloc(6 * sizeof(char));
        char *num = (char *)strtok(str, ":");
        int index = 0;
        while (num != NULL) {
                int i;
                sscanf(num, "%x", &i);
                ret[index++] = i;
                num = (char *)strtok(NULL, ":");
        }
        return ret;
}

