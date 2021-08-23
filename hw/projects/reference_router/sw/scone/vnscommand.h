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
/*   Description:

   A c-style declaration of commands for the virtual router.

  ---------------------------------------------------------------------------*/

#ifndef __VNSCOMMAND_H
#define __VNSCOMMAND_H

#define VNSOPEN       1
#define VNSCLOSE      2
#define VNSPACKET     4
#define VNSBANNER     8
#define VNSHWINFO    16

#define IDSIZE 32

/*-----------------------------------------------------------------------------
                                 BASE
  ---------------------------------------------------------------------------*/

typedef struct
{
    uint32_t mLen;
    uint32_t mType;
}__attribute__ ((__packed__)) c_base;

/*-----------------------------------------------------------------------------
                                 OPEN
  ---------------------------------------------------------------------------*/

typedef struct
{

    uint32_t mLen;
    uint32_t mType;        /* = VNSOPEN */
    uint16_t topoID;       /* Id of the topology we want to run on */
    uint16_t pad;          /* unused */
    char     mVirtualHostID[IDSIZE]; /* Id of the simulated router (e.g.
                                        'VNS-A'); */
    char     mUID[IDSIZE]; /* User id (e.g. "appenz"), for information only */
    char     mPass[IDSIZE];

}__attribute__ ((__packed__)) c_open;

/*-----------------------------------------------------------------------------
                                 CLOSE
  ---------------------------------------------------------------------------*/

typedef struct
{

    uint32_t mLen;
    uint32_t mType;
    char     mErrorMessage[256];

}__attribute__ ((__packed__)) c_close;

/*-----------------------------------------------------------------------------
                                HWREQUEST
  ---------------------------------------------------------------------------*/

typedef struct
{

    uint32_t mLen;
    uint32_t mType;

}__attribute__ ((__packed__)) c_hwrequest;

/*-----------------------------------------------------------------------------
                                 BANNER
  ---------------------------------------------------------------------------*/

typedef struct
{

    uint32_t mLen;
    uint32_t mType;
    char     mBannerMessage[256];

}__attribute__ ((__packed__)) c_banner;

/*-----------------------------------------------------------------------------
                               PACKET (header)
  ---------------------------------------------------------------------------*/


typedef struct
{
    uint32_t mLen;
    uint32_t mType;
    char     mInterfaceName[16];
    uint8_t  ether_dhost[6];
    uint8_t  ether_shost[6];
    uint16_t ether_type;

}__attribute__ ((__packed__)) c_packet_ethernet_header;

typedef struct
{
    uint32_t mLen;
    uint32_t mType;
    char     mInterfaceName[16];
}__attribute__ ((__packed__)) c_packet_header;

/*-----------------------------------------------------------------------------
                               HWInfo
  ----------------------------------------------------------------------------*/

#define HWINTERFACE    1
#define HWSPEED        2
#define HWSUBNET       4
#define HWINUSE        8
#define HWFIXEDIP     16
#define HWETHER       32
#define HWETHIP       64
#define HWMASK       128

typedef struct
{
    uint32_t mKey;
    char     value[32];
}__attribute__ ((__packed__)) c_hw_entry;

typedef struct
{
#define MAXHWENTRIES 256
    uint32_t   mLen;
    uint32_t   mType;
    c_hw_entry mHWInfo[MAXHWENTRIES];
}__attribute__ ((__packed__)) c_hwinfo;


#endif  /* __VNSCOMMAND_H */
