#############################################################################
# @file	__init__.py
# @brief	Vunit python script init file. Automates the EDC VHDL Testbench execution.
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

from bin.post_run import merge_cover
from bin.post_run import vcover_text_report
from bin.post_run import wlf_to_vcd
from bin.post_run import generate_screenshots
from bin.post_run import doxygen_report

from bin.pre_run import find_results
from bin.pre_run import remove_files

from bin.paths import implementation_src
from bin.paths import testbench_dir
from bin.paths import testbench_source
from bin.paths import ucdb_merge_path
from bin.paths import coverage_report_path
from bin.paths import waveforms_path
from bin.paths import vcd_files_path
from bin.paths import modelsim_do_file_path
from bin.paths import testbench_results_path
from bin.paths import gtkwave_dir
from bin.paths import doxyfile_path
from bin.paths import doxygen_log
from bin.paths import gtkwave_log
from bin.paths import vcd_log
from bin.paths import vcover_log
from bin.paths import merge_log

from bin.vunit_init import modelsim_config

from bin.logger import text_to_file