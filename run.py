#############################################################################
# @file	run_qtb.py
# @brief	Vunit python script. Automates the EDC VHDL Testbench execution.
#
# @copyright 2020 Avionik Straubing Entwicklungs GmbH
# @version Version X.X.X, Platform: Python 3.8
#
# | Attribute | Value |
# | :-- | :-- |
# | Subversion revision | $Rev:$ |
# | Time of last change | $Date:$ |
# | Author(s) | @author Andreas Schroeder |
#
# history 20201116_1700 : Initial Release, NOT tested,  (AS)
###############################################################################

# Include area
from vunit import VUnit, ui
from os.path import join, dirname
from pathlib import Path
from subprocess import call, check_output
import glob
import os
import sys

# Create the vunit process from the command line arguments
qtb = VUnit.from_argv()
# Determine the root directory for vunit (NOT ModelSim)
root = os.path.dirname(os.path.abspath(__file__))
# Path for the combined coverage result. The folders MUST exist.
coverage_ucdb_path = "./coverage/ucdb/coverage_data"

##### Post test area ######
def post_run(results):
    # Merges the coverage results
    merge_cover(results)
    # Creates the text coverage result report from the merged ucdb file
    print(vcover_text_report(".//coverage/CoverageCombined.txt", coverage_ucdb_path))
    # Generates vcd files from ModelSims wlf file format. WARNING: 3 seconds of data require approx. 500 MB of hard disk space (1 ns resolution).
    wlf_to_vcd(results)
    # Generate screenshots using gtkwave and tcl files for setup
    print(generate_screenshots(root, "waveforms", "..\\gtkwave\\bin\\", results))
    # Doxygen html and pdf report generation 
    #print(doxygen_report(".\\doxygen_report\\Doxyfile"))
    #Final Message
    print("!!Testbench execution done!!")

##### Function Definitions #####
def post_run_blacklist(test_name):
    blacklist_dict = { # Return dictionary for blacklist tests: 0 -> Test on blacklist, 1 -> Test NOT blacklisted
        "wlf_to_vcd": 1,
        "screenshot": 1,
        }
    # Wlf to vcd conversion BL
    wlf_to_vcd = ["lib.e_timerqualification_tb.500_ms_reset_signal_tb",
                  "lib.e_timerqualification_tb.1_sec_reset_signal_tb",
                  "lib.e_timerqualification_tb.30_sec_reset_signal_tb",
                  "lib.e_timerqualification_tb.34_sec_reset_signal_tb",
                  "lib.e_timerqualification_tb.60_sec_reset_signal_tb",
                  "lib.e_timerqualification_tb.90_sec_reset_signal_tb",
                  "lib.e_timerqualification_tb.500_ms_timing_pulse_tb",
                  "lib.e_timerqualification_tb.1_sec_timing_pulse_tb",
                  "lib.e_timerqualification_tb.30_sec_timing_pulse_tb",
                  "lib.e_timerqualification_tb.34_sec_timing_pulse_tb",
                  "lib.e_timerqualification_tb.60_sec_timing_pulse_tb",
                  "lib.e_timerqualification_tb.90_sec_timing_pulse_tb",
                  "lib.e_selftesttopqualification_tb.no_error_full_run_tb",
                  "lib.e_ads1018sequencerqualification_tb.adc_readback_invalid_tb"]
    # Screenshot BL
    screenshot_bl = ["lib.e_timerqualification_tb.500_ms_reset_signal_tb",
                     "lib.e_timerqualification_tb.1_sec_reset_signal_tb",
                     "lib.e_timerqualification_tb.30_sec_reset_signal_tb",
                     "lib.e_timerqualification_tb.34_sec_reset_signal_tb",
                     "lib.e_timerqualification_tb.60_sec_reset_signal_tb",
                     "lib.e_timerqualification_tb.90_sec_reset_signal_tb",
                     "lib.e_timerqualification_tb.500_ms_timing_pulse_tb",
                     "lib.e_timerqualification_tb.1_sec_timing_pulse_tb",
                     "lib.e_timerqualification_tb.30_sec_timing_pulse_tb",
                     "lib.e_timerqualification_tb.34_sec_timing_pulse_tb",
                     "lib.e_timerqualification_tb.60_sec_timing_pulse_tb",
                     "lib.e_timerqualification_tb.90_sec_timing_pulse_tb",
                     "lib.e_selftesttopqualification_tb.no_error_full_run_tb",
                     "lib.e_ads1018sequencerqualification_tb.adc_readback_invalid_tb"]
                     
    # Check if name given from function call is blacklisted for each feature.
    for test_on_bl in wlf_to_vcd:
        if test_name == test_on_bl:
            blacklist_dict["wlf_to_vcd"] = 0
    for test_on_bl in screenshot_bl:
        if test_name == test_on_bl:
            blacklist_dict["screenshot"] = 0
    return blacklist_dict

