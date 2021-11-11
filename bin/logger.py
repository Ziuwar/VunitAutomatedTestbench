#############################################################################
# @file	logger.py
# @brief	Logger functions python script.
#
# @copyright 2020 Avionik Straubing Entwicklungs GmbH
# @version Version X.X.X, Platform: Python 3.9.2
#
# | Attribute | Value |
# | :-- | :-- |
# | Subversion revision | $Rev:$ |
# | Time of last change | $Date:$ |
# | Author(s) | @author Andreas Schroeder |
#
# history 20211109_1600 : Initial Release, NOT tested,  (AS)
###############################################################################

from os import mkdir
from os import path

def make_dir(dir):
    if dir:
        if path.isdir(dir):
            return 'The directory "' + dir + '" already exists. No change.'
        else:
            try:
                mkdir(dir)
                return 'The directory "' + dir + '" was created.'
            except Exception as e:
                return "An error occurred while creating the directory: %s" % (e)
    else:
        return "Error: Enter the name of a directory."
