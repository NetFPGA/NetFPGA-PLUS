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

#ifndef ETHERNETADDR_HH__
#define ETHERNETADDR_HH__

#include <stdexcept>
#include <iostream>
#include <cassert>
#include <cstring>
#include <string>

extern "C"
{
#include <netinet/in.h>
#include <netinet/ether.h>
#include <stdint.h>
}


inline
unsigned long long htonll(unsigned long long n)
{
#if __BYTE_ORDER == __BIG_ENDIAN
  return n;
#else
  return (((unsigned long long)htonl(n)) << 32) + htonl(n >> 32);
#endif
}

inline
unsigned long long ntohll(unsigned long long n)
{
#if __BYTE_ORDER == __BIG_ENDIAN
  return n;
#else
  return (((unsigned long long)htonl(n)) << 32) + htonl(n >> 32);
#endif
}

//-----------------------------------------------------------------------------
//                             struct ethernetaddr
//-----------------------------------------------------------------------------

static const uint8_t ethbroadcast[] = "\xff\xff\xff\xff\xff\xff";

//-----------------------------------------------------------------------------
struct ethernetaddr
{
    //-------------------------------------------------------------------------
    //-------------------------------------------------------------------------
    static const  unsigned int   LEN =   6;


    //-------------------------------------------------------------------------
    //-------------------------------------------------------------------------
    uint8_t     octet[ethernetaddr::LEN];

    //-------------------------------------------------------------------------
    // Constructors/Detructor
    //-------------------------------------------------------------------------
    ethernetaddr();
    ethernetaddr(const  char*);
    ethernetaddr(uint64_t  id);
    ethernetaddr(const std::string&);
    ethernetaddr(const ethernetaddr&);

    // ------------------------------------------------------------------------
    // String Representation
    // ------------------------------------------------------------------------

    std::string string() const;
    const char* c_string() const;

    uint64_t    as_long() const;

    //-------------------------------------------------------------------------
    // Overloaded casting operator
    //-------------------------------------------------------------------------
    operator const bool    () const;
    operator const uint8_t*() const;
    operator const uint16_t*() const;
    operator const struct ethernetaddr*() const;

    //-------------------------------------------------------------------------
    // Overloaded assignment operator
    //-------------------------------------------------------------------------
    ethernetaddr& operator=(const ethernetaddr&  octet);
    ethernetaddr& operator=(const char*          text);
    ethernetaddr& operator=(uint64_t               id);

    // ------------------------------------------------------------------------
    // Comparison Operators
    // ------------------------------------------------------------------------

    bool operator == (const ethernetaddr&) const;
    bool operator != (const ethernetaddr&) const;
    bool operator <  (const ethernetaddr&) const;
    bool operator <= (const ethernetaddr&) const;
    bool operator >  (const ethernetaddr&) const;
    bool operator >= (const ethernetaddr&) const;

    //-------------------------------------------------------------------------
    // Non-Const Member Methods
    //-------------------------------------------------------------------------

    void set_octet(const uint8_t* oct);

    //-------------------------------------------------------------------------
    // Method: private(..)
    //
    // Check whether the private bit is set
    //-------------------------------------------------------------------------
    bool is_private() const;

    bool is_init() const;

    //-------------------------------------------------------------------------
    // Method: is_multicast(..)
    //
    // Check whether the multicast bit is set
    //-------------------------------------------------------------------------
    bool is_multicast() const;

    bool is_broadcast() const;

