#
# Copyright (c) 2015 Noa Zilberman, Jingyun Zhang
# Copyright (c) 2021 Yuta Tokusashi
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory 
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
# as part of the DARPA MRC research programme,
# and by the University of Cambridge Computer Laboratory under EPSRC EARL Project
# EP/P025374/1 alongside support from Xilinx Inc.
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@
#

# The following list include all the items that are mapped to memory segments
# The structure of each item is as follows {<Prefix name> <ID> <has registers> <library name>}

set DEF_LIST {
	{INPUT_ARBITER 0 1 input_arbiter_v1_0_0/data/input_arbiter_regs_defines.txt} \
	{OUTPUT_QUEUES 0 1 output_queues_v1_0_0/data/output_queues_regs_defines.txt} \
	{OUTPUT_PORT_LOOKUP 0 1 router_output_port_lookup_v1_0_0/data/output_port_lookup_regs_defines.txt } \
}

set target_path $::env(NF_DESIGN_DIR)/test
set target_file $target_path/nf_register_defines.h

if {[file exists ${target_path}] == 0} {
	exec mkdir -p ${target_path}
}

######################################################
# the following function writes the license header
# into the file
######################################################

proc write_header { target_file } {

# creat a blank header file
# do a fresh rewrite in case the file already exits
file delete -force $target_file
open $target_file "w"
set h_file [open $target_file "w"]


puts $h_file "//-"
puts $h_file "// Copyright (c) 2015,2021 University of Cambridge"
puts $h_file "// All rights reserved."
puts $h_file "//"
puts $h_file "// This software was developed by Stanford University and the University of Cambridge Computer Laboratory "
puts $h_file "// under National Science Foundation under Grant No. CNS-0855268,"
puts $h_file "// the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and"
puts $h_file "// by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 (\"MRC2\"), "
puts $h_file "// as part of the DARPA MRC research programme,"
puts $h_file "// and by the University of Cambridge Computer Laboratory under EPSRC EARL Project"
puts $h_file "// EP/P025374/1 alongside support from Xilinx Inc."
puts $h_file "//"
puts $h_file "// @NETFPGA_LICENSE_HEADER_START@"
puts $h_file "//"
puts $h_file "// Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor"
puts $h_file "// license agreements.  See the NOTICE file distributed with this work for"
puts $h_file "// additional information regarding copyright ownership.  NetFPGA licenses this"
puts $h_file "// file to you under the NetFPGA Hardware-Software License, Version 1.0 (the"
puts $h_file "// \"License\"); you may not use this file except in compliance with the"
puts $h_file "// License.  You may obtain a copy of the License at:"
puts $h_file "//"
puts $h_file "//   http://www.netfpga-cic.org"
puts $h_file "//"
puts $h_file "// Unless required by applicable law or agreed to in writing, Work distributed"
puts $h_file "// under the License is distributed on an \"AS IS\" BASIS, WITHOUT WARRANTIES OR"
puts $h_file "// CONDITIONS OF ANY KIND, either express or implied.  See the License for the"
puts $h_file "// specific language governing permissions and limitations under the License."
puts $h_file "//"
puts $h_file "// @NETFPGA_LICENSE_HEADER_END@"
puts $h_file "/////////////////////////////////////////////////////////////////////////////////"
puts $h_file "// This is an automatically generated header definitions file"
puts $h_file "/////////////////////////////////////////////////////////////////////////////////"
puts $h_file ""

close $h_file 

}; # end of proc write_header


######################################################
# the following function writes all the information
# of a specific core into a file
######################################################

proc write_core {target_file prefix id has_registers lib_name} {


set h_file [open $target_file "a"]

#First, read the memory map information from the reference_project defines file
source $::env(NF_DESIGN_DIR)/hw/tcl/$::env(NF_PROJECT_NAME)_defines.tcl
set public_repo_dir $::env(NFPLUS_FOLDER)/hw/lib/


set baseaddr [set $prefix\_BASEADDR]
set highaddr [set $prefix\_HIGHADDR]
set sizeaddr [set $prefix\_SIZEADDR]

puts $h_file "//######################################################"
puts $h_file "//# Definitions for $prefix"
puts $h_file "//######################################################"

puts $h_file "#define NFPLUS_$prefix\_BASEADDR $baseaddr"
puts $h_file "#define NFPLUS_$prefix\_HIGHADDR $highaddr"
puts $h_file "#define NFPLUS_$prefix\_SIZEADDR $sizeaddr"
puts $h_file ""

#Second, read the registers information from the library defines file
if $has_registers {
	set lib_path "$public_repo_dir/std/$lib_name"
	set regs_h_define_file $lib_path
	set regs_h_define_file_read [open $regs_h_define_file r]
	set regs_h_define_file_data [read $regs_h_define_file_read]
	close $regs_h_define_file_read
	set regs_h_define_file_data_line [split $regs_h_define_file_data "\n"]

       foreach read_line $regs_h_define_file_data_line {
            if {[regexp "#define" $read_line]} {
                puts $h_file "#define NFPLUS_[lindex $read_line 2]\_$id\_[lindex $read_line 3]\_[lindex $read_line 4] [lindex $read_line 5]"
            }
	}
}
puts $h_file ""
close $h_file 
}; # end of proc write_core

######################################################
# the main function
######################################################
#
write_header  $target_file 

foreach lib_item $DEF_LIST { 
     write_core  $target_file [lindex $lib_item 0] [lindex $lib_item 1] [lindex $lib_item 2] [lindex $lib_item 3] 
}

