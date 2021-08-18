#
# Copyright (c) 2015 Noa Zilberman
# Modified by Salvator Galea
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

# Vivado Launch Script
#### Change design settings here #######
set design fallthrough_small_fifo
set top fallthrough_small_fifo
set device $::env(DEVICE)
set proj_dir ./ip_proj
set ip_version 1.00
set lib_name NetFPGA
#####################################
# set IP paths
#####################################

#####################################
# Project Settings
#####################################
create_project -name ${design} -force -dir "./${proj_dir}" -part ${device} -ip
set_property source_mgmt_mode All [current_project]
set_property top ${top} [current_fileset]
set_property ip_repo_paths $::env(NFPLUS_FOLDER)/hw/lib  [current_fileset]
puts "Creating Fallthrough Small FIFO IP"
#####################################
# Project Structure & IP Build
#####################################

read_verilog "./hdl/fallthrough_small_fifo.v"
read_verilog "./hdl/small_fifo.v"
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

ipx::infer_user_parameters [ipx::current_core]

ipx::add_user_parameter {WIDTH} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters WIDTH]
set_property display_name {WIDTH} [ipx::get_user_parameters WIDTH]
set_property value {72} [ipx::get_user_parameters WIDTH]
set_property value_format {long} [ipx::get_user_parameters WIDTH]

ipx::add_user_parameter {MAX_DEPTH_BITS} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters MAX_DEPTH_BITS]
set_property display_name {MAX_DEPTH_BITS} [ipx::get_user_parameters MAX_DEPTH_BITS]
set_property value {3} [ipx::get_user_parameters MAX_DEPTH_BITS]
set_property value_format {long} [ipx::get_user_parameters MAX_DEPTH_BITS]

ipx::add_user_parameter {PROG_FULL_THRESHOLD} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters PROG_FULL_THRESHOLD]
set_property display_name {PROG_FULL_THRESHOLD} [ipx::get_user_parameters PROG_FULL_THRESHOLD]
set_property value {2} [ipx::get_user_parameters PROG_FULL_THRESHOLD]
set_property value_format {long} [ipx::get_user_parameters PROG_FULL_THRESHOLD]

ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]
update_ip_catalog
close_project

file delete -force ${proj_dir} 
