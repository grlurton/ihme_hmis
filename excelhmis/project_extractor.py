'''
David Phillips
3/10/2015
Basic extraction script. This accomplishes the following:
1. Replace org_unit, category and element ID's with names
2. Identify the parent, 2nd parent etc for each organizational unit
3. Save a subset of the main data file with user-specified variables (wide), in the user-specified location

================================================================================
Requires user to supply the following items. Currently, they are supplied just by creating objects in memory and then executing this script:
iso3 - iso3 for country of interest
country - country name in lower case
varList - an object of class list containing one or more element IDs which the user ultimately wants to work with
outputLocation - an object of class str containing a valid output location (probably a csv file)
'''

'''
TO DO:
Generalize to take locations of input files too.
Improve argument handling so that the user can pass arguments rather than altering lines 39/40.
Fill in section that labels organization units with parents
Reference an iso3 table to look up country name
'''

# set up python
# --------------
import sys, platform, os, psutil
import numpy as np
import pandas as pd
if platform.system()=='Windows': j = 'J:'
else: j = '/home/j'

# inputs
iso3 = 'ken'
country = 'kenya'
varList = ['xiaJWeXNYif', 'L2dPeH9VkBc', 'h1GlCYbIQvU', 'OyddF1qflzP', 'ku80YRejJPg', 'K1Zzhafeukq']
outputLocation = j + '/Project/Evaluation/GAVI/hmis/'+iso3+'/data/vaccine_extract.csv'

iso3 = 'zmb'
country = 'zambia'
varList = [81, 126, 127, 128, 392, 393, 625, 626, 627, 628, 629]
outputLocation = j + '/Project/Evaluation/GAVI/hmis/'+iso3+'/data/vaccine_extract.csv'

# directories and files
dir = j + '/Project/dhis/'+country+'/extracted_data'
dataFile = dir + '/data_'+country+'.csv'
elementIDFile = dir + '/data_elements.csv'
categoryIDFile = dir + '/data_categories.csv'
orgIDFile = dir + '/org_units_description.csv'

# check inputs
assert isinstance(varList, list), 'The varList input must be a list'
assert isinstance(outputLocation, str), 'The outputLocation input must be a string'

# make sure it's safe to run
size = os.path.getsize(dataFile)
availableMemory = psutil.phymem_usage().available
if not size<availableMemory: raise AssertionError('Not enough memory! Switch to a bigger computer.')


# load and subset data file
# -------------------------
print 'Loading data from: ' + dataFile
data = pd.read_csv(dataFile, sep=',', usecols=['org_unit_ID', 'period', 'data_element_ID', 'category', 'value'])
data = data[data['data_element_ID'].isin(varList)]


# drop complete duplicates assuming they are unwanted
# ---------------------------------------------------
data = data.drop_duplicates()


# replace element IDs with names
# ------------------------------
print 'Merging element IDs'
elementIDs = pd.read_csv(elementIDFile, sep=',', usecols=['data_element_ID', 'data_element_name'])
elementIDs = elementIDs[elementIDs['data_element_ID'].isin(varList)]
elementIDs = elementIDs.drop_duplicates()
data = pd.merge(data, elementIDs, how='left', left_on='data_element_ID', right_on='data_element_ID') 


# replace category IDs with names
# -------------------------------
print 'Merging category IDs'
categoryIDs = pd.read_csv(categoryIDFile, sep=',', usecols=['category_ID', 'category_name'])
categoryList = data['category'].unique()
categoryIDs = categoryIDs[categoryIDs['category_ID'].isin(categoryList)]
data = pd.merge(data, categoryIDs, how='left', left_on='category', right_on='category_ID') 
data = data.drop('category_ID', axis=1)


# replace organizational unit IDs with names
# ------------------------------------------
print 'Merging organizational unit IDs'
orgUnitIDs = pd.read_csv(orgIDFile, sep=',', usecols=['org_unit_ID', 'name'])
orgUnitIDs = orgUnitIDs.drop_duplicates()

# label each org unit with its parents
# FILL IN

# some org_units don't have names, just use their code
orgUnitIDs['name'][orgUnitIDs['name']=='..']=orgUnitIDs['org_unit_ID'][orgUnitIDs['name']=='..']

# actually merge
data = pd.merge(data, orgUnitIDs, how='left', left_on='org_unit_ID', right_on='org_unit_ID') 

# replace missing with ID
na = pd.isnull(data['name'])
data['name'].loc[na,] = data['org_unit_ID'].loc[na,]


# unstack from long to wide
# -------------------------
data = data.drop('data_element_ID', axis=1)
data = data.set_index(['org_unit_ID', 'period', 'category', 'name', 'category_name', 'data_element_name']).unstack('data_element_name')
data.columns = data.columns.droplevel()
data = data.reset_index()


# save
# ----
print 'Saving extract to: ' + outputLocation
data.to_csv(outputLocation, index=False)
