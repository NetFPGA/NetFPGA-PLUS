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

PATCH_FILE := opennic-driver.patch
OUTFILE    := .updated.txt
GITOUTFILE := .git_updated
DRIVER_DIR := open-nic-driver

all: fetch patch driver

.PHONY: fetch patch driver
patch: $(OUTFILE)
$(OUTFILE):
	patch -d $(DRIVER_DIR) < $(PATCH_FILE) > $(OUTFILE)

fetch: $(GITOUTFILE)
$(GITOUTFILE):
	touch $(GITOUTFILE)
	git submodule update --init $(DRIVER_DIR)

driver:
	cd $(DRIVER_DIR) && $(MAKE)

clean:
	$(MAKE) -C $(DRIVER_DIR) clean
