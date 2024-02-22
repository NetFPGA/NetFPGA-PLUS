#!/usr/bin/env python3
#
# Copyright (c) 2015 University of Cambridge
# Copyright (c) 2015 Neelakandan Manihatty Bojan, Georgina Kalogeridou
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
#
# Author:
#        Modified by Neelakandan Manihatty Bojan, Georgina Kalogeridou

import os
import sys
import argparse
import glob
import subprocess

script_dir = os.path.dirname( sys.argv[0] )
# Add path *relative to this script's location* of testcheck module
sys.path.append( os.path.join( script_dir, 'NFTest' ) )

import testcheck

import re

GLOBAL_SETUP = 'global setup'
GLOBAL_TEARDOWN = 'global teardown'

args = None

rootDir = ''
project = ''
projDir = ''
workDir = ''

work_test_dir = ''

proj_test_dir = ''
src_test_dir = ''

sim_opt = ''

tests = []

REQUIRED = 1
OPTIONAL = 0

teardown = 'teardown'
setup = 'setup'
run = 'run.py'
commonDir = 'common'
globalDir = 'global'
projectRoot = 'projects'
testRoot = 'test'


def run_hw_test():
    print('Root directory is ' + rootDir)

    #verify ci is correct if set
    verifyCI()

    #verify the mapfile exists
    if args.map:
        try:
            mapfile = open(args.map)
            mapfile.close()
        except IOError as  exc:
            print('Error opening mapfile ' + args.map)
            print(exc.strerror)
            sys.exit(1)

    #run regression tests on each project one-by-one
    results = []
    testResults = {}
    passed = True
    commonPass = True

    test = args.citest + testcheck.tcGetTestSeparator() + 'global.setup'
    if not args.quiet:
        print('   Running global setup... ', end=' ')
    testcheck.tcTestStarted(test)
    (gsResult, output) = runGlobalSetup(project)
    if not gsResult:
        passed = False

        # Store the test results for later
        testResults[GLOBAL_SETUP] = gsResult
        test_result = ( GLOBAL_SETUP, gsResult, output)
        results.append(test_result)

    # run checks
    printScriptOutput(gsResult, output)
    if not gsResult:
        testcheck.tcTestFailed(test, 'Test failed', output)
    testcheck.tcTestFinished(test)

    if gsResult:
        for test in tests:
            testStr = args.citest + testcheck.tcGetTestSeparator() + test
            testcheck.tcTestStarted(testStr)
            prepareTestWorkDir(test)
            if not args.quiet:
                sys.stdout.write('   Running test ' + os.path.basename(test) + '... ')
                sys.stdout.flush()

            # Common setup
            (csResult, csOutput) = runCommonSetup(project)
            testResults[test] = csResult
            passed &= csResult
            commonPass &= csResult

            # Local setup -- only run if common setup passed
            if csResult:
                (lsResult, lsOutput) = runLocalSetup(project, test)
                testResults[test] = lsResult
                passed &= lsResult

            # Actual test -- only run if both setups succeed
            if csResult and lsResult:
                (testResult, testOutput) = runTest(project, test)
                testResults[test] = testResult
                passed &= testResult

            # Local teardown -- only run if both setups succeeded
            if csResult and lsResult:
                (ltResult, ltOutput) = runLocalTeardown(project, test)
                testResults[test] = ltResult
                passed &= ltResult

            # Common teardown -- only run if the common setup succeeded
            if csResult:
                (ctResult, ctOutput) = runCommonTeardown(project)
                testResults[test] = ctResult
                passed &= ctResult
                commonPass &= ctResult

            testResult &= csResult & lsResult & ltResult & ctResult

            output = ''
            if not csResult:
                output += csOutput
            if not lsResult:
                output += lsOutput
            if not testResult:
                if testOutput != None:
                    output += testOutput
            if not ltResult:
                output += ltOutput
            if not ctResult:
                output += ctOutput

            if testResult:
                 output = testOutput
            test_result = (test, testResult, output)
            results.append(test_result)

            printScriptOutput(testResult, output)
            if not testResult:
                testcheck.tcTestFailed(testStr, 'Test failed', output)
            testcheck.tcTestFinished(testStr)

        # store outputs, push (test, testResult, output)  to results
            if not commonPass:
                break
            if args.failfast and not testResult:
                break

    # Run the teardown if the global setup passed and the tests passed or not failfast
    if gsResult and ( not args.failfast or passed):
        if not args.quiet:
            print('   Running global teardown... ', end=' ')
        (result, output) = runGlobalTeardown(project)
        if not result:
            passed = False
            testResults[GLOBAL_TEARDOWN] = result
            test_result = (GLOBAL_TEARDOWN, result, output)
            results.append(test_result)
        printScriptOutput(result, output)
        if not result:
            testcheck.tcTestFailed(test, 'Test failed', output)
        testcheck.tcTestFinished(test)
    if not args.quiet:
        print('\n')

    if args.quiet and not passed:
        print('Regression test suite failed\n')
        print('Project failing tests: ' + project)
        print('Tests failing within each project')
        for testSummary in results:
            if not testSummary[1]:
                print('Test: ' + testSummary[0])
                print('-' * len(testSummary[0]))
                print(testSummary[2])
            print('')

