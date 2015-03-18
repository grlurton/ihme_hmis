'''
David Phillips
3/17/2015

Prep standardized IHME data team files in the typical "GHDx" format
Originally built for J:/DATA/ZMB/HMIS
Outputs a massive file in the standard format
================================================================================
'''

'''
TO DO:
Codify data like data_kenya.csv
Generalize to be a function
Reference an iso3 table to look up country name
'''


# set up python
# --------------
import sys
import numpy as np
import pandas as pd
import platform
import os
sys.stdout.flush() # real time output of messages

# inputs
iso3 = 'ZMB'
country = 'zambia'
extension = 'XLS'
pattern = '2011_2014' # a specific pattern to use to identify included files
pattern = 'ZMB_MUCHINGA_MPIKA_HMIS_2011_2014_SDA_HIV_CARE_Y2015M01D30' # a specific pattern to use to identify included files
sheetName = 'Sheet 1'

# directories and files
if platform.system()=='Windows': j = 'J:'
else: j = '/home/j'
inDir = j + '/DATA/' + iso3 + '/HMIS'
outDir = j + '/Project/dhis/' + country + '/extracted_data'
dataFile = outDir + '/data_' + country + '.csv'
elementIDFile = outDir + '/data_elements.csv'
categoryIDFile = outDir + '/data_categories.csv'
orgIDFile = outDir + '/org_units_description.csv'


# prep data
# ---------
# identify files
files = os.listdir(inDir)
extLength = len(extension)
files_xls = [f for f in files if f[-extLength:] == extension and pattern in f]
nFiles = str(len(files_xls))

# append files
print 'Appending ' + nFiles + ' data files containing pattern ' + extension + ' and ' + pattern + ' from ' + inDir
data = pd.DataFrame()
for f, file in enumerate(files_xls):
    print f,
    df = pd.read_excel(inDir + '/' + file, sheetName)
    data = data.append(df)

# format into unicode
    
# codify data

# output data
# -----------
# make unicode compatible
data.to_csv(dataFile)
