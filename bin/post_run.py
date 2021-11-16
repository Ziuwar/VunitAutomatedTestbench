#############################################################################
# @file	post_run.py
# @brief	Post run functions python script. Automates the EDC VHDL Testbench execution.
#
# @copyright 2021 Avionik Straubing Entwicklungs GmbH
# @version Version 1.0.0, Platform: Python 3.9
#
# | Attribute | Value |
# | :-- | :-- |
# | Subversion revision | $Rev:$ |
# | Time of last change | $Date:$ |
# | Author(s) | @author Andreas Schroeder |
#
# history 20201116_1700 : Initial Release, NOT tested,  (AS)
# history 20211116_1400 : Release 1.0.0, Tested  (AS)
###############################################################################

from subprocess import STDOUT, check_output
import glob
import os

import bin as lib

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
def merge_cover(coverage_ucdb_path, qtb, results):
    try:
        results.merge_coverage(coverage_ucdb_path)
        if qtb.get_simulator_name() == "ghdl":
            coverage_merge_out = check_output(["gcovr", coverage_ucdb_path], stderr = STDOUT)
            lib.text_to_file(lib.merge_log()[0], coverage_merge_out.decode(), lib.merge_log()[1])
    except Exception as e:
        print("An error occurred while mergeing the coverage files: %s" % (e))

# Creates a text report from the ucdb file given
# vcover report -file ".//coverage/CoverageCombined.txt" -all -code b -verbose ".//coverage/ucdb/coverage_data"
def vcover_text_report(text_report_path, combined_ucdb_path):
    try:
        print('\nGenerating the coverage text report...')
        command = 'vcover report -output ' + text_report_path + ' -all -code bf -verbose ' + combined_ucdb_path # Format the command string
        cover_out = check_output(command, stderr = STDOUT)   # Send command to PowerShell
        lib.text_to_file(lib.vcover_log()[0], cover_out.decode(), lib.vcover_log()[1])
        print("Coverage text report generation done!")
    except Exception as e:
        print('An error occurred while creating the text coverage report: %s' %(e))

# Generate vcd files from the ModelSim log files (wlf). wlf2vcd.exe is used for that.
def wlf_to_vcd(results, path_vcd):
    command = ""
    vcd_out = ""
    try:
        report = results.get_report()
        # print(report.output_path)
        print("\nStart of .vcd file generation...")
        for key, test in report.tests.items():
            # print(key), print(test.status), print(test.time), print(test.path), print(test.relpath)
            test_bl = post_run_blacklist(key)
            if test.status == 'passed' and test_bl["wlf_to_vcd"] == 1: 
                command = 'wlf2vcd.exe -o "' + path_vcd + key + '.vcd" ".\\vunit_out\\test_output\\' + test.relpath + '\\modelsim\\vsim.wlf"'
                vcd_out += 'Converting file ' + key + ' to vcd.\n'
                vcd_out += check_output(command, stderr = STDOUT).decode()
            elif test.status != 'passed':
                vcd_out += '\nFile ' + key + ' not converted, because the testrun failed.\n'
            elif test_bl["wlf_to_vcd"] == 0:
                vcd_out += '\nFile ' + key + ' not converted, the test was blacklisted.\n'
            else:
                vcd_out += '\nFile ' + key + ' not converted, an unknown error occurred.\n'
        lib.text_to_file(lib.vcd_log()[0], vcd_out, lib.vcd_log()[1])
        print("All vcd files for passed and not blacklisted files are generated!")
    except Exception as e:
        print("An error occurred while converting the wlf files: %s" % (e))

# Generate screenshots with gtkwave tcl files, files in subfolder waveforms are parsed
def generate_screenshots(root_dir, waveform_dir, gtkwave_dir, results):
    try:
        report = results.get_report()   # Only passed tests shall be evaluated
        os.chdir(waveform_dir)          # Change directory to execute gtkwave in the this directory
        print("\nStart screenshot creation with GtkWave...")
        for key, item in report.tests.items():  # Go through all executed tests
            test_bl = post_run_blacklist(key)
            if item.status == 'passed' and test_bl.get("screenshot") == 1:  # Check if the status of the test was passed.
                if glob.glob(key + '.tcl'):     # Check if the tcl file can be found
                    gtkwave_command = gtkwave_dir + 'gtkwave.exe -T ' + key +'.tcl'
                    gtkwave_out = check_output(gtkwave_command, stderr = STDOUT) # Execute the gtkwave call command
                else:
                    print('\nNo screenshot created for file ' + key + ', tcl file not found.\n')
            elif item.status != 'passed':
                print('\nNo screenshot created for file ' + key + ', the testrun failed.\n')
            elif test_bl.get("screenshot") == 0:
                print('\nNo screenshot created for file ' + key + ', the test was blacklisted.\n')
            else:
                print('\nAn unknown error orrcured in test '+ key + '\n')
            lib.text_to_file(lib.gtkwave_log()[0], gtkwave_out.decode(), lib.gtkwave_log()[1])
        os.chdir(root_dir)  # Change the folder back to run.py root
        print("Screenshot generation done!")
    except Exception as e:
        print('An error occurred while generating the screenshots: %s' % (e))

# Execute doxygen an generate the documentation
def doxygen_report(root_dir, tb_dir, doxyfile_name):
    command = "doxygen.exe " + doxyfile_name
    try:
        print("\nStart of documentation generation with DoxyGen...")
        os.chdir(tb_dir)
        doxy_output = check_output(command, stderr = STDOUT) # Execute Doxygen
        os.chdir(root_dir)
        lib.text_to_file(lib.doxygen_log()[0], doxy_output.decode(), lib.doxygen_log()[1]) 
        print("Documentation generation done!")
    except Exception as e:
        print('An error occurred while running DoxyGen: %s' % (e))