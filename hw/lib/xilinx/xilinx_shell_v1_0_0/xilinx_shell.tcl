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

# Vivado Launch Script
#### Change design settings here #######
set design xilinx_shell
set top open_nic_shell
set device $::env(DEVICE)
set board $::env(BOARD)
set board_name $::env(BOARD_NAME)
set proj_dir ./ip_proj
set ip_version 1.0
set lib_name xilinx
set proj ./proj
set_param board.repoPaths $::env(BOARD_FILE_PATH)
#####################################
# Project Settings
#####################################
create_project -name ${design} -force -dir "./${proj_dir}" -part ${device} -ip
set_property BOARD_PART $board [current_project]
set_property source_mgmt_mode All [current_project]  
set_property top ${top} [current_fileset]
set_property ip_repo_paths $::env(NFPLUS_FOLDER)/hw/lib/  [current_fileset]
if {[string match $board_name "au280"]} {
	set_property verilog_define { {__synthesis__} {__au280__}} [current_fileset]
} elseif {[string match $board_name "au250"]} {
	set_property verilog_define { {__synthesis__} {__au250__}} [current_fileset]
} elseif {[string match $board_name "au200"]} {
	set_property verilog_define { {__synthesis__} {__au200__}} [current_fileset]
} elseif {[string match $board_name "vcu1525"]} {
	set_property verilog_define { {__synthesis__} {__au200__}} [current_fileset]
} else {
	puts "Error: ${board_name} is not found."
	exit -1
}
puts "Creating Xiilnx Xilinx OpenNIC Shell IP"
#####################################
# Design Parameters
#####################################
set num_qdma      1
set num_phys_func 2
set num_queue     2048
set min_pkt_len   64
set max_pkt_len   1518
#####################################
# Project Structure & IP Build
#####################################
read_verilog -sv "./hdl/open_nic_shell.sv"

read_verilog     "open-nic-shell/src/open_nic_shell_macros.vh"
read_verilog     "open-nic-shell/src/cmac_subsystem/cmac_subsystem_address_map.v"
read_verilog -sv "open-nic-shell/src/cmac_subsystem/cmac_subsystem_cmac_wrapper.sv"
read_verilog -sv "open-nic-shell/src/cmac_subsystem/cmac_subsystem.sv"
read_verilog -sv "open-nic-shell/src/qdma_subsystem/qdma_subsystem_address_map.sv"
read_verilog -sv "open-nic-shell/src/qdma_subsystem/qdma_subsystem_c2h.sv"
read_verilog -sv "open-nic-shell/src/qdma_subsystem/qdma_subsystem_function_register.sv"
read_verilog -sv "open-nic-shell/src/qdma_subsystem/qdma_subsystem_function.sv"
read_verilog -sv "open-nic-shell/src/qdma_subsystem/qdma_subsystem_h2c.sv"
read_verilog -sv "open-nic-shell/src/qdma_subsystem/qdma_subsystem_hash.sv"
read_verilog     "open-nic-shell/src/qdma_subsystem/qdma_subsystem_qdma_wrapper.v"
read_verilog -sv "open-nic-shell/src/qdma_subsystem/qdma_subsystem_register.sv"
read_verilog -sv "open-nic-shell/src/qdma_subsystem/qdma_subsystem.sv"
read_verilog -sv "open-nic-shell/src/system_config/cms_subsystem.sv"
read_verilog -sv "open-nic-shell/src/system_config/system_config_address_map.sv"
read_verilog     "open-nic-shell/src/system_config/system_config_register.v"
read_verilog -sv "open-nic-shell/src/system_config/system_config.sv"
read_verilog -sv "open-nic-shell/src/utility/axi_lite_register.sv"
read_verilog -sv "open-nic-shell/src/utility/axi_lite_slave.sv"
read_verilog -sv "open-nic-shell/src/utility/axi_stream_packet_buffer.sv"
read_verilog -sv "open-nic-shell/src/utility/axi_stream_packet_fifo.sv"
read_verilog -sv "open-nic-shell/src/utility/axi_stream_register_slice.sv"
read_verilog -sv "open-nic-shell/src/utility/axi_stream_size_counter.sv"
read_verilog     "open-nic-shell/src/utility/crc32.v"
read_verilog -sv "open-nic-shell/src/utility/generic_reset.sv"
read_verilog -sv "open-nic-shell/src/utility/level_trigger_cdc.sv"
read_verilog -sv "open-nic-shell/src/utility/rr_arbiter.sv"

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
ipx::package_project