# Pass the coverage data to the main process
def merge_cover(results):
    try:
        results.merge_coverage(coverage_ucdb_path)
        if qtb.get_simulator_name() == "ghdl":
            call(["gcovr", coverage_ucdb_path])
    except Exception as e:
        print("An error occurred while mergeing the coverage files: %s" % (e))

# Generate vcd files from the ModelSim log files (wlf). wlf2vcd.exe is used for that.
def wlf_to_vcd(results):
    command = ""
    try:
        report = results.get_report()
        # print(report.output_path)
        print("\n")
        for key, test in report.tests.items():
            # print(key), print(test.status), print(test.time), print(test.path), print(test.relpath)
            test_bl = post_run_blacklist(key)
            if test.status == 'passed' and test_bl["wlf_to_vcd"] == 1: 
                command = 'wlf2vcd.exe -o ".\\waveforms\\vcd\\' + key + '.vcd" ".\\vunit_out\\test_output\\' + test.relpath + '\\modelsim\\vsim.wlf"'
                print('Coverting file ' + key + ' to vcd.')
                check_output(command)
            elif test.status != 'passed':
                print('\nFile ' + key + ' not converted, because the testrun failed.\n')
            elif test_bl["wlf_to_vcd"] == 0:
                print('\nFile ' + key + ' not converted, the test was blacklisted.\n')
            else:
                print('\nFile ' + key + ' not converted, an unknown error occurred.\n')                
        print("All vcd files for passed and not blacklisted files are generated!\n")
    except Exception as e:
        print("An error occurred while converting the wlf files: %s" % (e))

# Finds all files in a directory given with the extension given (str, str)
def find_results(search_dir, extension):
    new_path = ""
    try:
        root_dir = os.path.dirname(os.path.abspath(__file__))   # The originating directory
        new_path = join(root_dir, search_dir)                   # Join the actual path and search directory
        os.chdir(new_path)                                      # Change into given directory
        files = glob.glob(join(new_path, extension))            # Find the files. Returns an absolute path.
        os.chdir(root_dir)                                      # Change directory back to the originating one
        return files
    except Exception as e:
        print('An error occurred finding the files: %s' % (e))

# Removes the files in the list (absolute or relative path as string)
def remove_files(files_found):
    file_count = 0
    try:
        for file in files_found:    # Loop through the files given
            os.remove(file)         # Remove the file
            file_count += 1         # Count how many files were deleted
        return file_count
    except Exception as e:
        print('An error occurred deleting the files: %s' %(e))

# Creates a text report from the ucdb file given
# vcover report -file ".//coverage/CoverageCombined.txt" -all -code b -verbose ".//coverage/ucdb/coverage_data"
def vcover_text_report(text_report_path, combined_ucdb_path):
    try:
        command = 'vcover report -output ' + text_report_path + ' -all -code bf -verbose ' + combined_ucdb_path # Format the command string
        return check_output(command).decode()   # Send command to PowerShell
    except Exception as e:
        print('An error occurred while creating the text coverage report: %s' %(e))

# Execute doxygen an generate the documentation
def doxygen_report(doxyfile_name):
    command = "doxygen.exe " + doxyfile_name
    try:
        return check_output(command).decode() # Execute Doxygen
    except Exception as e:
        print('An error occurred while running DoxyGen: %s' % (e))

