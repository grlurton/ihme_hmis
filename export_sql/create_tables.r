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
dbUser <- readline(prompt = 'Please enter username : ')
dbPassword <-  readline(prompt = 'Please enter password : ')

# Database host name
dbHost = 'sandbox-db'

# Database name
dbName <- 'hmis'
# ----------------------------------------------------


# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Table and columns

# Names of tables
tables = c('data_values', 'organization_units', 'data_elements', 'groups' )

# Flat file locations
dir = paste0(j, '/Project/dhis/zambia/extracted_data/')

files = list(
	'data_values' = paste0(dir, 'data_zambia.csv'),
	'organization_units' = paste0(dir, 'org_units_description.csv'),
	'data_elements' = paste0(dir, 'data_elements.csv'),
	'groups' = paste0(dir, 'data_categories.csv')
)

# Columns
data_structure <- read.csv('structure/data_structure.csv' , stringsAsFactors = FALSE)
data_structure[is.na(data_structure)] <- ''


columns <- list()
for (table in unique(data_structure$table)){
  columns[[table]] <- data_structure$column[data_structure$table == table]
}


# Column types
columnTypes <- list()
for (tab_value in unique(data_structure$table)){
  types <- c()
  table_data <- subset(data_structure , table == tab_value, select = c(type , default , nullable , character_set , extra))
  for (var in seq(1,nrow(table_data))){
    a <- paste(table_data[var,] , collapse = " ")
    types <- c(types , a)
  }
  columnTypes[[tab_value]] <- types
}


# Primary keys
primary_keys <- read.csv('structure/primary_keys.csv' , stringsAsFactors = FALSE)
primary_keys[is.na(primary_keys)] <- ''
primaryKeys <- list()
for (table in unique(primary_keys$table)){
  primaryKeys[[table]] <- primary_keys$primary_key[primary_keys$table == table]
}
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Create database

# set up database connection
con = dbConnect(MySQL(), user=dbUser, password=dbPassword, host=dbHost, dbname=dbName)

# create tables
for(table in tables) {
	# drop table if exists
  print(table)
	dbGetQuery(con, paste0('DROP TABLE IF EXISTS ', table, ';'))
  
	# set up string to create blank table 
	createString = paste0('CREATE TABLE ', dbName, '.', table, ' (')
	#print(createString)
	c=1
	for(column in columns[[table]]) {
	  print(paste0('     ' , column))
		type = columnTypes[[table]][c]
		#print(type)
		createString = paste0(createString, ' ', column, ' ', type, ', ')
		c=c+1
	}
	primaryKey = primaryKeys[[table]]
	createString = paste0(createString, ' PRIMARY KEY (', primaryKey, '));')
	
	# create blank table
	dbGetQuery(con, createString)
	
	# import data table from disk
	dbGetQuery(con, paste0('LOAD DATA LOCAL INFILE \'', 
					files[[table]], '\' INTO TABLE ', 
					table, ' FIELDS TERMINATED BY \',\' IGNORE 1 LINES;'))
}

dbGetQuery(con, 'ALTER TABLE data_values ADD FOREIGN KEY (indicator_ID) REFERENCES data_elements (data_element_ID);')


dbDisconnect(con)
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------