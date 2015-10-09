library(plyr)


#### Prepare the data from DHIS
## --------------------------------


## Keep Only malaria relevant data
malaria_data <- subset(data_fac , indicator_thematic_malaria == 1)

## For now just using 2 indicators
malaria_indicators <- c('Confirmed uncomplicated malaria' ,
                        'Confirmed uncomplicated malaria given ACT')

malaria_data <- subset(malaria_data , 
                       indicator_name %in%  malaria_indicators )

#########
## Imputation of missing data
#########

malaria_data$value <- as.numeric(as.character(malaria_data$value))
fac_coll <- ddply(malaria_data , .(Level2 , Level2ID , Level3 , Level3ID ,
                                   orgUnit , period , dataElement) , 
                  function(x) data.frame(value = sum(x$value)) , .progress = 'text')

## Function to create a full space of time and orgunits
create_full <- function(data){
  expand.grid(period = unique(data$period) ,
              orgUnit = unique(data$orgUnit))
}

library("reshape2")

## Function to take and reshape all data from a LGA and make the full space
make_ratio_data <- function(data , orgUnit , keep_dataElement){
  LGA <- unique(data$Level3ID[data$orgUnit == orgUnit])
  data <- subset(data , dataElement == keep_dataElement & Level3ID == LGA ,
                 select = c(period , value , orgUnit , Level3ID))
  full_space <- create_full(data)
  datab <- merge(data , full_space , 
                 by = c('orgUnit' , 'period') ,
                 all.y = TRUE , all.x = FALSE)
  datab$Level3ID <- LGA
  dataLong <- dcast(datab , 
                    period + Level3ID ~ orgUnit ,
                    value.var = 'value' , 
                    fun.aggregate = function(x) sum(x , na.rm = FALSE))
  dataLong
}

## Function that does the imputation by looking at the ratio of the data between two 
## on a given date and taking the median of estimations made
impute_value <- function(data , orgUnit){
  periods <- data$period
  num <- data[,orgUnit]
  den <- data[ , -which(names(data) %in% c('period',orgUnit,'Level3ID'))]
  ratio <- num / den
  mratio <- apply(ratio , MARGIN = 2 , FUN = function(x) median(x , na.rm = TRUE))
  imp <- den * mratio
  if(nrow(imp) > 1){
    impute <- round(apply(imp , MARGIN = 1 , FUN = function(x) median(x , na.rm = TRUE)) ,
                    0)
  }
  if(nrow(imp) <= 1){
    impute <- imp
  }
  out <- data[,orgUnit]
  out[is.na(out)] <- impute[is.na(out)]
  out[out > 5*median(out)] <- NA
  out[out < 0.05*median(out)] <- NA
  data.frame(periods , value = out , orgUnit)
}

## Overall imputation function
imputation <- function(data , orgUnit , keep_dataElement){
  data_ratio <- make_ratio_data(data , orgUnit , keep_dataElement)
  imputation <- try(impute_value(data_ratio , orgUnit))
  imputation
}


## Making the imputation
system.time(
imputed_data <- ddply(fac_coll , .(dataElement , Level2 , Level2ID , Level3 , Level3ID) , 
                      function(data){
                        out <- data.frame(periods = character() , 
                                          value = numeric() , 
                                          orgUnit = character())
                        n <- length(unique(data$orgUnit))
                        print(paste('Estimating LGA' , unique(data$Level3) , 'and his' ,n ,'facilities',
                              sep = ' '))
                        if(n > 2){
                          for(orgUnit in unique(data$orgUnit)){
                            print(paste('Estimating facility' , orgUnit ,
                                  sep = ' '))
                          
                            im <- imputation(data , orgUnit ,
                                             unique(data$dataElement))
                            out <- rbind(im , out)
                          }
                        }
                        if(n <= 2){ # LGA with one facility should not be imputed with 
                                      # this method
                            out <- data.frame(periods = data$period ,
                                             value = data$value , 
                                             orgUnit = data$orgUnit)
                            }
                        out
                        }, 
                      .progress = 'text')
)

##########
## Collapse to LGA level
##########

