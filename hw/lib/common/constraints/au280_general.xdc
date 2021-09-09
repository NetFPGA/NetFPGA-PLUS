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
###########################################################################
# This file is based on the origin file downloaded from
# https://www.xilinx.com/products/boards-and-kits/alveo/u280.html#vivado
###########################################################################
#
#######################################################################
# General Clock
#######################################################################
set_property PACKAGE_PIN BJ44 [get_ports sysclk_n];
set_property IOSTANDARD LVDS [get_ports sysclk_n];
set_property PACKAGE_PIN BJ43 [get_ports sysclk_p];
set_property IOSTANDARD LVDS [get_ports sysclk_p];
#create_clock -period  10.000 -name sysclk0 [get_ports sysclk0_p]
#set_clock_groups -asynchronous -group [get_clocks sysclk0 -include_generated_clocks]

#set_clock_groups -asynchronous -group [get_clocks SYSCLK0_300 -include_generated_clocks]
#######################################################################
# PCIe
#######################################################################
set_property PACKAGE_PIN AR14 [get_ports pci_clk_n]
set_property PACKAGE_PIN AR15 [get_ports pci_clk_p]
#create_clock -name sys_clk -period 10 [get_ports pci_clk_p]
create_clock -period 10.000 -name pcie_refclk [get_ports pci_clk_p]



set_property PULLUP true [get_ports pci_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports pci_rst_n]
set_property PACKAGE_PIN BH26 [get_ports pci_rst_n]

set_false_path -through [get_ports pci_rst_n]
#######################################################################
# CMAC
#######################################################################
# QSFP0_CLOCK
set_property PACKAGE_PIN R41 [get_ports QSFP0_CLOCK_N];
set_property PACKAGE_PIN R40 [get_ports QSFP0_CLOCK_P];
# QSFP0_PORT
set_property PACKAGE_PIN G32 [get_ports QSFP0_FS];
set_property IOSTANDARD LVCMOS18 [get_ports QSFP0_FS];
set_property PACKAGE_PIN H32 [get_ports QSFP0_RESET]
set_property IOSTANDARD LVCMOS18 [get_ports QSFP0_RESET]

# QSFP1
set_property PACKAGE_PIN M43 [get_ports QSFP1_CLOCK_N];
set_property PACKAGE_PIN M42 [get_ports QSFP1_CLOCK_P];

# QSFP1
set_property PACKAGE_PIN G33 [get_ports QSFP1_FS];
set_property IOSTANDARD LVCMOS18 [get_ports QSFP1_FS];
set_property PACKAGE_PIN H30 [get_ports QSFP1_RESET]
set_property IOSTANDARD LVCMOS18 [get_ports QSFP1_RESET]

# HBM
set_property PACKAGE_PIN D32 [get_ports STAT_CATTRIP]
set_property IOSTANDARD LVCMOS18 [get_ports STAT_CATTRIP]
##########################################################################
# Timing
##########################################################################
# CMAC user clock
create_clock -period 3.103 -name cmac_clk_0 [get_pins -hier -filter name=~*cmac_port[0]*cmac_gtwiz_userclk_tx_inst/txoutclk_out[0]]
create_clock -period 3.103 -name cmac_clk_1 [get_pins -hier -filter name=~*cmac_port[1]*cmac_gtwiz_userclk_tx_inst/txoutclk_out[0]]

# Datapath Clock - 340MHz
create_clock -period 2.941 -name dp_clk [get_pins -hier -filter name=~*u_clk_wiz_1/clk_out1]

set_false_path -from [get_clocks axis_aclk] -to [get_clocks dp_clk]
set_false_path -from [get_clocks dp_clk] -to [get_clocks axis_aclk]
set_false_path -from [get_clocks cmac_clk_1] -to [get_clocks dp_clk]
set_false_path -from [get_clocks dp_clk] -to [get_clocks cmac_clk_1]
set_false_path -from [get_clocks cmac_clk_0] -to [get_clocks dp_clk]
set_false_path -from [get_clocks dp_clk] -to [get_clocks cmac_clk_0]
