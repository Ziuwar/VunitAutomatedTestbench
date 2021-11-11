#############################################################################
# @file	pre_run.py
# @brief	Pre run functions python script. Automates the EDC VHDL Testbench execution.
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
# history 20211109_1600 : Initial Release, NOT tested,  (AS)
###############################################################################

from os.path import join
import glob
import os

# Finds all files in a directory given with the extension given (str, str)
def find_results(search_dir, root_dir, extension):
    new_path = ""
    try:
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