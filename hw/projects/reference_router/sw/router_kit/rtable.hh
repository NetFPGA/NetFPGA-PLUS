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


#ifndef RTABLE_HH
#define RTABLE_HH

#include "netinet++/ipaddr.hh"

#include <iostream>
#include <string>
#include <vector>

namespace rk
{

//-----------------------------------------------------------------------------
struct ipv4_entry
{
    ipaddr      dest;
    ipaddr      gw;
    ipaddr      mask;

    std::string dev;

    ipv4_entry(const ipaddr&, const ipaddr&, const ipaddr&, const
            std::string&);
    ipv4_entry(const ipv4_entry&);

    bool operator == (const ipv4_entry&) const;
};
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
class rtable
{
    std::vector<ipv4_entry> table;

    public:
    rtable();

    void   add(const ipv4_entry&);
    size_t size() const ;
    bool   contains(const ipv4_entry&);
    void   clear();

    const ipv4_entry& operator[](int i) const;

    rtable& operator = (const rtable&);
    bool    operator == (const rtable&) const;
    bool    operator != (const rtable&) const;
};
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
inline
rtable::rtable()
{
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
void
rtable::add(const ipv4_entry& entry)
{
    table.push_back(entry);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
void
rtable::clear()
{
    table.clear();
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
size_t
rtable::size() const
{
    return table.size();
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool
rtable::contains(const ipv4_entry& entry)
{
    for(size_t i = 0; i < table.size(); ++i){
        if(table[i] == entry){
            return true;
        }
    }
    return false;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
rtable&
rtable::operator = (const rtable& rt)
{
    table.clear();
    table = rt.table;
    return (*this);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool
rtable::operator == (const rtable& rt) const
{
    return (table == rt.table);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool
rtable::operator != (const rtable& rt) const
{
    return (table != rt.table);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
ipv4_entry::ipv4_entry(const ipaddr& dest_, const ipaddr& gw_, const ipaddr&
        mask_, const std::string& dev_ ):
    dest(dest_), gw(gw_), mask(mask_), dev(dev_)
{
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
ipv4_entry::ipv4_entry(const ipv4_entry& in):
    dest(in.dest), gw(in.gw), mask(in.mask), dev(in.dev)
{
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
bool
ipv4_entry::operator == (const ipv4_entry& in) const
{
    return ((dest == in.dest) &&
            (gw   == in.gw)  &&
            (mask == in.mask) &&
            (dev  == in.dev));
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
const ipv4_entry&
rtable::operator[](int i) const
{
    return table[i];
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
inline
std::ostream&
operator <<(std::ostream& os, const ipv4_entry& entry)
{
    os << entry.dest << " : " << entry.gw <<  " : " << entry.mask << " : "
       << entry.dev;

    return os;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
inline
std::ostream&
operator <<(std::ostream& os,rtable& rt)
{
    for ( size_t i = 0; i < rt.size(); ++i){
        os <<  (rt[i]) << std::endl;
    }
    return os;
}
//-----------------------------------------------------------------------------

} // -- namespace rk

#endif // -- RTABLE_HH