def run_sim_test():
    verifyCI()
    #set up test dirs
    passed = []; failed = []; gui = []
    for td in tests:
        if args.tx:
            if args.gui:
                if args.packet_length and args.packet_no:
                    charis = os.system("make simtxgui TESTNAME=sim_tx_dma PKTLEN=%d PKTNO=%d -C %s" % (length, number, designDIr + '/test/'))
                elif args.packet_length: 
                    charis = os.system("make simtxgui TESTNAME=sim_tx_dma PKTLEN=%d -C %s" % (length, designDIr + '/test/'))
                elif args.packet_no:
                    charis = os.system("make simtxgui TESTNAME=sim_tx_dma PKTNO=%d -C %s" % (number, designDIr + '/test/'))
                else:
                    charis = os.system("make simtxgui TESTNAME=sim_tx_dma -C %s" % (designDIr + '/test/'))
            else:
                if args.packet_length and args.packet_no:
                    charis = os.system("make simtx TESTNAME=sim_tx_dma PKTLEN=%d PKTNO=%d -C %s" % (length, number, designDIr + '/test/'))
                elif args.packet_length: 
                    charis = os.system("make simtx TESTNAME=sim_tx_dma PKTLEN=%d -C %s" % (length, designDIr + '/test/'))
                elif args.packet_no:
                    charis = os.system("make simtx TESTNAME=sim_tx_dma PKTNO=%d -C %s" % (number, designDIr + '/test/'))
                else:
                    charis = os.system("make simtx TESTNAME=sim_tx_dma -C %s" % (designDIr + '/test/'))
        elif args.rx:
            if args.gui:
                if args.packet_length and args.packet_no:
                    charis = os.system("make simrxgui TESTNAME=sim_rx_dma PKTLEN=%d PKTNO=%d -C %s" % (length, number, designDIr + '/test/'))
                elif args.packet_length: 
                    charis = os.system("make simrxgui TESTNAME=sim_rx_dma PKTLEN=%d -C %s" % (length, designDIr + '/test/'))
                elif args.packet_no:
                    charis = os.system("make simrxgui TESTNAME=sim_rx_dma PKTNO=%d -C %s" % (number, designDIr + '/test/'))
                else:
                    charis = os.system("make simrxgui TESTNAME=sim_rx_dma -C %s" % (designDIr + '/test/'))
            else:
                if args.packet_length and args.packet_no:
                    charis = os.system("make simrx TESTNAME=sim_rx_dma PKTLEN=%d PKTNO=%d -C %s" % (length, number, designDIr + '/test/'))
                elif args.packet_length: 
                    charis = os.system("make simrx TESTNAME=sim_rx_dma PKTLEN=%d -C %s" % (length, designDIr + '/test/'))
                elif args.packet_no:
                    charis = os.system("make simrx TESTNAME=sim_rx_dma PKTNO=%d -C %s" % (number, designDIr + '/test/'))
                else:
                    charis = os.system("make simrx TESTNAME=sim_rx_dma -C %s" % (designDIr + '/test/'))
        elif args.txrx:
            if args.gui:
                if args.packet_length and args.packet_no:
                    charis = os.system("make simtxrxgui TESTNAME=sim_txrx_dma PKTLEN=%d PKTNO=%d -C %s" % (length, number, designDIr + '/test/'))
                elif args.packet_length: 
                    charis = os.system("make simtxrxgui TESTNAME=sim_txrx_dma PKTLEN=%d -C %s" % (length, designDIr + '/test/'))
                elif args.packet_no:
                    charis = os.system("make simtxrxgui TESTNAME=sim_txrx_dma PKTNO=%d -C %s" % (number, designDIr + '/test/'))
                else:
                    charis = os.system("make simtxrxgui TESTNAME=sim_txrx_dma -C %s" % (designDIr + '/test/'))
            else:
                if args.packet_length and args.packet_no:
                    charis = os.system("make simtxrx TESTNAME=sim_txrx_dma PKTLEN=%d PKTNO=%d -C %s" % (length, number, designDIr + '/test/'))
                elif args.packet_length: 
                    charis = os.system("make simtxrx TESTNAME=sim_txrx_dma PKTLEN=%d -C %s" % (length, designDIr + '/test/'))
                elif args.packet_no:
                    charis = os.system("make simtxrx TESTNAME=sim_txrx_dma PKTNO=%d -C %s" % (number, designDIr + '/test/'))
                else:
                    charis = os.system("make simtxrx TESTNAME=sim_txrx_dma -C %s" % (designDIr + '/test/'))
        elif args.gui:
            charis = os.system("make simgui TESTNAME=%s -C %s" % (td, designDIr + '/test/'))
        else:
            charis = os.system("make sim TESTNAME=%s -C %s" % (td, designDIr + '/test/'))
        print(charis)
    
        if args.type == 'sim':
            subprocess.call(['cp', '-r', '-p', designDIr + '/hw/Makefile', src_test_dir])

        if not args.no_compile:
            buildSim()
        if args.compile_only:
            sys.exit(0)
        prepareTestWorkDir(td)
        global_run = designDIr + '/test/' + td + '/run.py'
        dst_dir = proj_test_dir + '/' + td
        which_run = global_run
        cmd = [which_run, '--sim']
        os.chdir(dst_dir)
        if args.isim:
            cmd.append('isim')
        elif args.vcs:
            cmd.append('vcs')
        elif args.vsim:
            cmd.append('vsim')
        else:
            cmd.append('xsim')
        if args.dump:
            cmd.append('--dump')
        if args.gui:
            cmd.append('--gui')
        if args.ci:
            cmd.append('--ci')
            cmd.append(args.ci)
            cmd.append('--citest')
            cmd.append(args.citest)

        #run tests
        print('=== Running test ' + dst_dir + ' ...', end = " ")
        print('using cmd', cmd) 
    
