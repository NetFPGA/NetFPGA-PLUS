#
# Copyright (c) 2015 University of Cambridge All rights reserved.
#
# This software was developed by the University of Cambridge Computer
# Laboratory under EPSRC INTERNET Project EP/H040536/1, National Science
# Foundation under Grant No. CNS-0855268, and Defense Advanced Research
# Projects Agency (DARPA) and Air Force Research Laboratory (AFRL), under
# contract FA8750-11-C-0249.
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed to NetFPGA Open Systems C.I.C. (NetFPGA) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  NetFPGA
# licenses this file to you under the NetFPGA Hardware-Software License,
# Version 1.0 (the "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at:
#
#   http://www.netfpga-cic.org
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@

rm -rf *.log .Xil* *.jou xsim* *.wdb

xvlog -d 32d -work work ./sim/testbench.v

xvlog -work work ./hdl/verilog/tcam.v
xvlog -work work ./hdl/verilog/tcam_wrapper.v

xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_init_file_pack_xst.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_pkg.vhd

xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_input_ternary_ternenc.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_input_ternary.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_input.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_control.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_decoder.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_match_enc.vhd

xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_regouts.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_mem_srl16_ternwrcomp.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_mem_srl16_wrcomp.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_mem_srl16_block_word.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_mem_srl16_block.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_mem_srl16.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_mem_blk_extdepth_prim.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_mem_blk_extdepth.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/dmem.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_mem_blk.vhd

xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_mem.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_rtl.vhd
xvhdl -work xil_defaultlib ./hdl/vhdl/tcam/cam_top.vhd

xelab -L unisms_ver -L xil_defaultlib testbench -s testbench -debug all

xsim testbench -tclbatch ./sim/run_sim.tcl
