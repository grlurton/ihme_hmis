gps <- read.csv('J://Project/phc/nga/nmis/Health_Mopup_and_Baseline_NMIS_Facility.csv')

out <- subset(gps , select = c(facility_name , latitude , longitude))


write.csv(out , 'J://Project/dot_map/facilities_gps_input.csv')