    bool is_zero() const;

}__attribute__ ((__packed__));
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
ethernetaddr::ethernetaddr()
{
    memset(octet,0,LEN);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
ethernetaddr::ethernetaddr(const ethernetaddr& addr_in)
{
    ::memcpy(octet,addr_in.octet,LEN);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
ethernetaddr::ethernetaddr(uint64_t id)
{
    if( (id & 0xff000000000000ULL) != 0)
    {
        std::cerr << " ethernetaddr::operator=(uint64_t) warning, value "
            << "larger then 48 bits, truncating" << std::endl;
    }

    id = htonll(id);

#if __BYTE_ORDER == __BIG_ENDIAN
    ::memcpy(octet, &id, LEN);
#else
    ::memcpy(octet, ((uint8_t*)&id) + 2, LEN);
#endif
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
ethernetaddr::ethernetaddr(const char* text)
{
    // -- REQUIRES
    assert(octet != 0);

    struct ether_addr* e_addr;
    e_addr = ::ether_aton(text);
    if(e_addr == 0)
    { ::memset(octet, 0, LEN);; }
    else
    { ::memcpy(octet, e_addr, LEN); }
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
ethernetaddr::ethernetaddr(const std::string& text)
{
    // -- REQUIRES
    assert(octet != 0);

    struct ether_addr* e_addr;
    e_addr = ::ether_aton(text.c_str());
    if(e_addr == 0)
    { ::memset(octet, 0, LEN);; }
    ::memcpy(octet, e_addr, LEN);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
ethernetaddr&
ethernetaddr::operator=(const ethernetaddr& addr_in)
{
    ::memcpy(octet,addr_in.octet,LEN);
    return *this;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
ethernetaddr&
ethernetaddr::operator=(uint64_t               id)
{
    if( (id & 0xff0000000000ULL) != 0)
    {
        std::cerr << " ethernetaddr::operator=(uint64_t) warning, value "
                  << "larger then 48 bits, truncating" << std::endl;
    }
    ::memcpy(octet, &id, LEN);
    return *this;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool
ethernetaddr::is_init() const
{
    return
        (*((uint32_t*)octet) != 0) &&
        (*(((uint16_t*)octet)+2) != 0) ;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
ethernetaddr&
ethernetaddr::operator=(const char* addr_in)
{
    ::memcpy(octet,::ether_aton(addr_in),LEN);
    return *this;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool
ethernetaddr::operator==(const ethernetaddr& addr_in) const
{
    for(unsigned int i=0 ; i < LEN ; i++) {
        if(octet[i] != addr_in.octet[i])
        { return false; }
    }
    return true;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
inline
bool
ethernetaddr::operator!=(const ethernetaddr& addr_in) const
{
    for(unsigned int i=0;i<LEN;i++)
        if(octet[i] != addr_in.octet[i])
            return true;
    return false;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool
ethernetaddr::operator <  (const ethernetaddr& in) const
{
    return ::memcmp(in.octet, octet, LEN) < 0;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool
ethernetaddr::operator <=  (const ethernetaddr& in) const
{
    return ::memcmp(in.octet, octet, LEN) <= 0;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool
ethernetaddr::operator >  (const ethernetaddr& in) const
{
    return ::memcmp(in.octet, octet, LEN) > 0;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool
ethernetaddr::operator >=  (const ethernetaddr& in) const
{
    return ::memcmp(in.octet, octet, LEN) >= 0;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
void
ethernetaddr::set_octet(const uint8_t* oct)
{
    ::memcpy(octet,oct,LEN);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
ethernetaddr::operator const bool    () const
{
    static const uint64_t zero = 0;
    return ::memcmp(octet, &zero, LEN) != 0;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
ethernetaddr::operator const struct ethernetaddr*() const
{
    return reinterpret_cast<const ethernetaddr*>(octet);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
ethernetaddr::operator const uint8_t*() const
{
    return reinterpret_cast<const uint8_t*>(octet);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
ethernetaddr::operator const uint16_t*() const
{
    return reinterpret_cast<const uint16_t*>(octet);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
std::string
ethernetaddr::string() const
{
    return std::string(::ether_ntoa(reinterpret_cast<const ether_addr*>(octet)));
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
uint64_t
ethernetaddr::as_long() const
{
    uint64_t id = *((uint64_t*)octet);
    return (ntohll(id)) >> 16;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
const char*
ethernetaddr::c_string() const
{
    return ::ether_ntoa(reinterpret_cast<const ether_addr*>(octet));
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool ethernetaddr::is_private() const
{
    return((0x40&octet[0]) != 0);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool ethernetaddr::is_multicast() const
{
    return((0x80&octet[0]) != 0);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool ethernetaddr::is_broadcast() const
{
    // yeah ... close enough :)
    return( *((uint32_t*)octet) == 0xffffffff);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool
ethernetaddr::is_zero() const
{
    return ((*(uint32_t*)octet) == 0) && ((*(uint16_t*)(octet+4)) == 0);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
std::ostream&
operator <<(std::ostream& os,const ethernetaddr& addr_in)
{
    os << addr_in.c_string();
    return os;
}
//-----------------------------------------------------------------------------

#endif   // __ETHERNETADDR_HH__