# aggregating function = average on 12 last months
collapse_sum <- function(data){
  data$value <- as.numeric(as.character(data$value))
  value <- sum(data$value , na.rm = TRUE)
  n_fac <- length(unique(data$orgUnit))
  data.frame(value , n_fac)
}

## Collapse facility data on the last year

### Generate a one year period finishing at the end of available data
make_period <- function(max_date){
  year <- as.numeric(substr(max_date , 1 , 4))
  month <- as.numeric(substr(max_date , 6 , 7))
  year_g <- rep(year , 12)
  month_g <- seq(month + 1 , month + 12)
  month_g[month_g > 12] <- month_g[month_g > 12] - 12
  year_g[month_g > month] <- year - 1
  year_g[month_g <= month] <- year
  month_g[month_g < 10] <- paste(0 , month_g[month_g < 10] , sep = '')
  out <- paste(year_g , month_g , '01' , sep = '-')
  out
}

to_period <- make_period(max(malaria_data$period))

## Keep only the data in this period
imputed_data$period <- as.character(imputed_data$period )
malaria_data_input <- subset(imputed_data , period %in% to_period )

malaria_data_input$indicator_name[malaria_data_input$dataElement == 'HdtaLx63988'] <-
  'Confirmed uncomplicated malaria'
malaria_data_input$indicator_name[malaria_data_input$dataElement == 'ouzURM9c1FI'] <-
  'Confirmed uncomplicated malaria given ACT'

## collapse data by lga for each month
system.time(
  lga_collapse <- ddply(malaria_data_input ,  
                           .(Level2 , Level2ID , Level3 , Level3ID , period ,
                             indicator_name , dataElement) ,
                           collapse_sum ,
                           .progress = 'text')
)

## To assess completeness, look at how many reports should be sent each month

# Keep facilities who should report on malaria indicators
malaria_facilities <- subset(data_elements_x_orgunit , 
                             data_element %in% lga_collapse$indicator_name)

# collapse by LGA
lga_should_report <- ddply(malaria_facilities , .(Level3ID) , 
                           function(data){length(unique(data$org_unit_ID)) } ,
                           .progress = 'text')

colnames(lga_should_report) <- c('Level3ID' , 'should_report')



## add reporting requirements to lga collapsed data
lga_collapse_full <- merge(lga_collapse , lga_should_report)

lga_collapse_full$data_coverage <- lga_collapse_full$n_fac / 
  lga_collapse_full$should_report

#### Imputing complete data

lga_collapse_full$final_value <- 
  lga_collapse_full$value / lga_collapse_full$data_coverage

### Take average by LGA
collapse_mean <- function(data){
  data$value <- as.numeric(as.character(data$final_value))
  value <- mean(data$final_value , na.rm = TRUE)
  data.frame(value = value)
}

system.time(
lga_collapse <- ddply(lga_collapse_full , 
                      .(Level2 , Level2ID , Level3 , Level3ID , 
                        indicator_name , dataElement) ,
                      collapse_mean ,
                      .progress = 'text')
)

lga_collapse <- subset(lga_collapse , value < 150000)

library("reshape2")
lga_reshaped <- dcast(lga_collapse , 
                      Level2 + Level2ID + Level3ID  + Level3 ~ indicator_name , 
                      value.var = 'value')

plot(lga_reshaped$`Confirmed uncomplicated malaria` , 
     lga_reshaped$`Confirmed uncomplicated malaria given ACT` )

colnames(lga_reshaped) <- c("Level2" , "Level2ID" , "Level3ID" , "Level3" ,
                            "Confirmed_uncomplicated_malaria" ,
                           "Confirmed_uncomplicated_malaria_given_ACT")


#######
## Match to Grid
#######

### Load Alan's file

full_grid <- read.csv(
  'J://Project/dot_map/data_ex_new/p_14_ALL_B.csv'
  )

full_grid$index <- seq(1 , nrow(full_grid))

### Matching Names in data to names in grid

######################################
##### Standardizing names  ###########
######################################

