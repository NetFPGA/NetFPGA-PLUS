#!/bin/sh
#
# Copyright (c) 2015-2021 University of Cambridge
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

# Run bash pci_rescan_run.sh

PcieBusPath=/sys/bus/pci/devices
PcieDeviceList=`ls /sys/bus/pci/devices/`
bus0="fail"
bus1="fail"
for BusNo in $PcieDeviceList
do	
	VenderId=`cat $PcieBusPath/$BusNo/device`
	if [[ "$VenderId" = "0x903f" ]]; then
		echo 1 > /sys/bus/pci/devices/$BusNo/remove
		sleep 1
		echo 1 > /sys/bus/pci/rescan
		echo
		echo "Completed rescan PCIe information !"
		echo
		bus0="pass"
	fi
done

for BusNo in $PcieDeviceList
do	
	VenderId=`cat $PcieBusPath/$BusNo/device`
	if [[ "$VenderId" = "0x913f" ]]; then
		echo 1 > /sys/bus/pci/devices/$BusNo/remove
		sleep 1
		echo 1 > /sys/bus/pci/rescan
		echo
		echo "Completed rescan PCIe information !"
		echo
		bus1="pass"
	fi
done

if [ $bus0 == "fail" ] | [ $bus1 == "fail" ]; then
	echo "Check programming FPGA or Reboot machine !"
fi
