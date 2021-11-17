#############################################################################
# @file	run_qtb.py
# @brief	Vunit python script. Automates the EDC VHDL Testbench execution.
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

from vunit import VUnit
import os
import bin as lib

def main():

    # >Implementation
    implementation_source = 'source'
    # >Testbench Directory
    testbench_directory = 'verification'
    # Testbench Subdirectory #
    # >>TB Source
    testbench_source = 'verification_source'

    # Create the vunit process from the command line arguments
    qtb = VUnit.from_argv()
    # Determine the root directory for vunit (NOT ModelSim)
    root = os.path.dirname(os.path.abspath(__file__))

    ##### Post test area ######
    def post_run(results):
        # Merges the coverage results
        lib.merge_cover(lib.ucdb_merge_path(testbench_directory), qtb, results)
        # Creates the text coverage result report from the merged ucdb file
        lib.vcover_text_report(lib.coverage_report_path(testbench_directory), lib.ucdb_merge_path(testbench_directory))
        # Generates vcd files from ModelSims wlf file format. WARNING: 3 seconds of data require approx. 500 MB of hard disk space (1 ns resolution).
        lib.wlf_to_vcd(results,lib.vcd_files_path(testbench_directory))
        # Generate screenshots using gtkwave and tcl files for setup
        lib.generate_screenshots(root, lib.waveforms_path(testbench_directory), lib.gtkwave_dir(), results)
        # Doxygen html and pdf report generation 
        lib.doxygen_report(root, lib.testbench_dir(testbench_directory),lib.doxyfile_path())
        #Final Message
        print("\nTestbench execution done!")

    # Configure ModelSim
    lib.modelsim_config(qtb, root, implementation_source, testbench_directory, testbench_source)

    # Delete the result files - "#" to switch to append mode
    print("Number of old results deleted: %s" % lib.remove_files(lib.find_results(lib.testbench_results_path(testbench_directory), root, "*.vhd")))
    # Delete the old vcd files
    print("Number of old vcd files deleted: %s" % lib.remove_files(lib.find_results(lib.vcd_files_path(testbench_directory), root, "*.vcd")))

    ##### Test execution ahead #####
    # Main process call
    qtb.main(post_run=post_run)

if __name__ == '__main__':
    main()
