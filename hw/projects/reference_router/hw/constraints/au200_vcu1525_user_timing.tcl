#
# Copyright (c) 2021 Yuta Tokusashi
# All rights reserved.
#
# This software was developed by the University of Cambridge Computer
# Laboratory under EPSRC EARL Project EP/P025374/1 alongside support 
# from Xilinx Inc.
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

create_pblock pblock_nf_datapath
add_cells_to_pblock [get_pblocks pblock_nf_datapath] [get_cells -quiet [list nf_datapath_0]]
add_cells_to_pblock [get_pblocks pblock_nf_datapath] [get_cells -quiet [list u_top_wrapper/u_nf_attachment]]
resize_pblock [get_pblocks pblock_nf_datapath] -add {SLR2}

