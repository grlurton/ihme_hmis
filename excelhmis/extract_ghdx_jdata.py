from __future__ import division
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
Generalize to be a function
Reference an iso3 table to look up country name
'''


# set up python
# --------------
import sys, platform, os, string, random, psutil
import numpy as np
import pandas as pd

# inputs
iso3 = 'ZMB'
country = 'zambia'
extension = 'XLS'
pattern = '2011_2014' # a specific pattern to use to identify included files
sheetName = 'Sheet 1'

# directories and files
if platform.system()=='Windows': j = 'J:'
else: j = '/home/j'
inDir = j + '/DATA/' + iso3 + '/HMIS'
outDir = j + '/Project/dhis/' + country + '/extracted_data'
dataFile = outDir + '/data_' + country + '.csv'
elementIDFile = outDir + '/data_elements.csv'
orgIDFile = outDir + '/org_units_description.csv'
categoryIDFile = outDir + '/data_categories.csv'

# make sure it's safe to run
size = sum(os.path.getsize(inDir + '/' + f) for f in os.listdir(inDir) if os.path.isfile(inDir + '/' + f))
availableMemory = psutil.phymem_usage().available
if not size<availableMemory: raise AssertionError('Not enough memory! Switch to a bigger computer.')


# prep data
# ---------
# identify files
files = os.listdir(inDir)
extLength = len(extension)
files_xls = [f for f in files if f[-extLength:] == extension and pattern in f]
nFiles = len(files_xls)

# append files
print 'Appending ' + str(nFiles) + ' data files containing ' + extension + ' and ' + pattern + ' from ' + inDir
data = pd.DataFrame()
for f, file in enumerate(files_xls):
    progress = round(f/nFiles,3)*100
    sys.stdout.write("Progress: '%1.1f'%% \r" % progress) # print progress in place
    sys.stdout.flush() # real time output of messages
    df = pd.read_excel(inDir + '/' + file, sheetName)
    df['category_name'] = file # add category
    df = df.drop_duplicates() # it was discovered that at least ZMB_WESTERN_LUKULU_HMIS_2011_2014_SDA_CHN_Y2015M01D30.XLS has complete duplicates
    data = data.append(df)
    
# codify data
print 'Generating unique codes for data elements and organizational units...'
random.seed(1)

# elements
elementIDs = pd.DataFrame(columns=['data_element_ID', 'data_element_name'])
elementNames = data.Data.unique()
elementNames.sort()
for e, name in enumerate(elementNames):
    elementIDs = elementIDs.append(pd.Series([str(e), name], index=['data_element_ID', 'data_element_name']), ignore_index=True)

# organizational units
orgUnitIDs = pd.DataFrame(columns=['org_unit_ID', 'name'])
orgUnitNames = data['Organisation unit'].unique()
orgUnitNames.sort()
for o, name in enumerate(orgUnitNames):
    orgUnitIDs = orgUnitIDs.append(pd.Series([str(o), name], index=['org_unit_ID', 'name']), ignore_index=True)

# categories
categoryIDs = pd.DataFrame(columns=['category', 'category_name'])
categoryNames = data['category_name'].unique()
categoryNames.sort()
for c, name in enumerate(categoryNames):
    categoryIDs = categoryIDs.append(pd.Series([str(c), name], index=['category_ID', 'category_name']), ignore_index=True)

# merge ID's, drop names, rename period
data = pd.merge(data, elementIDs, how='left', left_on='Data', right_on='element_name')
data = pd.merge(data, orgUnitIDs, how='left', left_on='Organisation unit', right_on='name')
data = pd.merge(data, categoryIDs, how='left', left_on='category_name', right_on='category_name')
data = data.drop(['Data', 'element_name', 'Organisation unit', 'name', 'category_name'], axis=1)
data = data.rename(columns={'Period': 'period'})


# output data and codebooks
# -------------------------
print 'Saving %s...' % (dataFile)
data.to_csv(dataFile, encoding='utf-8', index=False)

print 'Saving %s...' % (elementIDFile)
elementIDs.to_csv(elementIDFile, encoding='utf-8', index=False)

print 'Saving %s...' % (orgIDFile)
orgUnitIDs.to_csv(orgIDFile, encoding='utf-8', index=False)

print 'Saving %s...' % (categoryIDFile)
categoryIDs.to_csv(categoryIDFile, encoding='utf-8', index=False)