def handleArgs():
    parser = argparse.ArgumentParser()
    parser.add_argument('type', choices=['hw','sim'], help='Type of test to run: hw or sw')
    parser.add_argument('--quiet', action='store_true', help='Hardware only. Run in quiet mode; don\'t output anything unless there are errors.', default = False)
    parser.add_argument('--major', help='Specify the string to match on the first part of the test directory name.', metavar='<string>', default='')
    parser.add_argument('--minor', help='Specify the string to match on the last part of the test directory name.', metavar='<string>', default='')
    parser.add_argument('--packet_length', help='Specify the lenght of the packet.', type=int)
    parser.add_argument('--packet_no', help='Specify the number of the packet.', type=int)
    parser.add_argument('--conn', help='Specify the conn file specifying the physical connections of the nfX ports.  Formatting is one connection per line, nfX:ethY.', metavar='<connections file>')
    parser.add_argument('--map', help='Remap interfaces per mapfile, which is a list of two interfaces per line.', metavar='<map_file>')
    parser.add_argument('--ci', choices=['testcheck'], help='For use when using a continuout integration tool.  Instructs the system to print out extra debugging information used by the CI tool.', metavar='<test_tool>')
    parser.add_argument('--citest', help='The name of the top-level test to print error messages in when using the \'ci\' option.', metavar='<test_name>', default='')
    parser.add_argument('--failfast', action='store_true', help='Fail fast causes the regression suite to fail as soon as a test fails and not to run the teardown scripts.')
    parser.add_argument('--common-setup', help='Hardware only.  Run a custom setup script for each test', metavar='<local common setup file name>')
    parser.add_argument('--common-teardown', help='Hardware only.  Run a custom teardown script for each test.', metavar='<local common teardown file name>')
    parser.add_argument('--work_test_dir', help='Specify the directory where the compiled binary should be placed. Each test will have its own directory created beneath this directory.', metavar='<work_dir>')
    parser.add_argument('--src_test_dir', help='Specify the directory where the test directories are located. Each directory should be named type_<major>_<minor>(where type is \'hw\', \'sw\'. or \'both\') and should contain an executable script called \'run.py\' that will perform the actual simulation and check the results if necessary.')
    parser.add_argument('--make_opt', help='Simulation only. Specify a single string to be passed to make (e.g. to invoke a different make rule). Make is invoked using \'make -f <makefile> <option_string>', default = '')
    parser.add_argument('--sim_opt', help='Simulation only. This option allows the string to be passed to the HDL simulator. For example, a macro definition which is checked by the HDL testbench, a post-processing option, or a simulation delay model option.', default = '')
    parser.add_argument('--dump', action='store_true', help='Simulation only. Normally the simulation will not produce a VCD file. If you want a VCD file then place a file \'dump.v\' in your src directory and specify this option. Then dump.v will be compile as a top level module.')
    parser.add_argument('--vcs', action='store_true', help='Simulation only. If this option is present, vcs will run. Otherwise vsim will run.')
    parser.add_argument('--vsim', action='store_true', help='Simulation only. If this option is present, vcs will run. Otherwise vsim will run.')
    parser.add_argument('--isim', action='store_true', help='Simulation only. If this option is present, ISIM will run. Otherwise vsim will run.')
    parser.add_argument('--gui', action='store_true', help='Simulation only. This will run the simulator in interactive mode (usually with a GUI).')
    parser.add_argument('--tx', action='store_true', help='Simulation only. This will run the simulator sending from dma to phy.')
    parser.add_argument('--rx', action='store_true', help='Simulation only. This will run the simulator sending from phy to dma.')
    parser.add_argument('--txrx', action='store_true', help='Simulation only. This will run the simulator for loopback.')
    parser.add_argument('--lenmin', action='store_true', help='Simulation only. This will run the simulator for min length of the packet.')
    parser.add_argument('--lenmax', action='store_true', help='Simulation only. This will run the simulator for max length of the packet.')
    parser.add_argument('--no_compile', action='store_true', help='Simulation only. This will not compile the simulation binary.')
    parser.add_argument('--compile_only', action='store_true', help='Simulation only.  This will only compile the simulation.')
    parser.add_argument('--seed', nargs=1, help='Specify a seed for the random number generator to replay a previous run.')

    global args; args = parser.parse_args()
    if args.type == 'sim':
        if args.quiet or args.common_setup or args.common_teardown:
            print('Error: --quiet, --common-setup, and --common-teardown are only compatible with hardware tests')
            sys.exit(1)
    else:
        if args.make_opt or args.sim_opt or args.dump or args.vcs or args.vsim or args.isim or args.gui or args.no_compile or args.compile_only:
            print('Error: --make_opt, --sim_opt, --dump, --vcs, --vsim --isim, and --gui are only compatible with simulation tests')
            sys.exit(1)

