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


#ifndef IFLIST_HH__
#define IFLIST_HH__


#include "netinet++/ipaddr.hh"
#include "netinet++/ethernetaddr.hh"

#include <vector>
#include <string>

extern "C"
{
#include <sys/ioctl.h>
#include <net/if.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
}

namespace rk
{

//-----------------------------------------------------------------------------
struct ifentry
{
    ipaddr       ip;
    ethernetaddr etha;
    std::string  name;

    ifentry(const ipaddr&, const ethernetaddr&, const std::string&);

    bool operator == (const ifentry&) const;
};
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
ifentry::ifentry(const ipaddr& ip_, const ethernetaddr& etha_, const
        std::string& name_):
    ip(ip_), etha(etha_), name(name_)
{
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool
ifentry::operator == (const ifentry& entry) const
{
    return (ip   == entry.ip)   &&
           (etha == entry.etha) &&
           (name == entry.name);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
class
iflist
{
    protected:
        std::vector<ifentry> interfaces;

    public:
        iflist();

        void   add_entry(const ifentry&);
        void   clear();
        size_t size() const;

        const ifentry& operator[](int i) const;
        bool operator == (const iflist&) const;
        bool operator != (const iflist&) const;

};
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
const ifentry&
iflist::operator[](int i) const
{
    return interfaces[i];
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool
iflist::operator == (const iflist& entry) const
{
    return interfaces == entry.interfaces;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool
iflist::operator != (const iflist& entry) const
{
    return interfaces != entry.interfaces;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
inline
size_t
iflist::size() const
{
    return interfaces.size();
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
iflist::iflist()
{
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
void
iflist::clear()
{
    interfaces.clear();
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
void
iflist::add_entry(const ifentry& entry)
{
    interfaces.push_back(entry);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// XXX: This is a pretty poor approach to getting the interface list and
// specfic to linux, in the future, we should use something more like
// the code pasted at the end of this section .mc
inline
int fill_iflist(iflist& ifl)
{
    ifl.clear();

    int s = ::socket (PF_INET, SOCK_STREAM, 0);

    // Verify that we actually got the socket
    if (s < 0)
    {
        std::cerr << " Unable to open nf descriptor, exiting .. " << std::endl;
	::exit(1);
    }

    // Get the list of available interfaces
    char          buf[1024];
    struct ifconf ifc;
    ifc.ifc_len = sizeof(buf);
    ifc.ifc_buf = buf;
    if(ioctl(s, SIOCGIFCONF, &ifc) < 0)
    {
        std::cerr << " Unable to obtain the list of interfaces, exiting .. " << std::endl;
	::exit(1);
    }

    // Walk through the list of interfaces
    struct ifreq *ifr_global = ifc.ifc_req;
    int ifaces = ifc.ifc_len / sizeof(struct ifreq);
    for ( int i=1 ; i<ifaces ; i++)
    {
        struct ifreq *ifr = &ifr_global[i];

        ipaddr ip;
        ip = ((struct sockaddr_in *) &ifr->ifr_addr)->sin_addr;

        ethernetaddr etha;
        if (ioctl (s, SIOCGIFHWADDR, ifr) < 0){
            // -- fail silently
        }else{
            etha.set_octet((const uint8_t*)&ifr->ifr_hwaddr.sa_data[0]);
        }

        // std::cout << ip << "  " << etha << "  " << ifr->ifr_name << std::endl;

        ifl.add_entry(ifentry(ip, etha, ifr->ifr_name));
    }

    close (s);
    return 0;
}
//-----------------------------------------------------------------------------


} // -- namespace rk

#endif // -- IFLIST_HH__

// Taken from: http://www.hungry.com/~alves/local-ip-in-C.html
//
//  #include <sys/types.h>
//     #include <sys/socket.h>
//     #include <netdb.h>
//     #include <netinet/in.h>
//     #include <unistd.h>
//     #include <arpa/inet.h>
//     #include <stdio.h>
//     #include <ifaddrs.h>
//     #include <string.h>
//
//     int main (int argc, char *argv[])
//     {
//       struct ifaddrs *ifa = NULL, *ifp = NULL;
//
//       if (getifaddrs (&ifp) < 0)
//         {
//           perror ("getifaddrs");
//           return 1;
//         }
//
//       for (ifa = ifp; ifa; ifa = ifa->ifa_next)
//         {
//           char ip[ 200 ];
//           socklen_t salen;
//
//           if (ifa->ifa_addr->sa_family == AF_INET)
//             salen = sizeof (struct sockaddr_in);
//           else if (ifa->ifa_addr->sa_family == AF_INET6)
//             salen = sizeof (struct sockaddr_in6);
//           else
//             continue;
//
//           if (getnameinfo (ifa->ifa_addr, salen,
//                            ip, sizeof (ip), NULL, 0, NI_NUMERICHOST) < 0)
//             {
//               perror ("getnameinfo");
//               continue;
//             }
//           printf ("%s\n", ip);
//
//         }
//
//       freeifaddrs (ifp);
//
//       return 0;
//     }
