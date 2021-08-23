/*-
 * Copyright (c) 2015 Bjoern A. Zeeb
 * All rights reserved.
 *
 * This software was developed by SRI International and the University of
 * Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249
 * ("MRC2"), as part of the DARPA MRC research programme.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * $Id: nf_sume.h,v 1.1 2015/06/24 22:36:12 root Exp root $
 */
/*
 * This work was licensed to NetFPGA C.I.C. (NetFPGA) under
 * one or more contributor license agreements (CLA).  Changes to this work
 * can only be accepted from contributors with a valid CLA in place.
 * See http://www.netfpga-cic.org for more information.
 */

#ifndef _NF_NFPLUS_H
#define _NF_NFPLUS_H

/*
 * NFPLUS default interface name (first interface) for ifreq ioctl;
 * see netdevice(7).
 */
#define NFPLUS_IFNAM_DEFAULT              "nf0"

/*
 * We are trying to use the same (private, deprecated) IOCTLs NF10 is
 * using.  Unfortunately the old user space tools (rdax/wraxi) operated
 * on a dedicated device node, rather using netdevice(7).
 */
#if defined(__linux__)
#define NFPLUS_IOCTL_CMD_WRITE_REG        (SIOCDEVPRIVATE+1)
#define NFPLUS_IOCTL_CMD_READ_REG         (SIOCDEVPRIVATE+2)
#elif defined(__FreeBSD__)
#define NFPLUS_IOCTL_CMD_WRITE_REG        (SIOCGPRIVATE_0)
#define NFPLUS_IOCTL_CMD_READ_REG         (SIOCGPRIVATE_1)
#else
#error NetFPGA NFPLUS ioctls not supported on this OS
#endif

struct sume_ifreq {
        uint32_t        addr;
        uint32_t        val;
};

#endif /* _NF_NFPLUS_H */

/* end */
