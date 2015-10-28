USE `hmis` ;

LOAD DATA LOCAL INFILE 'c://users/grlurton/documents/ihmehmis/export_sql/iso3_dictionnary.csv' 
	INTO TABLE country
    FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n'
    IGNORE 1 LINES ;