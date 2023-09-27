#
# Copyright (c) 2021 University of Cambridge
# All rights reserved.
#
# This software was developed by the University of Cambridge Computer
# Laboratory under EPSRC EARL Project EP/P025374/1 alongside support 
# from Xilinx Inc.
#
# @NETFPGA_LICENSE_HEADER_START@

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
### User defined
export NFPLUS_FOLDER=${HOME}/NetFPGA-PLUS-GW
export BOARD_NAME=au250
export NF_PROJECT_NAME=reference_switch
export PYTHON_BNRY=/usr/bin/python3

### Don't change
# export VERSION=2020.2     -  GREG - had to change this to latest Vivado version
export VERSION=2023.1


export PROJECTS=${NFPLUS_FOLDER}/projects
export CONTRIB_PROJECTS=${NFPLUS_FOLDER}/contrib-projects
export NF_DESIGN_DIR=${NFPLUS_FOLDER}/hw/projects/${NF_PROJECT_NAME}
export NF_WORK_DIR=/tmp/${USER}
export PYTHONPATH=.:${NFPLUS_FOLDER}/tools/scripts/:${NF_DESIGN_DIR}/lib/Python:${NFPLUS_FOLDER}/tools/scripts/NFTest
export DRIVER_FOLDER=${NFPLUS_FOLDER}/lib/sw/std/driver/${DRIVER_NAME}
export APPS_FOLDER=${NFPLUS_FOLDER}/lib/sw/std/apps/${DRIVER_NAME}


# Check sequence
if [ ! -d ${NFPLUS_FOLDER} ] ; then
	echo "Error: ${NFPLUS_FOLDER} is not found."
	return -1
fi

if [ ${BOARD_NAME} != "au280" -a \
     ${BOARD_NAME} != "au250" -a \
     ${BOARD_NAME} != "au200" -a \
     ${BOARD_NAME} != "au50"  -a \
     ${BOARD_NAME} != "vcu1525" ] ; then 
	echo "Error: ${BOARD_NAME} is not supported."
	echo "    Supported boards are au280, au250, au200, au50, and vcu1525."
	return -1
else
	board_name=`echo "puts [get_board_parts -quiet -latest_file_version \"*:${BOARD_NAME}:*\"]" | vivado -nolog -nojournal -mode tcl | grep xilinx` 
	echo "**** GREG: BOARD_NAME is $BOARD_NAME and board_name is $board_name"
	if [ ${BOARD_NAME} = "au280" ] ; then
		device="xcu280-fsvh2892-2L-e"
	elif [ ${BOARD_NAME} = "au250" ] ; then
		device="xcu250-figd2104-2L-e"
	elif [ ${BOARD_NAME} = "au200" ] ; then
		device="xcu200-fsgd2104-2-e"
	elif [ ${BOARD_NAME} = "au50" ] ; then
		device="xcu50-fsvh2104-2-e"
	elif [ ${BOARD_NAME} = "vcu1525" ] ; then
		device="xcvu9p-fsgd2104-2L-e"
	fi
fi

if [ ! -d ${NF_DESIGN_DIR} ] ; then
	echo "Error: ${NF_PROJECT_NAME} cannot be found."
	return -1
fi

echo "[ok]    All parameters have been checked."

vivado_version=`echo $XILINX_VIVADO | awk -F "/" 'NF>1{print $NF}'`
if [ -z ${vivado_version} ]; then
	echo "Error: please source vivado scripts. e.g.) /tools/Xilinx/Vivado/2019.2/settings64.sh"
	return -1
fi
if [ ${VERSION} != ${vivado_version} -a \
     ${VERSION}* != ${vivado_version} ] ; then
	echo "Error: you don't have proper Vivado version (${VERSION})."
	return -1
fi

echo "[ok]    Vivado Version (${VERSION}) has been checked."
echo "     NFPLUS_FOLDER  :   ${NFPLUS_FOLDER}"
echo "     BOARD_NAME     :   ${BOARD_NAME}"
echo "     NF_PROJECT_NAME:   ${NF_PROJECT_NAME}"

echo "Done..."

export BOARD=${board_name}
export DEVICE=${device}

