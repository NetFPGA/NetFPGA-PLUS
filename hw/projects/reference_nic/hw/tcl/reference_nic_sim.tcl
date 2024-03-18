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

#### Change design settings here #######
set design $::env(NF_PROJECT_NAME) 
set top top_sim
set sim_top top_tb
set device $::env(DEVICE)
set board  $::env(BOARD)
set board_name  $::env(BOARD_NAME)

set proj_dir ./project
set public_repo_dir $::env(NFPLUS_FOLDER)/hw/lib/
set repo_dir ./ip_repo
set project_constraints ./constraints/${board_name}_switch.xdc

set test_name [lindex $argv 0] 
source $::env(NF_DESIGN_DIR)/hw/tcl/$::env(NF_PROJECT_NAME)_defines.tcl

set_param general.maxThreads 8
#####################################
# Design Parameters on NF_DATAPATH
#####################################
set datapath_width_bit    1024
#####################################
# Project Settings
#####################################
create_project -name ${design} -force -dir "./${proj_dir}" -part ${device}
set_property board_part ${board} [current_project]
set_property source_mgmt_mode DisplayOnly [current_project]
set_property top ${top} [current_fileset]
puts "Creating User Datapath reference project"
#####################################
# set IP paths
#####################################
create_fileset -constrset -quiet constraints
file copy ${public_repo_dir}/ ${repo_dir}
set_property ip_repo_paths ${repo_dir} [current_fileset]
 
#####################################
# Project 
#####################################
update_ip_catalog
# OPL
create_ip -name nic_output_port_lookup -vendor NetFPGA -library NetFPGA -module_name nic_output_port_lookup_ip
set_property CONFIG.C_M_AXIS_DATA_WIDTH ${datapath_width_bit} [get_ips nic_output_port_lookup_ip]
set_property CONFIG.C_S_AXIS_DATA_WIDTH ${datapath_width_bit} [get_ips nic_output_port_lookup_ip]
set_property generate_synth_checkpoint false [get_files nic_output_port_lookup_ip.xci]
reset_target all [get_ips nic_output_port_lookup_ip]
generate_target all [get_ips nic_output_port_lookup_ip]
# input_arbiter
create_ip -name input_arbiter -vendor NetFPGA -library NetFPGA -module_name input_arbiter_ip
set_property CONFIG.C_M_AXIS_DATA_WIDTH ${datapath_width_bit} [get_ips input_arbiter_ip]
set_property CONFIG.C_S_AXIS_DATA_WIDTH ${datapath_width_bit} [get_ips input_arbiter_ip]
set_property generate_synth_checkpoint false [get_files input_arbiter_ip.xci]
reset_target all [get_ips input_arbiter_ip]
generate_target all [get_ips input_arbiter_ip]
# output_queues
create_ip -name output_queues -vendor NetFPGA -library NetFPGA -module_name output_queues_ip
set_property CONFIG.C_M_AXIS_DATA_WIDTH ${datapath_width_bit} [get_ips output_queues_ip]
set_property CONFIG.C_S_AXIS_DATA_WIDTH ${datapath_width_bit} [get_ips output_queues_ip]
set_property generate_synth_checkpoint false [get_files output_queues_ip.xci]
reset_target all [get_ips output_queues_ip]
generate_target all [get_ips output_queues_ip]

create_ip -name nf_mac_attachment -vendor NetFPGA -library NetFPGA -module_name nf_mac_attachment_ip
set_property CONFIG.C_M_AXIS_DATA_WIDTH ${datapath_width_bit} [get_ips nf_mac_attachment_ip]
set_property CONFIG.C_S_AXIS_DATA_WIDTH ${datapath_width_bit} [get_ips nf_mac_attachment_ip]
set_property generate_synth_checkpoint false [get_files nf_mac_attachment_ip.xci]
reset_target all [get_ips nf_mac_attachment_ip]
generate_target all [get_ips nf_mac_attachment_ip]

create_ip -name nf_mac_attachment -vendor NetFPGA -library NetFPGA -module_name nf_mac_attachment_dma_ip
set_property CONFIG.C_M_AXIS_DATA_WIDTH ${datapath_width_bit} [get_ips nf_mac_attachment_dma_ip]
set_property CONFIG.C_S_AXIS_DATA_WIDTH ${datapath_width_bit} [get_ips nf_mac_attachment_dma_ip]
set_property CONFIG.C_DEFAULT_VALUE_ENABLE 0 [get_ips nf_mac_attachment_dma_ip]
set_property generate_synth_checkpoint false [get_files nf_mac_attachment_dma_ip.xci]
reset_target all [get_ips nf_mac_attachment_dma_ip]
generate_target all [get_ips nf_mac_attachment_dma_ip]
create_ip -name barrier -vendor NetFPGA -library NetFPGA -module_name barrier_ip
reset_target all [get_ips barrier_ip]
generate_target all [get_ips barrier_ip]

