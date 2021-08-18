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
#
.PHONY: all
.PHONY: update
.PHONY: sim

all: clean
	vivado -mode tcl -source tcam.tcl 

update:
	unzip xapp1151_Param_CAM.zip
	bash ./scripts/run_update_lib.sh
	cp -f ./xapp1151_cam_v1_1/src/vhdl/*.vhd ./hdl/vhdl/tcam/

sim:
	bash ./sim/run_tcam_sim.sh	

clean:
	rm -rf vivado*.* *.xml xgui/ .Xil* ip_pro* xv* *.wdb xsim* xe* we*
