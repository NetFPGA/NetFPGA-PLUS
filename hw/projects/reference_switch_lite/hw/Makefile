################################################################################
# Copyright (c) 2021 University of Cambridge
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
################################################################################
PROJ = ${NF_PROJECT_NAME}

all: project

project: 
	echo "Create reference project under folder /project";
	@if test -d project/; then \
		echo "Project already exists"; \
	else \
		vivado -mode batch -source tcl/${PROJ}.tcl; \
	fi

projectgui:
	echo "Create reference project under folder /project";
	@if test -d project/; then \
		echo "Project already exists"; \
	else \
		vivado -mode gui -source tcl/${PROJ}.tcl; \
	fi

sim:	simclean
	cp -f $(NF_DESIGN_DIR)/test/reg_defines_${NF_PROJECT_NAME}.py $(NF_DESIGN_DIR)/test/${TESTNAME}/reg_defines_${NF_PROJECT_NAME}.py
	vivado -mode batch -source ../../../projects/${PROJ}/hw/tcl/${NF_PROJECT_NAME}_sim.tcl -tclargs ${TESTNAME}
	$(NFPLUS_FOLDER)/tools/scripts/nf_sim_reconcile_axi_logs.py
	$(NFPLUS_FOLDER)/tools/scripts/nf_sim_registers_axi_logs.py

reg:
	vivado -mode batch -source $(NF_DESIGN_DIR)/hw/tcl/export_registers.tcl
	cd ../test  && cp ../../../../tools/scripts/xparam2regdefines.py . && python xparam2regdefines.py
	cd ../test  && rm -f xparam2regdefines.py 
	cd ../test && cp ../../../../tools/scripts/python_parser.py . && python python_parser.py
	cd ../test && rm -f python_parser.py && mv reg_defines.py reg_defines_${NF_PROJECT_NAME}.py

simgui: simclean 
	cp -f $(NF_DESIGN_DIR)/test/reg_defines_$(NF_PROJECT_NAME).py $(NF_DESIGN_DIR)/test/${TESTNAME}/reg_defines_$(NF_PROJECT_NAME).py
	vivado -mode gui -source ../../../projects/${PROJ}/hw/tcl/$(NF_PROJECT_NAME)_sim.tcl -tclargs ${TESTNAME}
	$(NFPLUS_FOLDER)/tools/scripts/nf_sim_reconcile_axi_logs.py
	$(NFPLUS_FOLDER)/tools/scripts/nf_sim_registers_axi_logs.py

simclean:
	rm -rf proj_* vivado*.* *.*~ .Xil* $(NF_DESIGN_DIR)/hw/ip_repo/ $(NF_DESIGN_DIR)/hw/project/
	rm -rf *[0-9]_{stim,expected,log}.axi
	rm -f *.axi
	rm -f portconfig.sim
	rm -f seed
	rm -f *.log
	rm -f ../test/Makefile
	rm -rf ../test/*.log
	rm -rf ../test/*.axi
	rm -rf ../test/seed
	rm -rf ../test/*.sim
	rm -rf ../test/proj_*
	rm -rf ../test/ip_repo
	rm -f ../test/vivado*.*
	rm -f ../test/*_*_*/reg_defines_${NF_PROJECT_NAME}.py
	rm -f ../test/*_*_*/reg_defines_${NF_PROJECT_NAME}.pyc


clean:
	rm -rf project
	rm -f vivado*
	rm -rf ip_repo
