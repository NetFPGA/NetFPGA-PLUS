#!/bin/sh
#
# Copyright (c) 2015 University of Cambridge
# All rights reserved.
#
# This software was developed by the University of Cambridge Computer
# Laboratory under EPSRC INTERNET Project EP/H040536/1, National Science
# Foundation under Grant No. CNS-0855268, and Defense Advanced Research
# Projects Agency (DARPA) and Air Force Research Laboratory (AFRL), under
# contract FA8750-11-C-0249.
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

cam_dir=./xapp1151_cam_v1_1/src

file_list=`find $cam_dir -name *.vhd`

for in_file in $file_list; do

   sed -i -e 's/LIBRARY cam/LIBRARY xil_defaultlib/' $in_file
   sed -i -e 's/ENTITY cam\./ENTITY xil_defaultlib\./' $in_file
   sed -i -e 's/USE cam\./USE xil_defaultlib\./' $in_file
done

sed -i '/virtex6l/a CONSTANT VIRTEX7               : STRING := "virtex7";' $cam_dir/vhdl/cam_pkg.vhd
sed -i -e 's/spartan6)/spartan6) OR (C_FAMILY = virtex7)/' $cam_dir/vhdl/cam_rtl.vhd
sed -i -e 's/or spartan6/spartan6, or virtex7/' $cam_dir/vhdl/cam_rtl.vhd
