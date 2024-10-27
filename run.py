#############################################################################
# @file	run_qtb.py
# @brief	Vunit python script. Automates the EDC VHDL Testbench execution.
#
# @copyright 2021
# @version Version 1.0.1, Platform: Python 3.9
#
# | Attribute | Value |
# | :-- | :-- |
# | Subversion revision | $Rev:$ |
# | Time of last change | $Date:$ |
# | Author(s) | @author Ziuwar |
#
# history 20201116_1700 : Initial Release, NOT tested,  (AS)
# history 20211116_1400 : Release 1.0.0, Tested  (AS)
# history 20211130_1100 : Release 1.0.1, Tested  (AS)
###############################################################################

from vunit import VUnit
import os
import bin as lib

def main():
    # Define the folder names here if changed from the released version. Other folders and paths can be customized in bin/paths.py.
    directories = {
        # >Implementation
        "implementation_source" : 'source',
        # >Testbench Directory
        "testbench_directory" : 'verification',
        # Testbench Subdirectory #
        # >>TB Source
        "testbench_source" : 'verification_source'}

    # Enable/disable automation features here. 1 = enabled, 0 = disabled.
    features  = {
        # Coverage merge and text report generation
        "coverage" : 1,
        # VCD file generation and screenshot capture (.tcl files for each testcase must exist)
        "screenshots" : 1,
        # DoxyGen HTML and PDF report 
        "doxygen" : 1}

    # Create the vunit process from the command line arguments
    qtb = VUnit.from_argv()
    # Determine the root directory for vunit (NOT ModelSim)
    root = os.path.dirname(os.path.abspath(__file__))

    ##### Post test area ######
    def post_run(results):
        print(lib.post_run_features(qtb, results, root, directories, features))

    # Configure ModelSim
    lib.modelsim_config(qtb, root, directories, features)

    # Delete the result files - "#" to switch to append mode
    print("Number of old results deleted: %s" % lib.remove_files(lib.find_results(lib.testbench_results_path(directories["testbench_directory"]), root, "*.vhd")))
    # Delete the old vcd files
    print("Number of old vcd files deleted: %s" % lib.remove_files(lib.find_results(lib.vcd_files_path(directories["testbench_directory"]), root, "*.vcd")))

    ##### Test execution ahead #####
    # Main process call
    qtb.main(post_run=post_run)

if __name__ == '__main__':
    main()