##Standardize State names in DHIS data
lga_reshaped$Level2 <- as.character(lga_reshaped$Level2)
lga_reshaped$State <- substr(lga_reshaped$Level2 , 
                           4 , nchar(lga_reshaped$Level2))
lga_reshaped$State <- tolower(gsub(' State' , '' , lga_reshaped$State))

lga_reshaped$State <- gsub('-' , ' ' , lga_reshaped$State)

##Standardize States names in grid
full_grid$state_name <- tolower(full_grid$state_name)

##Standardize LGA names in DHIS data
lga_reshaped$Level3 <- as.character(lga_reshaped$Level3)
lga_reshaped$lga <- substr(lga_reshaped$Level3 , 
                           4 , nchar(lga_reshaped$Level3))
lga_reshaped$lga <- tolower(gsub(' Local Government Area' , '' , lga_reshaped$lga))

lga_reshaped$lga_simp <- gsub(' |-' , '' , lga_reshaped$lga)

##Standardize LGA names in grid
full_grid$lga_name <- tolower(full_grid$lga_name)
full_grid$lga_simp <- gsub(' |-' , '' , full_grid$lga_name)

#############################################
#### Add manual matches in the matched facilities
#############################################
manual_matches <- read.csv('manual_matches.csv')

lga_matching <- merge(lga_reshaped  , manual_matches , by.x = 'lga_simp' ,
                      by.y = "dhis_data" , all.x = TRUE)

lga_matching$shapefile <- as.character(lga_matching$shapefile)
lga_matching$lga_simp <- as.character(lga_matching$lga_simp)

lga_matching$shapefile[is.na(lga_matching$shapefile)] <- 
  lga_matching$lga_simp[is.na(lga_matching$shapefile)]

lga_matching <- subset(lga_matching , select = -c(lga , lga_simp))


## Complete Specific matches

lga_matching$State[lga_matching$State == 'nasarawa'] <- 'nasarawa'
full_grid$lga_simp[full_grid$lga_simp %in% c('katsina(benue)',
                                               'katsina(k)')] <- 'katsina'
lga_matching$shapefile[lga_matching$shapefile == 'onuimo'] <- 'unuimo'
lga_matching$shapefile[lga_matching$shapefile == 'aiyekire(gbonyin)'] <- 'gboyin'
lga_matching$shapefile[lga_matching$shapefile == 'obinwga'] <- 'obomangwa'
lga_matching$shapefile[lga_matching$shapefile %in% c('katsina(benue)',
                                                   'katsina(k)')] <- 'katsina'
lga_matching$shapefile[lga_matching$shapefile == 'kogi'] <- 'kotonkar'
lga_matching$shapefile[lga_matching$shapefile == 'yewanorth'] <- 'egbadonorth'
lga_matching$shapefile[lga_matching$shapefile == 'yewasouth'] <- 'egbadosouth'

##Match LGAs to check 
lga_matching$state_lga <- paste(lga_matching$State , 
                                lga_matching$shapefile , sep = '_')
full_grid$state_lga <- paste(full_grid$state_name , 
                             full_grid$lga_simp , sep = '_')


lga_matching$state_lga[!(lga_matching$state_lga %in% full_grid$state_lga)]
unique(full_grid$state_lga[!(full_grid$state_lga %in% lga_matching$state_lga)])



######################################################

## Export non matched names to 
comp1 <- sort(lga_matching$state_lga[!(lga_matching$state_lga %in% full_grid$state_lga)])
comp2 <- sort(unique(full_grid$state_lga[!(full_grid$state_lga %in% 
                                             lga_matching$state_lga)]))

comp1 <- c(comp1 , rep('' , length(comp2) - length(comp1)))
write.csv(data.frame(comp1 , comp2) , 'tocheck.csv')

#### Taking out lgas with duplicate names in dhis until we can stratify in grid
duplga <- ddply(lga_matching , .(state_lga) , nrow)
duplga <- subset(duplga , V1 > 1)

lga_matching <- subset(lga_matching , !(state_lga %in% duplga$state_lga))

##

