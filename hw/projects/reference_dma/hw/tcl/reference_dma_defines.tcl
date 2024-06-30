#
# Copyright (c) 2015 Noa Zilberman
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


#######################
# Segments Assignment #
#######################
#M00 
set M00_BASEADDR 0x00000000
set M00_HIGHADDR 0x00000FFF
set M00_SIZEADDR 0x1000

#M01 
set M01_BASEADDR 0x00010000
set M01_HIGHADDR 0x00010FFF
set M01_SIZEADDR 0x1000

#M02 
set M02_BASEADDR 0x00020000
set M02_HIGHADDR 0x00020FFF
set M02_SIZEADDR 0x1000

##M03 
#set M03_BASEADDR 0x44030000
#set M03_HIGHADDR 0x44030FFF
#set M03_SIZEADDR 0x1000
#

#######################
# IP_ASSIGNMENT       #
#######################
# Note that physical connectivity must match this mapping

# Where is this used????

#NF_DATA_SINK base address and size
set NF_DATA_SINK_BASEADDR $M00_BASEADDR
set NF_DATA_SINK_HIGHADDR $M00_HIGHADDR
set NF_DATA_SINK_SIZEADDR $M00_SIZEADDR


