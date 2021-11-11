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

from vunit import VUnit
import os
import bin as lib

def main():

    # >Implementation
    implementation_source = 'src'
    # >Testbench Directory
    testbench_directory = 'qualification_tb'
    # Testbench Subdirectory #
    # >>TB Source
    testbench_source = 'src_qtb'

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
        print(lib.doxygen_report(root, lib.testbench_dir(testbench_directory), lib.doxyfile_path()))
        #Final Message
        print("!!Testbench execution done!!")

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