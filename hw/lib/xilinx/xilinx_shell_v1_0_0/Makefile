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

all: update clean
	sed -i -e "s/parameter int NUM_PHYS_FUNC = 1/parameter int NUM_PHYS_FUNC = 2/g" hdl/open_nic_shell.sv
	sed -i -e "s/parameter int NUM_CMAC_PORT = 1/parameter int NUM_CMAC_PORT = 2/g" hdl/open_nic_shell.sv
	vivado -mode batch -source xilinx_shell.tcl

update:
	bash update.sh

clean:
	rm -rf ip_*  vivado*.* *.xml xgui/ .Xil* *.*~ *.zip proj