def printEnv(dir_only = False):
    print("NetFPGA environment:")
    print("   Root dir:       " + rootDir)
    print("   Project name:   " + project)
    print("   Project dir:    " + projDir)
    print("   Work dir:       " + workDir)
    
    if dir_only:
        return

    if args.type == 'sim':
        subprocess.call(['cp', '-r', '-p', designDIr + '/hw/Makefile', src_test_dir])
        os.system("make reg -C %s" % (designDIr + '/test/'))
    else:
        os.system("make reg -C %s" % (designDIr + '/hw/'))

# verify that NF_ROOT has been set and exists
def identifyRoot():
    global rootDir; global projDir; global designDIr
    try:
        rootDir = os.path.abspath(os.environ['NFPLUS_FOLDER'])
        designDIr = os.path.abspath(os.environ['NF_DESIGN_DIR'])
        projDir = designDIr

        if not os.path.exists(rootDir):
            print("NetFPGA directory " + rootDir + " as referenced by environment variable 'NFPLUS_FOLDER' does not exist")
    except(KeyError):
        print("Please set the environment variable 'NFPLUS_FOLDER' to point to the local NetFPGA source")
    os.environ['NFPLUS_FOLDER'] = rootDir

def identifyWorkDir():
    global workDir
    try:
        workDir = os.path.abspath(os.environ['NF_WORK_DIR'])
    except(KeyError):
        login = os.getlogin()
        workDir = '/tmp/' + login
    
    if not os.path.exists(workDir):
        try:
            os.mkdir(workDir)
            user = os.environ['USER']
            subprocess.call(['chown', '-R', user + ':' + user, workDir])
        except OSError as exc:
            print("Cannot create work directory '" + workDir + "'")
            print(exc.strerror, exc.filename)
            sys.exit(1)
    os.environ['NF_WORK_DIR'] = workDir
    global work_test_dir
    if args.work_test_dir:
        work_test_dir = args.work_test_dir
    else:
        work_test_dir = workDir + '/test'
    global proj_test_dir; global src_test_dir
    global project; global projDir
    project = os.path.basename(os.path.abspath(os.environ['NF_DESIGN_DIR']))
    projDir = os.environ['NF_WORK_DIR'] + '/test/' + project
    proj_test_dir = work_test_dir + '/' + project
    if args.src_test_dir:
        src_test_dir = args.src_test_dir
    else:
        src_test_dir = os.environ['NF_DESIGN_DIR'] + '/test'