create_ip -name axis_sim_record -vendor NetFPGA -library NetFPGA -module_name axis_sim_record_ip0
set_property -dict [list CONFIG.OUTPUT_FILE $::env(NF_DESIGN_DIR)/test/nf_interface_0_log.axi] [get_ips axis_sim_record_ip0]
reset_target all [get_ips axis_sim_record_ip0]
generate_target all [get_ips axis_sim_record_ip0]

create_ip -name axis_sim_record -vendor NetFPGA -library NetFPGA -module_name axis_sim_record_ip1
set_property -dict [list CONFIG.OUTPUT_FILE $::env(NF_DESIGN_DIR)/test/nf_interface_1_log.axi] [get_ips axis_sim_record_ip1]
reset_target all [get_ips axis_sim_record_ip1]
generate_target all [get_ips axis_sim_record_ip1]

create_ip -name axis_sim_record -vendor NetFPGA -library NetFPGA -module_name axis_sim_record_ip2
set_property -dict [list CONFIG.OUTPUT_FILE $::env(NF_DESIGN_DIR)/test/dma_0_log.axi] [get_ips axis_sim_record_ip2]
reset_target all [get_ips axis_sim_record_ip2]
generate_target all [get_ips axis_sim_record_ip2]


create_ip -name axis_sim_stim -vendor NetFPGA -library NetFPGA -module_name axis_sim_stim_ip0
set_property -dict [list CONFIG.input_file $::env(NF_DESIGN_DIR)/test/nf_interface_0_stim.axi] [get_ips axis_sim_stim_ip0]
generate_target all [get_ips axis_sim_stim_ip0]

create_ip -name axis_sim_stim -vendor NetFPGA -library NetFPGA -module_name axis_sim_stim_ip1
set_property -dict [list CONFIG.input_file $::env(NF_DESIGN_DIR)/test/nf_interface_1_stim.axi] [get_ips axis_sim_stim_ip1]
generate_target all [get_ips axis_sim_stim_ip1]

create_ip -name axis_sim_stim -vendor NetFPGA -library NetFPGA -module_name axis_sim_stim_ip2
set_property -dict [list CONFIG.input_file $::env(NF_DESIGN_DIR)/test/dma_0_stim.axi] [get_ips axis_sim_stim_ip2]
generate_target all [get_ips axis_sim_stim_ip2]


create_ip -name axi_sim_transactor -vendor NetFPGA -library NetFPGA -module_name axi_sim_transactor_ip
set_property -dict [list CONFIG.STIM_FILE $::env(NF_DESIGN_DIR)/test/reg_stim.axi CONFIG.EXPECT_FILE $::env(NF_DESIGN_DIR)/test/reg_expect.axi CONFIG.LOG_FILE $::env(NF_DESIGN_DIR)/test/reg_stim.log] [get_ips axi_sim_transactor_ip]
reset_target all [get_ips axi_sim_transactor_ip]
generate_target all [get_ips axi_sim_transactor_ip]


