# ----------------------------------------------------------
# David Phillips, Grégoire Lurton
# 
# 5/18/2015
# Upload HMIS data as MySQL database
# ----------------------------------------------------------


# ---------------------------------------------------------------------------------------------------------
# Instructions:                                                                                       
# User must supply username and password for database (objects below)  
# User must supply paths a flat file of each table                                      
# ---------------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------------------------------------------------------
# To Do:                                                                                       
# Alter username and password to be more flexible. Either as arguments to this script or using groups                               
# --------------------------------------------------------------------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------------------------------------------------------
# Set up r
rm(list=ls())
library('RMySQL')
lapply( dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)
j = ifelse(Sys.info()[1]=="Windows", "J:", "/home/j")
# ------------------------------------------------------------------------------------------------------------------------------------


# ----------------------------------------------------
# Database settings

# Database username and password
dbUser <- readline('Please enter User Name : ')
dbPassword <- readline('Please enter Password : ')

# Database host name
dbHost = 'sandbox-db'

# Database name
dbName <- 'hmis'
# ----------------------------------------------------


# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Table and columns

# Names of tables
tables = c('data_values', 'organization_units', 'data_elements', 'groups')

# Flat file locations
dir = paste0(j, '/Project/dhis/zambia/extracted_data/')

files = list(
	'data_values' = paste0(dir, 'data_zambia.csv'),
	'organization_units' = paste0(dir, 'org_units_description.csv'),
	'data_elements' = paste0(dir, 'data_elements.csv'),
	'groups' = paste0(dir, 'data_categories.csv')
)

# Columns
columns = list(
	'data_values'=c('value_ID', 'organization_unit_ID', 'indicator_ID', 
					'age_ID', 'gender_ID', 'period', 'value', 'source_ID', 'NID'),
	'organization_units'=c('organization_unit_ID', 'organization_unit_name', 
							'organization_unit_start', 'organization_unit_end', 'group_pivot_ID' , 
							'country_ID'),
	'groups_pivot'=c('group_pivot_ID', 'organization_unit_ID', 'group_ID'),
	'groups'=c('group_ID', 'group_name'),
	'age'=c('age_ID', 'age_min', 'age_max'),
	'gender'=c('gender_ID', 'gender_name'),
	'source'=c('source_ID', 'source_name', 'source_date'),
	'data_elements'=c('data_element_ID', 'data_element_name', 'metadata_pivot_ID' ,
	                  'country_ID'),
	'metadata_pivot'=c('metadata_pivot_ID', 'data_element_ID', 'metadata_ID'),
	'metadata'=c('metadata_ID', 'metadata_label')
)

# Column types
columnTypes = list(
	'data_values'=c('INT NOT NULL AUTO_INCREMENT', 'INT NOT NULL', 'INT NOT NULL', 
					'INT NOT NULL', 'INT NOT NULL', 'VARCHAR(45)', 'INT', 'INT NOT NULL', 'INT NOT NULL'),
	'organization_units'=c('INT NOT NULL AUTO_INCREMENT', 'VARCHAR(45)', 
							'VARCHAR(45)', 'VARCHAR(45)', 'INT NOT NULL'),
	'groups_pivot'=c('INT NOT NULL AUTO_INCREMENT', 'INT NOT NULL', 'INT NOT NULL'),
	'groups'=c('INT NOT NULL AUTO_INCREMENT', 'VARCHAR(45)'),
	'age'=c('INT NOT NULL AUTO_INCREMENT', 'INT NOT NULL', 'INT NOT NULL'),
	'gender'=c('INT NOT NULL AUTO_INCREMENT', 'VARCHAR(45)'),
	'source'=c('INT NOT NULL AUTO_INCREMENT', 'VARCHAR(45)', 'VARCHAR(45)'),
	'data_elements'=c('INT NOT NULL AUTO_INCREMENT', 'VARCHAR(45)', 'INT NOT NULL'),
	'metadata_pivot'=c('INT NOT NULL AUTO_INCREMENT', 'INT NOT NULL', 'INT NOT NULL'),
	'metadata'=c('INT NOT NULL AUTO_INCREMENT', 'VARCHAR(45)')
)

# Primary keys
primaryKeys = list(
	'data_values'='value_ID',
	'organization_units'='organization_unit_ID',
	'groups_pivot'='group_pivot_ID',
	'groups'='group_ID',
	'age'='age_ID',
	'gender'='gender_ID',
	'source'='source_ID',
	'data_elements'='data_element_ID',
	'metadata_pivot'='metadata_pivot_ID',
	'metadata'='metadata_ID'
)
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Create database

# set up database connection
con = dbConnect(MySQL(), user=dbUser, password=dbPassword, host=dbHost, dbname=dbName)

# create tables
for(table in tables) {
	# drop table if exists
	dbGetQuery(con, paste0('DROP TABLE IF EXISTS ', table, ';'))

	# set up string to create blank table
	createString = paste0('CREATE TABLE `', dbName, '`.`', table, '` (')
	c=1
	for(column in columns[[table]]) {
		type = columnTypes[[table]][c]
		createString = paste0(createString, '`', column, '` ', type, ', ')
		c=c+1
	}
	primaryKey = primaryKeys[[table]]
	createString = paste0(createString, ' PRIMARY KEY (`', primaryKey, '`));')
	
	# create blank table
	dbGetQuery(con, createString)
	
	# import data table from disk
	dbGetQuery(con, paste0('LOAD DATA LOCAL INFILE \'', 
					files[[table]], '\' INTO TABLE ', 
					table, ' FIELDS TERMINATED BY \',\' LINES TERMINATED BY \'\n\';'))
}
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