if {[file exists ${proj}]} {
	file delete -force ${proj}
	file mkdir ${proj}
} else {
	file mkdir ${proj}
}

set ip_build_dir ${proj}

if {[string match $board_name "au280"]} {
	source "open-nic-shell/src/cmac_subsystem/vivado_ip/cmac_usplus_0_au280.tcl"
} elseif {[string match $board_name "au250"]} {
	source "vivado_ip/cmac_usplus_0_au250.tcl"
} elseif {[string match $board_name "au200"]} {
	source "vivado_ip/cmac_usplus_0_au250.tcl"
} elseif {[string match $board_name "vcu1525"]} {
	source "vivado_ip/cmac_usplus_0_vcu1525.tcl"
}
generate_target {instantiation_template} [get_files ./${proj}/${cmac_usplus}/${cmac_usplus}.xci]
generate_target all [get_files ./${proj}/${cmac_usplus}/${cmac_usplus}.xci]
ipx::package_project -force -import_files ./${proj}/${cmac_usplus}/${cmac_usplus}.xci

if {[string match $board_name "au280"]} {
	source "open-nic-shell/src/cmac_subsystem/vivado_ip/cmac_usplus_1_au280.tcl"
} elseif {[string match $board_name "au250"]} {
	source "vivado_ip/cmac_usplus_1_au250.tcl"
} elseif {[string match $board_name "au200"]} {
	source "vivado_ip/cmac_usplus_1_au250.tcl"
} elseif {[string match $board_name "vcu1525"]} {
	source "vivado_ip/cmac_usplus_1_vcu1525.tcl"
}
generate_target {instantiation_template} [get_files ./${proj}/${cmac_usplus}/${cmac_usplus}.xci]
generate_target all [get_files ./${proj}/${cmac_usplus}/${cmac_usplus}.xci]
ipx::package_project -force -import_files ./${proj}/${cmac_usplus}/${cmac_usplus}.xci

source "open-nic-shell/src/cmac_subsystem/vivado_ip/cmac_subsystem_axi_crossbar.tcl"
generate_target {instantiation_template} [get_files ./${proj}/${axi_crossbar}/${axi_crossbar}.xci]
generate_target all [get_files ./${proj}/${axi_crossbar}/${axi_crossbar}.xci]
ipx::package_project -force -import_files ./${proj}/${axi_crossbar}/${axi_crossbar}.xci

#source "vivado_ip/qdma_subsystem_axi_cdc.tcl"
source "open-nic-shell/src/qdma_subsystem/vivado_ip/qdma_subsystem_axi_cdc.tcl"
generate_target {instantiation_template} [get_files ./${proj}/${axi_clock_converter}/${axi_clock_converter}.xci]
generate_target all [get_files ./${proj}/${axi_clock_converter}/${axi_clock_converter}.xci]
ipx::package_project -force -import_files ./${proj}/${axi_clock_converter}/${axi_clock_converter}.xci

source "open-nic-shell/src/qdma_subsystem/vivado_ip/qdma_subsystem_axi_crossbar.tcl"
generate_target {instantiation_template} [get_files ./${proj}/${axi_crossbar}/${axi_crossbar}.xci]
generate_target all [get_files ./${proj}/${axi_crossbar}/${axi_crossbar}.xci]
ipx::package_project -force -import_files ./${proj}/${axi_crossbar}/${axi_crossbar}.xci

