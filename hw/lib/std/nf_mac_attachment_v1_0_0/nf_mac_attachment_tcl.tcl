# 
# Copyright (c) 2015 Yury Audzevich
# Modified by Salvator Galea
# All rights reserved.
# 
# This software was developed by
# Stanford University and the University of Cambridge Computer Laboratory
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
set device          $::env(DEVICE)
set ip_name 		{nf_mac_attachment}
set lib_name 		{NetFPGA}
set vendor_name 	{NetFPGA}
set ip_display_name 	{nf_mac_attachment}
set ip_description 	{10G Ethernet attachment for NetFPGA NFPLUS}
set vendor_display_name {NetFPGA}
set vendor_company_url 	{http://www.netfpga.org}
set ip_version 		{1.0}


## Other 
set proj_dir 		./ip_proj


## # of added files
set_param project.singleFileAddWarning.Threshold 500


### SubCore Reference
set subcore_names {\
		nf_axis_converter\
		fallthrough_small_fifo\
}

### Source Files List
# Here for all directory
set source_dir { \
		hdl\
}

## quick way, there is a cleaner way
set VerilogFiles [list]
set VerilogFiles [concat \
			[glob -nocomplain hdl]]

set rtl_dirs	[list]
set rtl_dirs	[concat \
			hdl]


# Top Module Name
set top_module_name {nf_mac_attachment}
set top_module_file ./hdl/$top_module_name.v

puts "top_file: $top_module_file \n"

# Inferred Bus Interface
set bus_interfaces {\
	xilinx.com:signal:clock:1.0\
	xilinx.com:signal:reset:1.0\	
	xilinx.com:interface:axis_rtl:1.0\
}

#############################################
# Create Project
#############################################
create_project -name ${ip_name} -force -dir "./${proj_dir}" -part ${device} 
set_property source_mgmt_mode All [current_project] 
set_property top $top_module_name [current_fileset]

# local IP repo
set_property ip_repo_paths $::env(NFPLUS_FOLDER)/hw/lib  [current_fileset]
update_ip_catalog

# include dirs
foreach rtl_dir $rtl_dirs {
        set_property include_dirs $rtl_dirs [current_fileset]
}


# Add verilog sources here
# Add Verilog Files to The IP Core
foreach verilog_file $VerilogFiles {
	add_files -norecurse ${verilog_file}
}
#read_verilog $VerilogFiles

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_generator_1_9 -dir ./${proj_dir}
set_property -dict [list \
	CONFIG.Component_Name {fifo_generator_1_9} \
	CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM} \
	CONFIG.Performance_Options {First_Word_Fall_Through} \
	CONFIG.Input_Data_Width {1} \
	CONFIG.Input_Depth {16} \
	CONFIG.Output_Data_Width {1} \
	CONFIG.Output_Depth {16} \
	CONFIG.Reset_Type {Asynchronous_Reset} \
	CONFIG.Full_Flags_Reset_Value {1} \
	CONFIG.Data_Count_Width {4} \
	CONFIG.Write_Data_Count_Width {4} \
	CONFIG.Read_Data_Count_Width {4} \
	CONFIG.Full_Threshold_Assert_Value {15} \
	CONFIG.Full_Threshold_Negate_Value {14} \
	CONFIG.Empty_Threshold_Assert_Value {4} \
	CONFIG.Empty_Threshold_Negate_Value {5} \
	CONFIG.Enable_Safety_Circuit {true}] [get_ips fifo_generator_1_9]
generate_target {instantiation_template} [get_files ./${proj_dir}/fifo_generator_1_9/fifo_generator_1_9.xci]
generate_target all [get_files  ./${proj_dir}/fifo_generator_1_9/fifo_generator_1_9.xci]
ipx::package_project -force -import_files ./${proj_dir}/fifo_generator_1_9/fifo_generator_1_9.xci

## without fifo
ipx::package_project

# Create IP Information
set_property name 			${ip_name} [ipx::current_core]
set_property library 			${lib_name} [ipx::current_core]
set_property vendor_display_name 	${vendor_display_name} [ipx::current_core]
set_property company_url 		${vendor_company_url} [ipx::current_core]
set_property vendor 			${vendor_name} [ipx::current_core]
set_property supported_families {{virtexuplus} {Production} {virtexuplushbm} {Production}} [ipx::current_core]
set_property taxonomy 			{{/NetFPGA/Generic}} [ipx::current_core]
set_property version 			${ip_version} [ipx::current_core]
set_property display_name 		${ip_display_name} [ipx::current_core]
set_property description 		${ip_description} [ipx::current_core]

