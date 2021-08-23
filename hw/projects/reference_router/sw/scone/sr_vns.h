/*******************************************************************************
*
* Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
*                          Junior University
* Copyright (C) Martin Casado
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
/*
 * Description:
 *
 * Header file for interface to VNS.  Able to connect, reserve host,
 * receive/parse hardware information, receive/send packets from/to VNS.
 *
 * See method definitions in sr_vns.c for detailed comments.
 *
 *---------------------------------------------------------------------------*/

#ifndef SR_VNS_H
#define SR_VNS_H

#ifdef _LINUX_
#include <stdint.h>
#endif /* _LINUX_ */

#ifdef _DARWIN_
#include <inttypes.h>
#endif /* _DARWIN_ */

#ifdef _SOLARIS_
#include <inttypes.h>
#endif /* _SOLARIS_ */

struct sr_instance* sr; /* -- forward declare -- */

int  sr_vns_read_from_server(struct sr_instance* );

int  sr_vns_connected_to_server(struct sr_instance* );

void sr_vns_init_log(struct sr_instance* sr, char* logfile);

int  sr_vns_connect_to_server(struct sr_instance* ,unsigned short , char* );

int  sr_vns_send_packet(struct sr_instance* ,uint8_t* , unsigned int , const char*);


#endif  /* -- SR_VNS_H -- */
