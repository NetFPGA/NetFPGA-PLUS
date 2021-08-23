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

#ifndef SR_CPU_EXTENSIONS_H
#define SR_CPU_EXTENSIONS_H

#include "sr_base_internal.h"

static const uint16_t CPU_CONTROL_READ  = 0x8804;
static const uint16_t CPU_CONTROL_WRITE = 0x8805;
#define               CPU_CONTROL_ADDR    "0:20:ce:10:03"

int  sr_cpu_init_hardware(struct sr_instance*, const char* hwfile);

int sr_cpu_input(struct sr_instance* sr);
int sr_cpu_output(struct sr_instance* sr /* borrowed */,
                       uint8_t* buf /* borrowed */ ,
                       unsigned int len,
                       const char* iface /* borrowed */);

#endif  /* --  SR_CPU_EXTENSIONS_H -- */
