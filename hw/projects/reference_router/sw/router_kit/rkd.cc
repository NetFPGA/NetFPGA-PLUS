/*******************************************************************************
*
* Copyright (C) 2010, 2011 The Board of Trustees of The Leland Stanford
*                          Junior University
* Copyright (C) Martin Casado
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
// Description:
//
// Router kit user-level program for monitoring arouting and ARP table and
// syncronizing with NetFPGAv2.1 hardware.

#include <iostream>
#include <vector>
#include <string>
#include <cstdio>
#include <cstdlib>
#include <sys/stat.h>

#include "iflist.hh"
#include "sume_mon.hh"
#include "linux_proc_net.hh"

extern "C" {
#include <getopt.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <limits.h>
}


using namespace rk;
using namespace std;

static int DEFAULT_INTERVAL_MS = 50; // Be default poll proc every 50ms

// --
// Vanilla daemonization code shamelessly adapted from
// (http://www.enderunix.org/docs/eng/daemon.php)
// --

void signal_handler(int sig)
{
    switch(sig) {
    case SIGHUP:
        break;
    case SIGTERM:
        ::exit(0);
        break;
    }
}

void daemonize()
{
    int i;
    if(::getppid()==1) return;
    i=::fork();
    if (i<0) ::exit(1);
    if (i>0) ::exit(0);
    ::setsid();
    for (i=::getdtablesize();i>=0;--i) ::close(i);
    i=::open("/dev/null",O_RDWR); ::dup(i); ::dup(i);
    ::umask(027);
    ::chdir("/tmp");
    ::signal(SIGCHLD,SIG_IGN);
    ::signal(SIGTSTP,SIG_IGN);
    ::signal(SIGTTOU,SIG_IGN);
    ::signal(SIGTTIN,SIG_IGN);
    ::signal(SIGHUP,signal_handler);
    ::signal(SIGTERM,signal_handler);
}

void usage(const string& argv0)
{
    cout << argv0 << " the NetFPGA SUME linux shadowing daemon " << endl;
    cout << "usage: " << argv0 << " [-h|--help][-d|--daemon][-i|--interval=<poll interval>]" << endl;
    cout << "\t[-h|--help] : this message " << endl;
    cout << "\t[-d|--daemon] : run "<<argv0<<" a a daemon process " << endl;
    cout << "\t[-p|--interval]= : set the polling interval " << endl;
    ::exit(0);
}

std::string long_options_to_short_options(struct option options[])
{
    std::string short_options;
    for (; options->name; options++) {
        struct option* o = options;
        if (o->flag == NULL && o->val > 0 && o->val <= UCHAR_MAX) {
            short_options.push_back(o->val);
            if (o->has_arg == required_argument) {
                short_options.push_back(':');
            } else if (o->has_arg == optional_argument) {
                short_options.append("::");
            }
        }
    }
    return short_options;
}


int main(int argc,char **argv)
{
    bool daemon = false;
    int  interval  = DEFAULT_INTERVAL_MS;
    //char interface[32];
    //bzero(interface, 32);


    for (;;) {
        static struct option long_options[] = {
            {"help",  no_argument, 0, 'h'},
            {"daemon",  no_argument, 0, 'd'},

            {"interval",      required_argument, 0, 'p'},
            //{"interface",      required_argument, 0, 'i'},
            {0, 0, 0}, //, 0},
        };
        static std::string short_options(long_options_to_short_options(
                    long_options));
        int option_index;

        int c;

        c = getopt_long(argc, argv, short_options.c_str(),
                long_options, &option_index);
        if (c == -1)
            break;

        switch (c) {
            case 'h':
                usage(argv[0]);
                break;

            case 'd':
                daemon = true;
                break;

            case 'p':
                interval = atoi(optarg);
                break;

            //case 'i':
            //    strncpy(interface, optarg, 32);
            //    break;

            case '?':
                exit(EXIT_FAILURE);

            default:
                abort();
        }

    }

    rtable rtcur;
    rtable rtcheck;

    iflist ifcur;
    iflist ifcheck;

    arptable arpcur;
    arptable arpcheck;

    sume_mon eh_mon; //interface);


    if(daemon){
        daemonize();
    }

    while(1)
    {
        linux_proc_net_load_rtable(rtcheck);

        if(rtcheck != rtcur){
            eh_mon.rtable_update(rtcheck);
            rtcur = rtcheck;
        }

        linux_proc_net_load_arptable(arpcheck);

        if(arpcheck != arpcur)
        {
            arpcur = arpcheck;
            eh_mon.arptable_update(arpcheck);
        }

        fill_iflist(ifcheck);

        if(ifcheck != ifcur){
            eh_mon.interface_update(ifcheck);
            ifcur = ifcheck;
        }

        ::usleep(interval);
    }

    return 0;
}