# Add SubCore Reference
#foreach subcore ${subcore_names} {
#	puts $subcore
#	set subcore_regex NAME=~*$subcore*
#	set subcore_ipdef [get_ipdefs -filter ${subcore_regex}]
#
#	ipx::add_subcore ${subcore_ipdef} [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
#	ipx::add_subcore ${subcore_ipdef}  [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
#	puts "Adding the following subcore: $subcore_ipdef \n"
#
#}
ipx::add_subcore NetFPGA:NetFPGA:nf_axis_converter:1.0 [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
ipx::add_subcore NetFPGA:NetFPGA:nf_axis_converter:1.0 [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
ipx::add_subcore NetFPGA:NetFPGA:fallthrough_small_fifo:1.0 [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
ipx::add_subcore NetFPGA:NetFPGA:fallthrough_small_fifo:1.0 [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
ipx::infer_user_parameters [ipx::current_core]


# Auto Generate Parameters
ipx::remove_all_hdl_parameter [ipx::current_core]
ipx::add_model_parameters_from_hdl [ipx::current_core] -top_level_hdl_file $top_module_file -top_module_name $top_module_name
ipx::infer_user_parameters [ipx::current_core]

## manual 
set_property value_validation_type list [ipx::get_user_parameters C_M_AXIS_DATA_WIDTH -of_objects [ipx::current_core]]
set_property value_validation_list {1024 512 256 64} [ipx::get_user_parameters C_M_AXIS_DATA_WIDTH -of_objects [ipx::current_core]]
set_property value_validation_type list [ipx::get_user_parameters C_S_AXIS_DATA_WIDTH -of_objects [ipx::current_core]]
set_property value_validation_list {1024 512 256 64} [ipx::get_user_parameters C_S_AXIS_DATA_WIDTH -of_objects [ipx::current_core]]
set_property value_validation_type list [ipx::get_user_parameters C_DEFAULT_VALUE_ENABLE -of_objects [ipx::current_core]]
set_property value_validation_list {0 1} [ipx::get_user_parameters C_DEFAULT_VALUE_ENABLE -of_objects [ipx::current_core]]
set_property value_validation_type list [ipx::get_user_parameters C_M_AXIS_TUSER_WIDTH -of_objects [ipx::current_core]]
set_property value_validation_list 128 [ipx::get_user_parameters C_M_AXIS_TUSER_WIDTH -of_objects [ipx::current_core]]
set_property value_validation_type list [ipx::get_user_parameters C_S_AXIS_TUSER_WIDTH -of_objects [ipx::current_core]]
set_property value_validation_list 128 [ipx::get_user_parameters C_S_AXIS_TUSER_WIDTH -of_objects [ipx::current_core]]
set_property value_validation_type list [ipx::get_user_parameters C_DEFAULT_VALUE_ENABLE -of_objects [ipx::current_core]]
set_property value_validation_list {0 1} [ipx::get_user_parameters C_DEFAULT_VALUE_ENABLE -of_objects [ipx::current_core]]

# Add Ports
ipx::remove_all_port [ipx::current_core]
ipx::add_ports_from_hdl [ipx::current_core] -top_level_hdl_file $top_module_file -top_module_name $top_module_name

# Auto Infer Bus Interfaces
foreach bus_standard ${bus_interfaces} {
	ipx::infer_bus_interfaces ${bus_standard} [ipx::current_core]
}

# manually infer the rest
# 156MHz clk
ipx::add_bus_interface clk156 [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 [ipx::get_bus_interfaces clk156 -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:clock:1.0 [ipx::get_bus_interfaces clk156 -of_objects [ipx::current_core]]
set_property interface_mode slave [ipx::get_bus_interfaces clk156 -of_objects [ipx::current_core]]
ipx::add_port_map CLK [ipx::get_bus_interfaces clk156 -of_objects [ipx::current_core]]
set_property physical_name clk156 [ipx::get_port_maps CLK -of_objects [ipx::get_bus_interfaces clk156 -of_objects [ipx::current_core]]]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces clk156 -of_objects [ipx::current_core]]
set_property value m_axis_mac:s_axis_mac [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces clk156 -of_objects [ipx::current_core]]]

# rst associated with 156MHz 
ipx::add_bus_interface areset_clk156 [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:reset_rtl:1.0 [ipx::get_bus_interfaces areset_clk156 -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:reset:1.0 [ipx::get_bus_interfaces areset_clk156 -of_objects [ipx::current_core]]
set_property interface_mode slave [ipx::get_bus_interfaces areset_clk156 -of_objects [ipx::current_core]]
ipx::add_port_map RST [ipx::get_bus_interfaces areset_clk156 -of_objects [ipx::current_core]]
set_property physical_name areset_clk156 [ipx::get_port_maps RST -of_objects [ipx::get_bus_interfaces areset_clk156 -of_objects [ipx::current_core]]]
ipx::add_bus_parameter POLARITY [ipx::get_bus_interfaces areset_clk156 -of_objects [ipx::current_core]]
set_property value ACTIVE_HIGH [ipx::get_bus_parameters POLARITY -of_objects [ipx::get_bus_interfaces areset_clk156 -of_objects [ipx::current_core]]]

# axis clk - auto inferred as axis_signal_aclk -- bug of 2014.4
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces axis_aclk -of_objects [ipx::current_core]]
set_property value m_axis_pipe:s_axis_pipe [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces axis_aclk -of_objects [ipx::current_core]]]

# rst associated with axis clk - auto inferred

# BUS parameters
ipx::add_bus_parameter TDATA_NUM_BYTES [ipx::get_bus_interfaces m_axis_pipe -of_objects [ipx::current_core]]
set_property description {TDATA Width (bytes)} [ipx::get_bus_parameters TDATA_NUM_BYTES -of_objects [ipx::get_bus_interfaces m_axis_pipe -of_objects [ipx::current_core]]]
set_property value 32 [ipx::get_bus_parameters TDATA_NUM_BYTES -of_objects [ipx::get_bus_interfaces m_axis_pipe -of_objects [ipx::current_core]]]

# Write IP Core xml to File system
ipx::check_integrity [ipx::current_core]
write_peripheral [ipx::current_core]

# Generate GUI Configuration Files
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

close_project
exit
