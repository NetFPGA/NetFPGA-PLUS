#
# Copyright (c) 2015 Georgina Kalogeridou
# All rights reserved.
#
# This software was developed by
# Stanford University and the University of Cambridge Computer Laboratory
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
# as part of the DARPA MRC research programme.
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

# Set variables.
set design        barrier
set device $::env(DEVICE)
set proj_dir      ./ip_proj
set ip_version    1.0
set lib_name      NetFPGA

# Project setting.
create_project -name ${design} -force -dir "./${proj_dir}" -part ${device} -ip
set_property source_mgmt_mode All [current_project]  
set_property top ${design} [current_fileset]
set_property ip_repo_paths $::env(NFPLUS_FOLDER)/hw/lib/  [current_fileset]
update_ip_catalog
# IP build.
read_verilog "./hdl/barrier.v" 
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
ipx::package_project

set_property name ${design} [ipx::current_core]
set_property library ${lib_name} [ipx::current_core]
set_property vendor_display_name {NetFPGA} [ipx::current_core]
set_property company_url {http://www.netfpga.org} [ipx::current_core]
set_property vendor {NetFPGA} [ipx::current_core]
set_property supported_families {{virtexuplus} {Production} {virtexuplushbm} {Production}} [ipx::current_core]
set_property taxonomy {{/NetFPGA/Generic}} [ipx::current_core]
set_property version ${ip_version} [ipx::current_core]
set_property display_name ${design} [ipx::current_core]
set_property description ${design} [ipx::current_core]

update_ip_catalog -rebuild 
ipx::infer_user_parameters [ipx::current_core]

ipx::add_user_parameter {NUM_PORTS} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters NUM_PORTS]
set_property display_name {NUM_PORTS} [ipx::get_user_parameters NUM_PORTS]
set_property value {2} [ipx::get_user_parameters NUM_PORTS]
set_property value_format {long} [ipx::get_user_parameters NUM_PORTS]

ipx::add_user_parameter {INACTIVITY_TIMEOUT} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters INACTIVITY_TIMEOUT]
set_property display_name {INACTIVITY_TIMEOUT} [ipx::get_user_parameters INACTIVITY_TIMEOUT]
set_property value {4000} [ipx::get_user_parameters INACTIVITY_TIMEOUT]
set_property value_format {long} [ipx::get_user_parameters INACTIVITY_TIMEOUT]

ipx::infer_user_parameters [ipx::current_core]

ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]
update_ip_catalog
close_project
