#############################################################################
# @file	paths.py
# @brief	Vunit python script. Automates the EDC VHDL Testbench execution.
#
# @copyright 2021
# @version Version 1.0.0, Platform: Python 3.9
#
# | Attribute | Value |
# | :-- | :-- |
# | Subversion revision | $Rev:$ |
# | Time of last change | $Date:$ |
# | Author(s) | @author Ziuwar |
#
# history 20201116_1700 : Initial Release, NOT tested,  (AS)
# history 20211116_1400 : Release 1.0.0, Tested  (AS)
###############################################################################

# Implementation, testbench and testbench source paths
def implementation_src (implementation_source):
    return './' + implementation_source + '/'
def testbench_dir(testbench_directory):
    return './' + testbench_directory + '/'
def testbench_source(testbench_directory,testbench_source):
    return testbench_dir(testbench_directory) + "/" + testbench_source + '/'

# Coverage path 
def ucdb_merge_path(testbench_directory):
    coverage_report = 'coverage'    # Coverage Report Subfolder
    ucdb_merge = 'ucdb'             # Ucdb Merge Subfolder
    ucdb_filename = 'coverage_data' # Ucdb file name - the ucdb suffix is added in the command line call
    return testbench_dir(testbench_directory) + coverage_report + '/' + ucdb_merge + '/' + ucdb_filename

# Coverage report path and filename
def coverage_report_path(testbench_directory):
    coverage_report = 'coverage'    # Coverage Report Subfolder
    report_filename = 'CoverageCombined.txt'
    return testbench_dir(testbench_directory) + coverage_report + '/' + report_filename

# Path to the waveform directory
def waveforms_path(testbench_directory):
    waveforms_directory = 'waveforms'
    return testbench_dir(testbench_directory) + '/' + waveforms_directory + '/'

# Path to the vcd files
def vcd_files_path(testbench_directory):
    waveforms_directory = 'waveforms'
    vcd_directory = 'vcd'
    return '.\\'+ testbench_directory +'\\'+ waveforms_directory +'\\'+ vcd_directory +'\\' # Backslash is needed, exe don't want /

# Path to the modelsim do file
def modelsim_do_file_path(testbench_directory):
    do_file_directory = 'modelsim_init'
    do_file_name = 'gui_init.do'
    return testbench_dir(testbench_directory) + do_file_directory + '/' + do_file_name

# Path to the testbench report files
def testbench_results_path(testbench_directory):
    results_directory = "results"
    return testbench_dir(testbench_directory) + results_directory + '/'

# GtkWave exe path
def gtkwave_dir():
    gtkwave_directory = 'gtkwave'
    return "..\\" + gtkwave_directory + "\\bin\\" # Function generate_screenshots() changes the root folder to the waveforms directory

# DoxyGen config file name
def doxyfile_path():
    doxyfile_subfolder = 'doxygen_report'
    doxyfile_name = 'Doxyfile'
    return ".\\" + doxyfile_subfolder + "\\" + doxyfile_name # Function doxygen_report() report changes the root folder to the TB directory 

# Log file paths - DoxyGen log
def doxygen_log():
    log_name = "doxygen_log.txt"
    logs_subfolder = "logs"
    write_mode = "w"
    return ["./" + logs_subfolder + "/" + log_name, write_mode]

# Log file paths - GtkWave log
def gtkwave_log():
    log_name = "gtkwave_log.txt"
    logs_subfolder = "logs"
    write_mode = "a"
    return ["../../" + logs_subfolder + "/" + log_name, write_mode]

# Log file paths - Vcd generation log
def vcd_log():
    log_name = "vcd_log.txt"
    logs_subfolder = "logs"
    write_mode = "w"
    return ["./" + logs_subfolder + "/" + log_name, write_mode]

# Log file paths - Vcover log
def vcover_log():
    log_name = "vcover_log.txt"
    logs_subfolder = "logs"
    write_mode = "w"
    return ["./" + logs_subfolder + "/" + log_name, write_mode]

# Log file paths - Coverage merge log
def merge_log():
    log_name = "coverage_merge_log.txt"
    logs_subfolder = "logs"
    write_mode = "w"
    return ["./" + logs_subfolder + "/" + log_name, write_mode]
