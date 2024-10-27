#############################################################################
# @file	logger.py
# @brief	Logger functions python script.
#
# @copyright 2021
# @version Version 1.0.0, Platform: Python 3.9.2
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

def text_to_file(file, text, mode):
    # Write in the text in the specified file.
    if text:
        try:
            imp_source = open(file, mode)
        except Exception as e:
            return "An error occurred while opening the file: %s" % (e)
        try:
            imp_source.write(text)
        except Exception as e:
            return "An error occurred while writing the text: %s" % (e)
        imp_source.close()
        return "The content was written. No Errors occurred."
    else:
        return "Nothing text to write. No Changes."


def write_log_entry():
    return