#source "vivado_ip/qdma_subsystem_clk_div.tcl"
source "open-nic-shell/src/qdma_subsystem/vivado_ip/qdma_subsystem_clk_div.tcl"
generate_target {instantiation_template} [get_files ./${proj}/${clk_wiz}/${clk_wiz}.xci]
generate_target all [get_files ./${proj}/${clk_wiz}/${clk_wiz}.xci]
ipx::package_project -force -import_files ./${proj}/${clk_wiz}/${clk_wiz}.xci

source "open-nic-shell/src/qdma_subsystem/vivado_ip/qdma_subsystem_c2h_ecc.tcl"
generate_target {instantiation_template} [get_files ./${proj}/${ecc}/${ecc}.xci]
generate_target all [get_files ./${proj}/${ecc}/${ecc}.xci]
ipx::package_project -force -import_files ./${proj}/${ecc}/${ecc}.xci

if {[string match $board_name "au280"]} {
	source "open-nic-shell/src/qdma_subsystem/vivado_ip/qdma_no_sriov_au280.tcl"
} elseif {[string match $board_name "au250"]} {
	source "open-nic-shell/src/qdma_subsystem/vivado_ip/qdma_no_sriov_au250.tcl"
} elseif {[string match $board_name "au200"]} {
	source "vivado_ip/qdma_no_sriov_au200.tcl"
} elseif {[string match $board_name "vcu1525"]} {
	source "vivado_ip/qdma_no_sriov_vcu1525.tcl"
}
generate_target {instantiation_template} [get_files ./${proj}/${qdma}/${qdma}.xci]
generate_target all [get_files ./${proj}/${qdma}/${qdma}.xci]
ipx::package_project -force -import_files ./${proj}/${qdma}/${qdma}.xci

source "open-nic-shell/src/system_config/vivado_ip/system_config_axi_crossbar.tcl"
generate_target {instantiation_template} [get_files ./${proj}/${axi_crossbar}/${axi_crossbar}.xci]
generate_target all [get_files ./${proj}/${axi_crossbar}/${axi_crossbar}.xci]
ipx::package_project -force -import_files ./${proj}/${axi_crossbar}/${axi_crossbar}.xci

source "open-nic-shell/src/system_config/vivado_ip/system_management_wiz.tcl"
generate_target {instantiation_template} [get_files ./${proj}/${system_management_wiz}/${system_management_wiz}.xci]
generate_target all [get_files ./${proj}/${system_management_wiz}/${system_management_wiz}.xci]
ipx::package_project -force -import_files ./${proj}/${system_management_wiz}/${system_management_wiz}.xci

source "open-nic-shell/src/system_config/vivado_ip/clk_wiz_50Mhz.tcl"
generate_target {instantiation_template} [get_files ./${proj}/${clk_wiz_50Mhz}/${clk_wiz_50Mhz}.xci]
generate_target all [get_files ./${proj}/${clk_wiz_50Mhz}/${clk_wiz_50Mhz}.xci]
ipx::package_project -force -import_files ./${proj}/${clk_wiz_50Mhz}/${clk_wiz_50Mhz}.xci

source "open-nic-shell/src/system_config/vivado_ip/axi_quad_spi_0.tcl"
generate_target {instantiation_template} [get_files ./${proj}/${axi_quad_spi}/${axi_quad_spi}.xci]
generate_target all [get_files ./${proj}/${axi_quad_spi}/${axi_quad_spi}.xci]
ipx::package_project -force -import_files ./${proj}/${axi_quad_spi}/${axi_quad_spi}.xci

source "open-nic-shell/src/system_config/vivado_ip/cms_subsystem_0.tcl"
generate_target {instantiation_template} [get_files ./${proj}/${cms_subsystem}/${cms_subsystem}.xci]
generate_target all [get_files ./${proj}/${cms_subsystem}/${cms_subsystem}.xci]
ipx::package_project -force -import_files ./${proj}/${cms_subsystem}/${cms_subsystem}.xci

