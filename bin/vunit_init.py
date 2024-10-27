#############################################################################
# @file	vunit_init.py
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

from os.path import join
import bin as lib

def modelsim_config(qtb,root,directories, features):
    ##### Add files and compile options fore those files in the library #####
    # Create the testbench library object
    qtb_lib = qtb.add_library("lib")
    # Add the source files to the library
    qtb_lib.add_source_files(join(root, lib.implementation_src(directories["implementation_source"]), "*.vhd"))

    if features["coverage"] == 1:
        # Enable the code coverage for the source files
        qtb_lib.set_compile_option("modelsim.vcom_flags", ["+cover=bf"])
        qtb_lib.set_compile_option("modelsim.vlog_flags", ["+cover=bf"])
        qtb_lib.set_compile_option("enable_coverage", True)

    # Add the testbench source files
    qtb_lib.add_source_files(join(root, lib.testbench_source(directories["testbench_directory"],directories["testbench_source"]), '*.vhd'))

    # Enable dataset snapshot in ModelSim - Generates one wlf file in the respective test_output folder. It is stored in the modelsim subfolder.
    qtb_lib.set_sim_option('modelsim.init_files.after_load', [lib.modelsim_do_file_path(directories["testbench_directory"])])

    if features["coverage"] == 1:
        # Enable the coverage in modelsim (checks out the license)
        qtb_lib.set_sim_option("enable_coverage", True)

    # Set modelsim vsim simulation time resolution, available values of simulator resolution are (refer to modelsim User's Manual p. 101):
    # 1 fs, 10 fs, 100 fs, 1 ps, 10 ps, 100 ps, 1 ns, 10 ns, 100 ns, 1 us, 10 us, 100 us, 1 ms, 10 ms, 100 ms, 1 s, 10 s, 100 s
    qtb.set_sim_option("modelsim.vsim_flags", ["-t 1ns"])