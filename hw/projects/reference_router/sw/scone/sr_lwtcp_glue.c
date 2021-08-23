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

#include "sr_lwtcp_glue.h"
#include <stdio.h>
#include <assert.h>

#ifdef _SOLARIS_
#include <inttypes.h>
#endif /* _SOLARIS_ */

#define  __USE_BSD 1
#include <sys/socket.h>
#include <netinet/in_systm.h>
#include <netinet/ip.h>

#include "lwip/ip_addr.h"
#include "lwip/ip.h"
#include "lwip/netif.h"
#include "lwip/pbuf.h"
#include "lwip/transport_subsys.h"

#include "sr_base_internal.h"

/* unsightly global variable, avert your eyes */
struct netif* inp = NULL;

/*-----------------------------------------------------------------------------
 * Method: sr_transport_input(..)
 * Scope:  Global
 *
 * Called by sr to send a packet to the transport layer.  Packet is assumed
 * to have a header with a correct ip length.  The memory holding packet is
 * left untouched.
 *
 *---------------------------------------------------------------------------*/

void sr_transport_input(uint8_t* packet /* borrowed */)
{
    struct pbuf* pb;

    if (inp == NULL) {
    	inp = (struct netif*)calloc(1, sizeof(struct netif));
    }

    /* -- this is sort of a hack for now, in the future we should
     *    initialize netif's with the hw information and pass handles
     *    to them around with the packets
     *                                                            -- */
    //memset(&inp, sizeof(struct netif), 0);

    struct ip* header = (struct ip*)packet;

    pb = pbuf_alloc(PBUF_RAW, ntohs(header->ip_len), PBUF_RAM);

    pb->len = pb->tot_len = ntohs(header->ip_len);

    memcpy(pb->payload,packet,pb->tot_len);

    tcp_msg_input(pb, inp);
} /* -- sr_transport_input -- */

/*-----------------------------------------------------------------------------
 * Method: ip_route(..)
 * Scope:  Global
 *
 * Called by lwip to pair a destination with the correct source (based on
 * the routing table.  ip_integ_route(..) must be implemented by the network
 * level implementation
 *
 *---------------------------------------------------------------------------*/

uint32_t /*nbo*/ ip_route(struct ip_addr *dest)
{
    return  sr_integ_findsrcip(dest->addr);
} /* -- ip_route -- */

/*-----------------------------------------------------------------------------
 * Method: sr_lwip_output(..)
 * Scope: Global
 *
 * Called by the lwip transport layer to pass packets to the lower level
 * network stack.  If the header is included the packet simply needs to
 * be routed:
 *
 *  sr_integ_ip_route(..)
 *
 * otherwise an IP header must be added
 *
 *  sr_integ_ip_output(..)
 *
 *---------------------------------------------------------------------------*/

err_t sr_lwip_output(struct pbuf *p, struct ip_addr *src, struct ip_addr *dst, uint8_t proto )
{
    struct pbuf *q;
    uint8_t* payload;
    int offset = 0;

    /* initiate transfer(); */


    payload = (uint8_t*)malloc(p->tot_len);

    memcpy(payload + offset, p->payload, p->len);
    offset += p->len;

    for(q = p->next; q != NULL; q = q->next)
    {
        memcpy(payload + offset, q->payload, q->len);
        offset += q->len;
    }

    sr_integ_ip_output(
            payload, /*disown*/
            proto,
            src->addr,
            dst->addr,
            p->tot_len);

    return 0;
} /* -- sr_lwip_output -- */
