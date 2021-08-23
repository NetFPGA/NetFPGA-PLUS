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


#include <string.h>
#include <assert.h>

#include <stdio.h>

int getarg(int* argc, char*** argv, char* arg, char** val)
{
    int i = 0;

    assert(argc); assert(argv); assert(arg); assert(val);

    for ( i = 0 ; i < *argc; ++i)
    {
        if ( ! strcmp ( (*argv)[i], arg ) )
        { /* -- match -- */

            /* -- if last arg or next arg is a '-' assume no value.
             *    Remove arg and return                            -- */
            if ( i == (*argc) - 1 ||
                 (*argv)[i+1][0] == '-')
            {
                *val = 0; /* -- let caller know there was no value -- */
                (*argc) -- ;
                while ( i < *argc )
                { (*argv)[i] = (*argv)[i+1]; ++i;}
                return 1;
            }

            /* -- arg has value -- */
            *val = (*argv)[i+1];
            (*argc) -=2 ;
            while ( i < *argc )
            { (*argv)[i] = (*argv)[i+2]; ++i;}
            return 1;
        }
    }

    return 0; /* -- no matches found -- */
} /* -- getarg -- */

/* test with: ./a.out --icecream yummy -t hi -h
int main(int argc, char** argv)
{
    int i = 0;
    char argval[32];
    char* expval;



    for ( i = 0; i < argc; ++ i )
    { printf("[%s]",argv[i]); }
    printf("\n");

    if ( ! getarg(&argc, &argv, "-h", &expval) )
    { assert(0); }
    if ( expval )
    { assert(0); }

    for ( i = 0; i < argc; ++ i )
    { printf("[%s]",argv[i]); }
    printf("\n");

    if ( ! getarg(&argc, &argv, "-t", &expval ) )
    { assert(0); }
    if ( ! expval )
    { assert(0); }

    for ( i = 0; i < argc; ++ i )
    { printf("[%s]",argv[i]); }
    printf("\n");

    if ( getarg(&argc, &argv, "-x", &expval) )
    { assert(0); }

    for ( i = 0; i < argc; ++ i )
    { printf("[%s]",argv[i]); }
    printf("\n");

    if ( ! getarg(&argc, &argv, "--icecream", &expval ) )
    { assert(0); }
    assert(expval);


    assert(argc);
    for ( i = 0; i < argc; ++ i )
    { printf("[%s]",argv[i]); }
    printf("\n");

    return 0;
} */
