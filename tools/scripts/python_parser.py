#!/usr/bin/python3

# Copyright (c) 2015 Neelakandan Manihatty Bojan
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory 
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
################################################################################
#  Description:
#        This is used to convert reg_defines.h to reg_defines.py
#

import re

input_file = open("reg_defines.h", "r")
output_file = open("reg_defines.py", "w")
output_file.write("#!/usr/bin/python")
for line in input_file:
    match_defines = re.match(r'\s*#define ([a-zA-Z_0-9]+) (.*)', line)
    match_comments = re.match(r'\s*[/\*][\s*\*](.*)', line)
    match_slash = re.match(r'\s*[/*](.*)', line)

    if match_defines:
        newline1= "\ndef %s():\n    return %s" % (match_defines.group(1),match_defines.group(2))
        output_file.write(newline1)

    elif match_comments:
        newline2= "\n# %s" % (match_comments.group(1))
        output_file.write(newline2)

    elif match_slash:
        newline3= "\n# %s" % (match_slash.group(1))
        output_file.write(newline3)

    else:
        output_file.write(line)


