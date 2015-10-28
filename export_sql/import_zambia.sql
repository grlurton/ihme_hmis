-- Add a check to see if the country has already been added

INSERT INTO country (country_name)
VALUES ('Zambia') ;

CREATE TABLE `hmis`.`passage`(
	`org_unit_ID`	INT ,
    `name` varchar(80)
   
    );


LOAD DATA LOCAL INFILE "J:/Project/dhis/zambia/extracted_data/org_units_description.csv"
INTO TABLE hmis.passage 
	FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n' 
	IGNORE 1 LINES ;


ALTER TABLE hmis.passage
	ADD  `country_ID` varchar(25) 
    DEFAULT 'Zambia'
    NOT NULL ;

