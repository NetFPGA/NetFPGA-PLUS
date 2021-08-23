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
 * Main function for sr_router.  Here we basically handle the command
 * line options and start the 'lower level' routing functionality which
 * involves connecting to the VNS server and negotiating the topology
 * and host information.
 *
 * The router functionality should be extended to support:
 *
 *   - ARP
 *   - ICMP
 *   - IP
 *   - TCP
 *   - Routing
 *   - OSPF
 *
 * Once the router is fully implemented it should support 'user level' network
 * code using standard BSD sockets.  To demonstrate this, main(..) must be
 * extended to support a fully interactive CLI from which you can telnet into
 * your router, configure the routing table and the interfaces, print
 * statistics and any other advanced functionality you choose to support.
 *
 *---------------------------------------------------------------------------*/

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

#include "sr_base.h"
#include "lwip/sys.h"
#include "lwip/arch.h"
#include "or_cli.h"
#include "or_www.h"
#include "or_main.h"


int run_user_level_network_program(void* subsys)
{ /* -- dummy method for user level network app -- */

	sys_thread_new(www_main, subsys /* dissown */);

	//launch_user_programs(subsys);
	cli_main(subsys);

	/*
    while(1)
    { sleep(1); }
	*/


    return 0;
} /* -- run_user_level_network_program -- */

int main(int argc, char** argv)
{
    /* --
     *  start the low-level network subsystem
     *
     *  Note: sr recognizes the following command
     *        line args (in getopt format)
     *        "hs:v:p:c:t:r:l:" and doesn't
     *        clean argv
     *                                            -- */

    void* sr = sr_init_low_level_subystem(argc, argv);

		if (sr == 0) {
			return 1;
		}


    /* -- run user level program -- */
    run_user_level_network_program(sr);

    return 0;
} /* -- main -- */
