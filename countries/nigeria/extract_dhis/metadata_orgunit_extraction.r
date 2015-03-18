library(RCurl)
library(XML)


setwd('J://Project/phc/nga/dhis')

Nigeria <-'https://dhis2nigeria.org.ng/api/organisationUnits/s5DPBsdoE8b.xml'

get_facilities_list <- function





##Function to extract children from a given page + adress of children
getChildren <- function(url){
  ParentName <- xmlGetAttr(root , "name")
  ParentId <- xmlGetAttr(root , "id")
  if(length(root[['children']]) > 0){
    UnitName <- xmlSApply(root[['children']] , xmlGetAttr , "name")
    UnitId <- xmlSApply(root[['children']] , xmlGetAttr , "id")
    UnitAdress <- xmlSApply(root[['children']] , xmlGetAttr , "href")
  }
  else{
    UnitAdress <- UnitName <- UnitAdress <- UnitId<- NA
  }
  out <- data.frame(UnitName , UnitId ,  UnitAdress , ParentName , ParentId)
  out
}

getMetadata<- function(root){
  UnitLevel <- xmlGetAttr(root , "level")
  UnitName <- xmlGetAttr(root , "name")
  UnitId <- xmlGetAttr(root , "id")
  if(length(root[['organisationUnitGroups']]) > 0){
    GroupName <- xmlSApply(root[['organisationUnitGroups']] , xmlGetAttr , "name")
  }
  else{
    GroupName <- NA
  }
  out <- data.frame(UnitName , UnitLevel , UnitId , GroupName)
  out
}

##Run Function

#Initiate parameters

pagesToRead <- c(Nigeria)
pagesRead <- c()
orgUnits <- data.frame(unitName =  character() , UnitId =  character() ,
                       UnitAdress = character() , ParentName = character() , ParentId = character())
MetaData <- data.frame(UnitName = character() , UnitLevel = character() ,
                      UnitId = character() , GroupName = character())
countp <- 0
total <- 0

StartTime <- Sys.time()
while (length(pagesToRead) > 0){
  extractOrg <- data.frame(unitName =  character() , UnitId =  character() ,
                           UnitAdress = character() , ParentName = character() , ParentLevel = character() ,
                           ParentId = character())
  extractMeta <- data.frame(UnitName = character() , GroupName = character())
  pagesJustRead <- c()
  for(url in pagesToRead){
    print(url)
    Page<-getURL(url,userpwd="grlurton:Glurton29",
                 ssl.verifypeer = FALSE , httpauth = 1L)
    if(substr(Page , 1 , 5) == "<?xml"){
      ParsedPage <- xmlParse(Page)
      root <- xmlRoot(ParsedPage)
      extractOrg <- rbind(extractOrg , getChildren(root))
      extractMeta <- rbind(extractMeta , getMetadata(root))
    }
    pagesJustRead <- c(pagesJustRead , url)
    countp <- countp + 1
    print(paste(countp , 'Units done' , ',' , length(pagesToRead) - (countp - total) ,
                'remaining this round',sep = ' '))
  }
  print('Merging to general output')
  orgUnits <- rbind(orgUnits , extractOrg)
  MetaData <- rbind(MetaData , extractMeta)

  child_adress <- paste(as.character(extractOrg$UnitAdress[!is.na(extractOrg$UnitAdress)]) ,
                        "xml" , sep = '.')

  pagesRead <- c(pagesRead , pagesJustRead)
  total <- length(pagesRead)

  pagesToRead <- c(pagesToRead , child_adress)
  pagesToRead <- pagesToRead[!(pagesToRead %in% pagesRead )]

  print(paste("Pages read =" , total , sep = " " ))
  print(paste("Pages to Read" , length(pagesToRead) , sep = " "))
}
StopTime <- Sys.time()

write.csv(MetaData , 'MetadataUnitsRaw.csv' , row.names = FALSE)
write.csv(orgUnits , 'ExtractOrgUnitsRaw.csv', row.names = FALSE)



extract_org_unit <- function(org_unit_page_url, userID, password){
  root <- parse_page(org_unit_page_url , userID , password)
  ##Extraction of org units metadata
  id <- xmlAttrs(root)[['id']]
  coordinates <- xmlValue(root[['coordinates']])
  opening_date <- xmlValue(root[['openingDate']])
  name <- xmlValue(root[['displayName']])
  active <- xmlValue(root[['active']])
  parent_id <- xmlAttrs(root[['parent']])[['id']]
  parent_name <- xmlAttrs(root[['parent']])[['name']]
  parent_url <- xmlAttrs(root[['parent']])[['href']]
  org_unit_metadata <- data.frame(id , coordinates , opening_date , name ,
                                  active , parent_id , parent_name , parent_url)

  ##Extraction of org units groups
  org_unit_group <- data.frame(group_ID = character() , group_name = character() ,
                               group_url = character())
  if (!is.null(root[['organisationUnitGroups']])){
    Groups <- root[['organisationUnitGroups']]
    group_ID <- xmlSApply(Groups , xmlGetAttr , 'id')
    group_name <- xmlSApply(Groups , xmlGetAttr , 'name')
    group_url <- xmlSApply(Groups , xmlGetAttr , 'href')
    org_unit_group <- data.frame(group_ID , group_name , group_url)
  }

  ##Extraction of org units datasets
  org_unit_dataset <- data.frame(dataset_ID = character() ,
                                 dataset_name = character() ,
                                 dataset_url = character())
  if (!is.null(root[['dataSets']])){
    Datasets <- root[['dataSets']]
    dataset_ID <- xmlSApply(Datasets , xmlGetAttr , 'id')
    dataset_name <- xmlSApply(Datasets , xmlGetAttr , 'name')
    dataset_url <- xmlSApply(Datasets , xmlGetAttr , 'href')
    org_unit_dataset <- data.frame(dataset_ID , dataset_name , dataset_url)
  }

  out <- list(org_unit_metadata , org_unit_group , org_unit_dataset)
  out
}



ss <- extract_org_unit('https://hiskenya.org/api/organisationUnits/HAXZM3YNUmN.xml',
                       'grlurton' , 'Glurton29')




