#
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
#  File:
#        Makefile
#
#  Project:
#        Makes all the cores of NetFPGA library
#
#  Description:
#        This makefile is used to generate and compile SDK project for NetFPGA reference projects.
#        The first argument is target

SCRIPTS_DIR	= tools/
LIB_REPO	= hw/lib/ip_repo
LIB_HW_DIR	= hw/lib
LIB_SW_DIR	= sw
LIB_HW_DIR_INSTANCES := $(shell cd $(LIB_HW_DIR) && find . -maxdepth 4 -type d)
LIB_HW_DIR_INSTANCES := $(basename $(patsubst ./%,%,$(LIB_HW_DIR_INSTANCES)))
LIB_SW_DIR_INSTANCES := $(shell cd $(LIB_SW_DIR) && find . -maxdepth 4 -type d)
LIB_SW_DIR_INSTANCES := $(basename $(patsubst ./%,%,$(LIB_SW_DIR_INSTANCES)))

TOOLS_DIR = tools
TOOLS_DIR_INSTANCES := $(shell cd $(TOOLS_DIR) && find . -maxdepth 3 -type d)
TOOLS_DIR_INSTANCES := $(basename $(patsubst ./%,%,$(TOOLS_DIR_INSTANCES)))

PROJECTS_DIR = hw/projects
PROJECTS_DIR_INSTANCES := $(shell cd $(PROJECTS_DIR) && find . -maxdepth 1 -type d)
PROJECTS_DIR_INSTANCES := $(basename $(patsubst ./%,%,$(PROJECTS_DIR_INSTANCES)))

CONTRIBPROJECTS_DIR = hw/contrib-projects
CONTRIBPROJECTS_DIR_INSTANCES := $(shell cd $(CONTRIBPROJECTS_DIR) && find . -maxdepth 1 -type d)
CONTRIBPROJECTS_DIR_INSTANCES := $(basename $(patsubst ./%,%,$(CONTRIBPROJECTS_DIR_INSTANCES)))

RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(RUN_ARGS):;@:)


all:	clean cores hwtestlib

clean: libclean toolsclean projectsclean swclean
	@rm -rfv *.*~
	@rm -rfv ip_proj
	@rm -rfv ip_user_files
	@find . -type f -name '*.pyc' -delete
	@find . -type f -name '*.jou' -delete
	@find . -type f -name '*.log' -delete
	@find . -type f -name '*.coe' -delete
	@find . -type f -name '*.mif' -delete

cores:
	make -C $(LIB_HW_DIR)/xilinx/cam_v1_1_0/
	make -C $(LIB_HW_DIR)/xilinx/tcam_v1_1_0/
	make -C $(LIB_HW_DIR)/xilinx/xilinx_shell_v1_0_0/
	make -C $(LIB_HW_DIR)/std/fallthrough_small_fifo_v1_0_0/
	make -C $(LIB_HW_DIR)/contrib/nf_endianess_manager_v1_0_0/
	make -C $(LIB_HW_DIR)/std/axis_fifo_v1_0_0/
	make -C $(LIB_HW_DIR)/std/nf_axis_converter_v1_0_0/
	make -C $(LIB_HW_DIR)/std/nf_mac_attachment_v1_0_0/
	make -C $(LIB_HW_DIR)/std/input_arbiter_v1_0_0/
	make -C $(LIB_HW_DIR)/std/output_queues_v1_0_0/
	make -C $(LIB_HW_DIR)/std/switch_output_port_lookup_v1_0_1/
	make -C $(LIB_HW_DIR)/std/nic_output_port_lookup_v1_0_0/
	make -C $(LIB_HW_DIR)/std/switch_lite_output_port_lookup_v1_0_0/
	make -C $(LIB_HW_DIR)/std/router_output_port_lookup_v1_0_0/
	make -C $(LIB_HW_DIR)/std/barrier_v1_0_0/
	make -C $(LIB_HW_DIR)/std/axi_sim_transactor_v1_0_0/
	make -C $(LIB_HW_DIR)/std/axis_sim_record_v1_0_0/
	make -C $(LIB_HW_DIR)/std/axis_sim_stim_v1_0_0/
	@echo "/////////////////////////////////////////";
	@echo "//\tLibrary cores created.";
	@echo "/////////////////////////////////////////";


libclean:
	@rm -rf $(LIB_REPO)
	@for lib in $(LIB_HW_DIR_INSTANCES) ; do \
		if test -f $(LIB_HW_DIR)/$$lib/Makefile; then \
			$(MAKE) -C $(LIB_HW_DIR)/$$lib clean; \
		fi; \
	done;
	@echo "/////////////////////////////////////////";
	@echo "//\tLibrary cores cleaned.";
	@echo "/////////////////////////////////////////";


toolsclean:
	@if test -f $(TOOLS_DIR)/Makefile; then \
		$(MAKE) -C $(TOOLS_DIR) clean; \
	fi;
	@echo "/////////////////////////////////////////";
	@echo "//\tTools cleaned.";
	@echo "/////////////////////////////////////////";


projectsclean:
	@for lib in $(PROJECTS_DIR_INSTANCES) ; do \
		if test -f $(PROJECTS_DIR)/$$lib/Makefile; then \
			$(MAKE) -C $(PROJECTS_DIR)/$$lib/ clean; \
		fi; \
	done;
	@echo "/////////////////////////////////////////";
	@echo "//\tProjects cleaned.";
	@echo "/////////////////////////////////////////";


contribprojectsclean:
	@for lib in $(CONTRIBPROJECTS_DIR_INSTANCES) ; do \
		if test -f $(CONTRIBPROJECTS_DIR)/$$lib/Makefile; then \
			$(MAKE) -C $(CONTRIBPROJECTS_DIR)/$$lib/ clean; \
		fi; \
	done;
	@echo "/////////////////////////////////////////";
	@echo "//\tContrib-projects cleaned.";
	@echo "/////////////////////////////////////////";

contribprojects:
	@for lib in $(CONTRIBPROJECTS_DIR_INSTANCES) ; do \
		if test -f $(CONTRIBPROJECTS_DIR)/$$lib/Makefile; then \
			$(MAKE) -C $(CONTRIBPROJECTS_DIR)/$$lib/; \
		fi; \
	done;
	@echo "/////////////////////////////////////////";
	@echo "//\tContrib-projects created.";
	@echo "/////////////////////////////////////////";


hwtestlib:
	$(MAKE) -C sw/hwtestlib
	@echo "/////////////////////////////////////////";
	@echo "//\tHW test Library created.";
	@echo "/////////////////////////////////////////";


hwtestlibclean:
	$(MAKE) -C sw/hwtestlib clean
	@echo "/////////////////////////////////////////";
	@echo "//\tHW test Library cleaned.";
	@echo "/////////////////////////////////////////";

swclean:
	@for swlib in $(LIB_SW_DIR_INSTANCES) ; do \
		if test -f $(LIB_SW_DIR)/$$swlib/Makefile; then \
			$(MAKE) -C $(LIB_SW_DIR)/$$swlib clean; \
		fi; \
	done;
	@echo "/////////////////////////////////////////";
	@echo "//\tSW Library cleaned.";
	@echo "/////////////////////////////////////////";

