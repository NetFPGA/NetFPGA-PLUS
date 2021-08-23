/*******************************************************************************
*
* Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
*                          Junior University
* Copyright (C) 2015 Gianni Antichi
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

#include "nfplus_util.h"
#include "nf_sume.h"


int readReg(int f, uint32_t addr, uint32_t *val)
{

        struct sume_ifreq sifr;
        struct ifreq ifr;
        size_t ifnamlen;

        memset(&sifr, 0, sizeof(sifr));
        sifr.addr = addr;

        memset(&ifr, 0, sizeof(ifr));
        ifnamlen=strlen("nf0");
        memcpy(ifr.ifr_name, "nf0", ifnamlen);

        ifr.ifr_name[ifnamlen] = '\0';
        ifr.ifr_data = (char *)&sifr;

        if(ioctl(f, NFPLUS_IOCTL_CMD_READ_REG, &ifr)<0){
                perror("NFPLUS ioctl failed");
                return 1;
        }

        *val = sifr.val;
        return 0;
}


int writeReg(int f, uint32_t addr, uint32_t val)
{

        struct sume_ifreq sifr;
        struct ifreq ifr;
        size_t ifnamlen;

        memset(&sifr, 0, sizeof(sifr));
        sifr.addr = addr;
        sifr.val = val;

        memset(&ifr, 0, sizeof(ifr));
        ifnamlen=strlen("nf0");
        memcpy(ifr.ifr_name, "nf0", ifnamlen);

        ifr.ifr_name[ifnamlen] = '\0';
        ifr.ifr_data = (char *)&sifr;

        if(ioctl(f, NFPLUS_IOCTL_CMD_WRITE_REG, &ifr)<0){
                perror("NFPLUS ioctl failed");
                return 1;
        }

        return 0;
}