def identifyTests():
    test_name = ''; both_test_name = ''
    global length
    global number
    if args.major:
        both_test_name = 'both_' + args.major + '_' + args.minor
        if args.type == 'sim':
            test_name = 'sim_' + args.major + '_' + args.minor
        else:
            test_name = 'hw_' + args.major + '_' + args.minor
    else:
        both_test_name = 'both_'
        if args.type == 'sim':
            test_name = 'sim_'
        else:
            test_name = 'hw_'

    if args.packet_length:
        length = args.packet_length

    if args.packet_no:
        number = args.packet_no

    dirs = os.listdir(os.environ['NF_DESIGN_DIR'] + '/test')
    global tests;tests = []
    for test in dirs:
        if test.endswith(test_name) or test.endswith(both_test_name):
            tests.append(test)
    if len(tests) == 0:
        print('=== Error: No tests match ' + test_name + ' - exiting')
        sys.exit(0)

def prepareWorkDir():
    global project; global projDir

    if not os.path.exists(projDir):
        user = os.environ['USER']
        try:
            if not os.path.exists(os.environ['NF_WORK_DIR'] + '/test/'):
                os.mkdir(os.environ['NF_WORK_DIR'] + '/test')
                subprocess.call(['chown', '-R', user + ':' + user, os.environ['NF_WORK_DIR'] + '/test'])
            os.mkdir(projDir)
            subprocess.call(['chown', '-R', user + ':' + user, projDir])
        except OSError as exc:
            print('Error: Unable to create project directory ' + projDir)
            print(exc.strerror, exc.filename)
            sys.exit(1)
    # copy the connections directory for sim
    subprocess.call(['cp', '-r', '-p', src_test_dir + '/connections', projDir])

def prepareTestWorkDir(testName):
    dst_dir = proj_test_dir + '/' + testName
    src_dir = src_test_dir + '/' + testName
    # look for a test
    if args.type == 'sim':
        print('=== Setting up test in ' + dst_dir)
    # check if exists, make if doesn't, error if fail
    if not os.path.exists(dst_dir):
        try:
            os.mkdir(dst_dir)
        except OSError as exc:
            print('Error: Unable to create test directory ' + dst_dir)
            print(exc.strerror, exc.filename)
            sys.exit(1)
    # cp files to dst_dir
    if args.type == 'sim':
        for file in glob.glob(src_dir + '/*'):
            subprocess.call(['cp', '-r', '-p', file, dst_dir])
        for i in range(2):
            subprocess.call(['cp', '-r', '-p', src_test_dir + '/nf_interface_%d_log.axi' %i, dst_dir])
            subprocess.call(['cp', '-r', '-p', src_test_dir + '/nf_interface_%d_stim.axi' %i, dst_dir])
            subprocess.call(['cp', '-r', '-p', src_test_dir + '/nf_interface_%d_expected.axi' %i, dst_dir])
        subprocess.call(['cp', '-r', '-p', src_test_dir + '/dma_0_log.axi', dst_dir])
        subprocess.call(['cp', '-r', '-p', src_test_dir + '/dma_0_expected.axi', dst_dir])
        subprocess.call(['cp', '-r', '-p', src_test_dir + '/Makefile', dst_dir])
        subprocess.call(['cp', '-r', '-p', src_test_dir + '/reg_stim.log', dst_dir])
        subprocess.call(['cp', '-r', '-p', src_test_dir + '/reg_expect.axi', dst_dir])
        subprocess.call(['cp', '-r', '-p', src_test_dir + '/reg_stim.axi', dst_dir])