source "open-nic-shell/src/system_config/vivado_ip/system_config_axi_clock_converter.tcl"
generate_target {instantiation_template} [get_files ./${proj}/${axi_clock_converter}/${axi_clock_converter}.xci]
generate_target all [get_files ./${proj}/${axi_clock_converter}/${axi_clock_converter}.xci]
ipx::package_project -force -import_files ./${proj}/${axi_clock_converter}/${axi_clock_converter}.xci

source "open-nic-shell/src/utility/vivado_ip/axi_lite_clock_converter.tcl"
generate_target {instantiation_template} [get_files ./${proj}/${axi_clock_converter}/${axi_clock_converter}.xci]
generate_target all [get_files ./${proj}/${axi_clock_converter}/${axi_clock_converter}.xci]
ipx::package_project -force -import_files ./${proj}/${axi_clock_converter}/${axi_clock_converter}.xci

update_ip_catalog -rebuild
ipx::infer_user_parameters [ipx::current_core]

set_property name ${design} [ipx::current_core]
set_property library ${lib_name} [ipx::current_core]
set_property vendor_display_name {xilinx} [ipx::current_core]
set_property company_url {http://www.xilinx.com} [ipx::current_core]
set_property vendor {xilinx} [ipx::current_core]
set_property supported_families {{virtexuplus} {Production} {virtexuplushbm} {Production}} [ipx::current_core]
set_property taxonomy {{/NetFPGA/Generic}} [ipx::current_core]
set_property version ${ip_version} [ipx::current_core]
set_property display_name ${design} [ipx::current_core]
set_property description ${design} [ipx::current_core]

ipx::infer_user_parameters [ipx::current_core]

ipx::add_user_parameter {MAX_PKT_LEN} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters MAX_PKT_LEN]
set_property display_name {MAX_PKT_LEN} [ipx::get_user_parameters MAX_PKT_LEN]
set_property value {1518} [ipx::get_user_parameters MAX_PKT_LEN]
set_property value_format {bitstring} [ipx::get_user_parameters MAX_PKT_LEN]

ipx::add_user_parameter {MIN_PKT_LEN} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters MIN_PKT_LEN]
set_property display_name {MIN_PKT_LEN} [ipx::get_user_parameters MIN_PKT_LEN]
set_property value {64} [ipx::get_user_parameters MIN_PKT_LEN]
set_property value_format {bitstring} [ipx::get_user_parameters MIN_PKT_LEN]

ipx::add_user_parameter {NUM_QUEUE} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters NUM_QUEUE]
set_property display_name {NUM_QUEUE} [ipx::get_user_parameters NUM_QUEUE]
set_property value {2048} [ipx::get_user_parameters NUM_QUEUE]
set_property value_format {bitstring} [ipx::get_user_parameters NUM_QUEUE]

ipx::add_user_parameter {NUM_PHYS_FUNC} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters NUM_PHYS_FUNC]
set_property display_name {NUM_PHYS_FUNC} [ipx::get_user_parameters NUM_PHYS_FUNC]
set_property value {2} [ipx::get_user_parameters NUM_PHYS_FUNC]
set_property value_format {bitstring} [ipx::get_user_parameters NUM_PHYS_FUNC]

ipx::add_user_parameter {NUM_CMAC_PORT} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters NUM_CMAC_PORT]
set_property display_name {NUM_CMAC_PORT} [ipx::get_user_parameters NUM_CMAC_PORT]
set_property value {2} [ipx::get_user_parameters NUM_CMAC_PORT]
set_property value_format {bitstring} [ipx::get_user_parameters NUM_CMAC_PORT]

ipx::add_user_parameter {USE_PHYS_FUNC} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters USE_PHYS_FUNC]
set_property display_name {USE_PHYS_FUNC} [ipx::get_user_parameters USE_PHYS_FUNC]
set_property value {1} [ipx::get_user_parameters USE_PHYS_FUNC]
set_property value_format {bitstring} [ipx::get_user_parameters USE_PHYS_FUNC]

ipx::infer_user_parameters [ipx::current_core]

ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]
update_ip_catalog
close_project
