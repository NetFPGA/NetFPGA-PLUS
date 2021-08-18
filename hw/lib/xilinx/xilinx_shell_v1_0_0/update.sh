#!/bin/bash
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

ip_dir="vivado_ip"
cmac_dir="open-nic-shell/src/cmac_subsystem/vivado_ip/"
qdma_dir="open-nic-shell/src/qdma_subsystem/vivado_ip/"

if [ ! -d "${cmac_dir}" ] || [ ! -d "${qdma_dir}" ]; then
	git submodule update --init open-nic-shell
fi

if [ ! -f "${ip_dir}/cmac_usplus_0_au250.tcl" ]; then
	sed -e "s/CONFIG.GT_REF_CLK_FREQ {156.25}/CONFIG.GT_REF_CLK_FREQ {161.1328125}/g" \
	    -e "s/CONFIG.DIFFCLK_BOARD_INTERFACE {qsfp0_156mhz}/CONFIG.DIFFCLK_BOARD_INTERFACE {qsfp0_161mhz}/g" \
	    ${cmac_dir}/cmac_usplus_0_au250.tcl > ${ip_dir}/cmac_usplus_0_au250.tcl
fi
if [ ! -f "${ip_dir}/cmac_usplus_1_au250.tcl" ]; then
	sed -e "s/CONFIG.GT_REF_CLK_FREQ {156.25}/CONFIG.GT_REF_CLK_FREQ {161.1328125}/g" \
	    -e "s/CONFIG.DIFFCLK_BOARD_INTERFACE {qsfp1_156mhz}/CONFIG.DIFFCLK_BOARD_INTERFACE {qsfp1_161mhz}/g" \
	    ${cmac_dir}/cmac_usplus_1_au250.tcl > ${ip_dir}/cmac_usplus_1_au250.tcl
fi
if [ ! -f "${ip_dir}/cmac_usplus_0_vcu1525.tcl" ]; then
	sed -e 's/156.25/161.1328125/' -e 's/CMACE4_X0Y6/CMACE4_X0Y7/' \
		-e 's/X0Y40~X0Y43/X1Y44~X1Y47/' -e 's/X0Y40/X1Y44/' \
		-e 's/X0Y41/X1Y45/' -e 's/X0Y42/X1Y46/'  -e 's/X0Y43/X1Y47/' \
		-e 's/RX_GT_BUFFER {1}/RX_GT_BUFFER {NA}/' \
		-e 's/GT_RX_BUFFER_BYPASS {0}/GT_RX_BUFFER_BYPASS {NA}/' \
		-e '/ETHERNET_BOARD/d' -e '/DIFFCLK_BOARD/d' \
		${cmac_dir}/cmac_usplus_0_au280.tcl > ${ip_dir}/cmac_usplus_0_vcu1525.tcl
fi
if [ ! -f "${ip_dir}/cmac_usplus_1_vcu1525.tcl" ]; then
	sed -e 's/156.25/161.1328125/' -e 's/CMACE4_X0Y7/CMACE4_X0Y8/' \
		-e 's/X0Y44~X0Y47/X1Y48~X1Y51/' -e 's/X0Y40/X1Y48/' \
		-e 's/X0Y41/X1Y49/' -e 's/X0Y42/X1Y50/'  -e 's/X0Y43/X1Y51/' \
		-e 's/RX_GT_BUFFER {1}/RX_GT_BUFFER {NA}/' \
		-e 's/GT_RX_BUFFER_BYPASS {0}/GT_RX_BUFFER_BYPASS {NA}/' \
		-e '/ETHERNET_BOARD/d' -e '/DIFFCLK_BOARD/d' \
		${cmac_dir}/cmac_usplus_1_au280.tcl > ${ip_dir}/cmac_usplus_1_vcu1525.tcl
fi
if [ ! -f "${ip_dir}/qdma_no_sriov_au200.tcl " ]; then
	sed -e 's/AU280/AU200/g' ${qdma_dir}/qdma_no_sriov_au280.tcl > ${ip_dir}/qdma_no_sriov_au200.tcl
fi
if [ ! -f "${ip_dir}/qdma_no_sriov_au200.tcl " ]; then
	sed -e 's/AU280/VCU1525/g' ${qdma_dir}/qdma_no_sriov_au280.tcl > ${ip_dir}/qdma_no_sriov_vcu1525.tcl
fi

