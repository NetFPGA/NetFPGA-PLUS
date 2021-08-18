#
# Copyright (c) 2021 University of Cambridge
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
OUTFILE   := au280_timing.tcl au250_timing.tcl

all: $(OUTFILE)

au250_timing.tcl:
	sed -e 's/pcie_refclk_p/pci_clk_p/g' -e 's/pcie_rstn/pci_rst_n/g' \
	    -e 's/\[get_nets cmac_clk/\[get_nets u_top_wrapper\/cmac_clk/g' \
	    -e 's/create_pbloc/#create_pbloc/g' \
	    -e 's/add_cells_to_pblock/#add_cells_to_pblock/g' \
	    -e 's/resize_pblock/#resize_pblock/g' \
	    ../../xilinx/xilinx_shell_v1_0_0/open-nic-shell/constr/au250/timing.xdc > au250_timing.tcl

au280_timing.tcl:
	sed -e 's/pcie_refclk_p/pci_clk_p/g' -e 's/pcie_rstn/pci_rst_n/g' \
	    -e 's/\[get_nets cmac_clk/\[get_nets u_top_wrapper\/cmac_clk/g' \
	    -e 's/cmac_port/u_top_wrapper\/xilinx_nic_shell\/inst\/cmac_port/g' \
	    -e 's/qdma_subsystem_inst/u_top_wrapper\/xilinx_nic_shell\/inst\/qdma_subsystem_inst/g' \
	    -e 's/create_pblock pblock_packet_adapter/#create_pblock pblock_packet_adapter/g' \
	    -e 's/add_cells_to_pblock \[get_pblocks pblock_packet/#add_cells_to_pblock \[get_pblocks pblock_packet/g' \
	    -e 's/resize_pblock \[get_pblocks pblock_packe/#resize_pblock \[get_pblocks pblock_packe/g' \
	    -e '/box/d' \
	    ../../xilinx/xilinx_shell_v1_0_0/open-nic-shell/constr/au280/timing.xdc > au280_timing.tcl
	cat nf_timing.tcl >> au280_timing.tcl

clean:
	rm -rf $(OUTFILE)