# Generate screenshots with gtkwave tcl files, files in subfolder waveforms are parsed
def generate_screenshots(root_dir, waveform_dir, gtkwave_dir, results):
    try:
        report = results.get_report()   # Only passed tests shall be evaluated
        os.chdir(waveform_dir)          # Change directory to execute gtkwave in the this directory
        for key, item in report.tests.items():  # Go through all executed tests
            test_bl = post_run_blacklist(key)
            if item.status == 'passed' and test_bl.get("screenshot") == 1:  # Check if the status of the test was passed.
                if glob.glob(key + '.tcl'):     # Check if the tcl file can be found
                    gtkwave_command = gtkwave_dir + 'gtkwave.exe -T ' + key +'.tcl'
                    check_output(gtkwave_command).decode()  # Execute the gtkwave call command
                else:
                    print('\nNo screenshot created for file ' + key + ', tcl file not found.\n')
            elif item.status != 'passed':
                print('\nNo screenshot created for file ' + key + ', the testrun failed.\n')
            elif test_bl.get("screenshot") == 0:
                print('\nNo screenshot created for file ' + key + ', the test was blacklisted.\n')
            else:
                print('\nAn unknown error orrcured in test '+ key + '\n')
        os.chdir(root_dir)  # Change the folder back to run.py root
    except Exception as e:
        print('An error occurred while generating the screenshots: %s' % (e))

##### Add files and compile options fore those files in the library #####
# Create the testbench library object
qtb_lib = qtb.add_library("lib")
# Add the source files to the library
qtb_lib.add_source_files(join(root, '../src', "*.vhd"))

# Enable the code coverage for the source files
qtb_lib.set_compile_option("modelsim.vcom_flags", ["+cover=bf"])
qtb_lib.set_compile_option("modelsim.vlog_flags", ["+cover=bf"])
qtb_lib.set_compile_option("enable_coverage", True)

# Add the testbench source files
qtb_lib.add_source_files(join(root, 'src_qtb', '*.vhd'))

# Enable dataset snapshot in ModelSim - Generates one wlf file in the respective test_output folder. It is stored in the modelsim subfolder.
qtb_lib.set_sim_option('modelsim.init_files.after_load', ['./modelsim_init/gui_init.do'])
 
# GenericToBePastToDut1 = [640, 480]
# GenericToBePastToDut2 = [1920, 1080]
# EncodedGenericToBePastToDut1 = ", ".join(map(str, GenericToBePastToDut1)) # build string to pass it to the VHDL testbench
# EncodedGenericToBePastToDut2 = ", ".join(map(str, GenericToBePastToDut2)) # build string to pass it to the VHDL testbench

# testbench = qtb_lib.test_bench("e_Dut_tb")
# testcase_1 = testbench.test("Testcase_1")

# generics = dict(EncodedGenericToBePastToDut=EncodedGenericToBePastToDut1)
# generics2 =dict(EncodedGenericToBePastToDut=EncodedGenericToBePastToDut2)
# testcase_1.add_config(name='Config1', generics=generics)
# testcase_1.add_config(name='Config2', generics=generics2)

# Enable the coverage in modelsim (checks out the licence)
qtb_lib.set_sim_option("enable_coverage", True)

# Set modelsim vsim simulation time resolution, available values of simulator resolution are (refer to modelsim User's Manual p. 101):
# 1 fs, 10 fs, 100 fs, 1 ps, 10 ps, 100 ps, 1 ns, 10 ns, 100 ns, 1 us, 10 us, 100 us, 1 ms, 10 ms, 100 ms, 1 s, 10 s, 100 s
qtb.set_sim_option("modelsim.vsim_flags", ["-t 1ns"])

# Delete the result files - "#" to switch to append mode
print("Number of old results deleted: %s" % remove_files(find_results("results", "*.vhd")))
# Delete the old vcd files
print("Number of old vcd files deleted: %s" % remove_files(find_results("waveforms\\vcd\\", "*.vcd")))

##### Test execution ahead #####
# Main process call
qtb.main(post_run=post_run)
