setwd('J://Project/dot_map/data_ex_new/p/')


pop06 <- read.csv('p_06_ALL_B.csv')
pop15 <- read.csv('p_15_ALL_B.csv')
latlong <- read.csv('J://Project/dot_map/data_ex_new/p_14_ALL_B.csv')
pop06$pop[pop06$pop == 0]<- pop15$pop[pop15$pop == 0] <- 1
diff06to15 <- (pop15$pop - pop06$pop)/pop06$pop

latlong$test <-  diff06to15

library(rgdal)
library(ggplot2)


latlong$testCens <- latlong$test
latlong$testCens[latlong$test > 5] <- 5

ggplot() +  
  geom_point(data=latlong , 
             aes(x=longitude, y=latitude, group=id , 
                 col = testCens ) ) + 
  scale_colour_gradient2(high="blue" , low = 'red' , midpoint = 0) +
  ggtitle('Population Growth Rate') + coord_map("mercator")


##################################

diff06to15 <- pop15$pop - pop06$pop

latlong$test <-  diff06to15

latlong$testCens <- latlong$test
latlong$testCens[latlong$test > 1000] <- 1000
latlong$testCens[latlong$test < -1000] <- -1000



ggplot() +  
  geom_point(data=latlong , 
             aes(x=longitude, y=latitude, group=id , 
                 col = testCens ) ) + 
  scale_colour_gradient2(high="blue" , low = 'red' , midpoint = 0) +
  ggtitle('Population Growth') + coord_map("mercator")