export_grid <- function(grid , lga_data){
  total <- sum(grid$pfpr_cnt)
  lga <- unique(grid$state_lga)
  print(lga)
  grid$pop_weight <- grid$pfpr_cnt / total
  lga_to_merge <- subset(lga_data , state_lga == lga)
  if(nrow(lga_to_merge) > 0){
    grid$Confirmed_uncomplicated_malaria <- 
      ceiling(lga_to_merge$Confirmed_uncomplicated_malaria * grid$pop_weight)
    grid$Confirmed_uncomplicated_malaria_given_ACT <- 
      ceiling(lga_to_merge$Confirmed_uncomplicated_malaria_given_ACT * grid$pop_weight)
    grid <- subset(grid, select = -c(pop_weight))
  }
  if(nrow(lga_to_merge) == 0){
    grid$Confirmed_uncomplicated_malaria <- 
      grid$Confirmed_uncomplicated_malaria_given_ACT <- NA
    grid <- subset(grid, select = -c(pop_weight))
  }
  grid
}

out <-ddply(full_grid , .(state_lga) , function(x) export_grid(x , lga_matching))
out <- out[order(out$index),]
#out[is.na(Confirmed_uncomplicated_malaria)]

variables <- c("Confirmed_uncomplicated_malaria" , 
               "Confirmed_uncomplicated_malaria_given_ACT")

setwd('J://Project/dot_map/data_ex_map/')
diagnostic <- out$Confirmed_uncomplicated_malaria
diagnostic[is.na(diagnostic)] <- -1
write.csv(diagnostic , 'i/i_4_14_ALL_B.csv')

act_treatment <- out$Confirmed_uncomplicated_malaria_given_ACT
act_treatment[is.na(act_treatment)] <- -1
write.csv(act_treatment , 'i/i_5_14_ALL_B.csv')

####################################################
####### Age Standardization ########################
####################################################
age_groups <- c('0005' , '0510' , '1015' , '1520' , '2025' , '2530' , '3035' , '3540' ,
'4045' , '4550' , '5055' , '5560' , '6065' , '65PL')
total_malaria <- rep(0 , times = nrow(out))
age_dist <- data.frame(age_group = character() , rate = numeric() , pop = numeric())
for(age_group in age_groups){
  print(age_group)
  rate <- read.csv(paste('i/i_2_14_' , age_group , '_B.csv' , sep = '') ,
                   header = FALSE)[,1]
  pop <- read.csv(paste('p/p_14_' , age_group , '_B.csv' , sep = '') ,
                  header = FALSE)[,1]
  num_malaria <- rate * pop
  outs <- data.frame(age_group , rate , pop , num_malaria)
  total_malaria <- total_malaria + num_malaria
  age_dist <- rbind(age_dist , outs)
}

age_dist$prop_malaria <- age_dist$num_malaria / total_malaria

out <- out[order(out$index),]
age_dist$age_group <- as.character(age_dist$age_group)
for(i in 1:2){
  var <- variables[i]
  print(var)
  max_all_r <- c()
  for(age_group in age_groups){
    print(age_group)
    var_age <- paste(var , age_group , sep = '_')
    rate <- out[,var] * age_dist$prop_malaria[age_dist$age_group == age_group] / 
      age_dist$num_malaria[age_dist$age_group == age_group]
    rate[is.na(rate)] <- 0
    rate[rate > 1] <- 1
    max_r <- quantile(rate , probs =0.995)
    rate[rate > max_r] <- max_r
    rate <- round(rate , 4)
    max_all_r <- c(max_all_r , max_r)
    var_num <- i + 3
    print('writing')
    write.csv(rate , 
              paste('i/i_' , var_num , '_14_' , age_group , '.csv' , sep = '') , 
              row.names = FALSE)
  }
  print(max_all_r)
  print(max(max_all_r))
}






############################################################################################


library(rgdal)
library(ggplot2)

ggplot() +  
  geom_point(data=out[out$Confirmed_uncomplicated_malaria_given_ACT < 100 ,], 
             aes(x=longitude, y=latitude, group=id , 
                 col = Confirmed_uncomplicated_malaria_given_ACT )
                       ) + 
  scale_colour_gradient(high="red" , low = 'light blue') + coord_map("mercator")