create_ip -name axi_crossbar -vendor xilinx.com -library ip -module_name axi_crossbar_0
set_property -dict [list \
CONFIG.NUM_MI {3}                            \
CONFIG.PROTOCOL {AXI4LITE}                   \
CONFIG.CONNECTIVITY_MODE {SASD}              \
CONFIG.R_REGISTER {1}                        \
CONFIG.S00_WRITE_ACCEPTANCE {1}              \
CONFIG.S01_WRITE_ACCEPTANCE {1}              \
CONFIG.S02_WRITE_ACCEPTANCE {1}              \
CONFIG.S03_WRITE_ACCEPTANCE {1}              \
CONFIG.S04_WRITE_ACCEPTANCE {1}              \
CONFIG.S05_WRITE_ACCEPTANCE {1}              \
CONFIG.S06_WRITE_ACCEPTANCE {1}              \
CONFIG.S07_WRITE_ACCEPTANCE {1}              \
CONFIG.S08_WRITE_ACCEPTANCE {1}              \
CONFIG.S09_WRITE_ACCEPTANCE {1}              \
CONFIG.S10_WRITE_ACCEPTANCE {1}              \
CONFIG.S11_WRITE_ACCEPTANCE {1}              \
CONFIG.S12_WRITE_ACCEPTANCE {1}              \
CONFIG.S13_WRITE_ACCEPTANCE {1}              \
CONFIG.S14_WRITE_ACCEPTANCE {1}              \
CONFIG.S15_WRITE_ACCEPTANCE {1}              \
CONFIG.S00_READ_ACCEPTANCE {1}               \
CONFIG.S01_READ_ACCEPTANCE {1}               \
CONFIG.S02_READ_ACCEPTANCE {1}               \
CONFIG.S03_READ_ACCEPTANCE {1}               \
CONFIG.S04_READ_ACCEPTANCE {1}               \
CONFIG.S05_READ_ACCEPTANCE {1}               \
CONFIG.S06_READ_ACCEPTANCE {1}               \
CONFIG.S07_READ_ACCEPTANCE {1}               \
CONFIG.S08_READ_ACCEPTANCE {1}               \
CONFIG.S09_READ_ACCEPTANCE {1}               \
CONFIG.S10_READ_ACCEPTANCE {1}               \
CONFIG.S11_READ_ACCEPTANCE {1}               \
CONFIG.S12_READ_ACCEPTANCE {1}               \
CONFIG.S13_READ_ACCEPTANCE {1}               \
CONFIG.S14_READ_ACCEPTANCE {1}               \
CONFIG.S15_READ_ACCEPTANCE {1}               \
CONFIG.M00_WRITE_ISSUING {1}                 \
CONFIG.M01_WRITE_ISSUING {1}                 \
CONFIG.M02_WRITE_ISSUING {1}                 \
CONFIG.M03_WRITE_ISSUING {1}                 \
CONFIG.M04_WRITE_ISSUING {1}                 \
CONFIG.M05_WRITE_ISSUING {1}                 \
CONFIG.M06_WRITE_ISSUING {1}                 \
CONFIG.M07_WRITE_ISSUING {1}                 \
CONFIG.M08_WRITE_ISSUING {1}                 \
CONFIG.M09_WRITE_ISSUING {1}                 \
CONFIG.M10_WRITE_ISSUING {1}                 \
CONFIG.M11_WRITE_ISSUING {1}                 \
CONFIG.M12_WRITE_ISSUING {1}                 \
CONFIG.M13_WRITE_ISSUING {1}                 \
CONFIG.M14_WRITE_ISSUING {1}                 \
CONFIG.M15_WRITE_ISSUING {1}                 \
CONFIG.M00_READ_ISSUING {1}                  \
CONFIG.M01_READ_ISSUING {1}                  \
CONFIG.M02_READ_ISSUING {1}                  \
CONFIG.M03_READ_ISSUING {1}                  \
CONFIG.M04_READ_ISSUING {1}                  \
CONFIG.M05_READ_ISSUING {1}                  \
CONFIG.M06_READ_ISSUING {1}                  \
CONFIG.M07_READ_ISSUING {1}                  \
CONFIG.M08_READ_ISSUING {1}                  \
CONFIG.M09_READ_ISSUING {1}                  \
CONFIG.M10_READ_ISSUING {1}                  \
CONFIG.M11_READ_ISSUING {1}                  \
CONFIG.M12_READ_ISSUING {1}                  \
CONFIG.M13_READ_ISSUING {1}                  \
CONFIG.M14_READ_ISSUING {1}                  \
CONFIG.M15_READ_ISSUING {1}                  \
CONFIG.S00_SINGLE_THREAD {1}                 \
CONFIG.M00_A00_ADDR_WIDTH {16}               \
CONFIG.M01_A00_ADDR_WIDTH {16}               \
CONFIG.M02_A00_ADDR_WIDTH {16}               \
CONFIG.M00_A00_BASE_ADDR {0x0000000000200000}\
CONFIG.M01_A00_BASE_ADDR {0x0000000000210000}\
CONFIG.M02_A00_BASE_ADDR {0x0000000000220000}] [get_ips axi_crossbar_0]
set_property generate_synth_checkpoint false [get_files axi_crossbar_0.xci]
reset_target all [get_ips axi_crossbar_0]
generate_target all [get_ips axi_crossbar_0]

read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/nf_datapath.v"
read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/top_sim.v"
read_verilog "$::env(NF_DESIGN_DIR)/hw/hdl/top_tb.v"

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set_property top ${sim_top} [get_filesets sim_1]
set_property include_dirs ${proj_dir} [get_filesets sim_1]
set_property simulator_language Mixed [current_project]
set_property verilog_define { {SIMULATION=1} } [get_filesets sim_1]
set_property -name xsim.more_options -value {-testplusarg TESTNAME=basic_test} -objects [get_filesets sim_1]
set_property runtime {} [get_filesets sim_1]
set_property target_simulator xsim [current_project]
set_property compxlib.compiled_library_dir {} [current_project]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

unset env(PYTHONPATH)
unset env(PYTHONHOME)
set env(PYTHONPATH) ".:$::env(NFPLUS_FOLDER)/tools/scripts/:$::env(NFPLUS_FOLDER)/tools/scripts/NFTest"
set output [exec $::env(PYTHON_BNRY) $::env(NF_DESIGN_DIR)/test/${test_name}/run.py]
puts $output

launch_simulation -simset sim_1 -mode behavioral
run 140us