def buildSim():
    project = os.path.basename(os.path.abspath(os.environ['NF_DESIGN_DIR']))

    print('=== Work directory is ' + proj_test_dir)

    if args.dump:
        dumpfile = 'dump.v'
    else:
        dumpfile = ''

def verifyCI():
    if args.ci and args.ci != 'testcheck':
        print('Unknown continuous integration ' + args.ci + '. Supported CI programs: testcheck')
    if args.ci and not args.citest:
        print('The name of the test was not specified in \'citest\'')

    if args.ci != 'testcheck':
        testcheck.tcDisableOutput()

###### hw specific functions

def runTest(project, test):
    testDir = designDIr + '/' + testRoot + '/' + test
    if os.path.exists(testDir) and os.path.isdir(testDir):
        script = run + ' --hw'
        if args.seed:
            script += ' --seed ' + str(args.seed[0])
        if args.conn:
            script += ' --conn ' + str(args.conn)
        return runScript(project, test, script, REQUIRED)
    else:
        match = re.search(r'/(.*)\/([^\/]*)/', test)
        if match:
            script = match.group(2) + ' --hw'
            if args.seed:
                script += ' --seed ' + str(args.seed[0])
            if args.conn:
                script += ' --conn ' + str(args.conn)
            return runScript(project, match.group(1), script, REQUIRED)
        else:
            print('Error finding test file: ' + test)
            sys.exit(1)

def runGlobalSetup(project):
    return runScript(project, globalDir, setup, OPTIONAL)

def runGlobalTeardown(project):
    return runScript(project, globalDir, teardown, OPTIONAL)

def runCommonSetup(project):
    return runScript(project, commonDir, commonSetup, OPTIONAL)

def runCommonTeardown(project):
    return runScript(project, commonDir, commonTeardown, OPTIONAL)

def runLocalSetup(project, test):
    match = re.search(r'/(.*)\/([^\/]*)/', test)
    if match:
        return runScript(project, match.group(1), setup, OPTIONAL)
    else:
        return runScript(project, test, setup, OPTIONAL)

def runLocalTeardown(project, test):
    match = re.search(r'/(.*)\/([^\/]*)/', test)
    if match:
        return runScript(project, match.group(1), teardown, OPTIONAL)
    else:
        return runScript(project, test, teardown, OPTIONAL)

def runScript(project, subdir, script, required):
    testDir = designDIr + '/' + testRoot + '/' + subdir

    if os.path.exists(testDir):
        subprocess.call(['cp', '-r', '-p', testDir, proj_test_dir])
        user = os.environ['USER']
        subprocess.call(['chown', '-R', user + ':' + user, proj_test_dir + '/' + subdir])
    cmd = proj_test_dir + '/' + subdir + '/' + script
    if args.map:
        cmd += ' --map ' + args.map

    status = 0
    output = ''

    origDir = os.getcwd()

    try:
        os.chdir(proj_test_dir + '/' + subdir)
        # process = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        process = subprocess.Popen(cmd.split(), stderr=subprocess.STDOUT)
        output = process.communicate()[0]
        status = process.returncode
    except OSError as exc:
        if required == REQUIRED:
            print('Unable to run test ' + script + ' for project ' + project)
            print(exc.strerror, exc.filename)
        else:
            return (1, '')
    finally:
        os.chdir(origDir)

    if status != 0:
        print(cmd + ' exited with value ' + str(status))

    return (status == 0, output)

def printScriptOutput(result, output):
    if not args.quiet:
        if result:
            print('PASS')
        else:
            print('FAIL')
            print('Output was:')
            print(output)

####### method calls

handleArgs()
identifyRoot()

if args.common_setup:
    commonSetup = args.common_setup
else:
    commonSetup = setup
if args.common_teardown:
    commonTeardown = args.common_teardown
else:
    commonTeardown = teardown

identifyWorkDir()
prepareWorkDir()
identifyTests()
printEnv()

if args.type == 'sim':
    run_sim_test()
else:
    run_hw_test()

printEnv(dir_only=True)



