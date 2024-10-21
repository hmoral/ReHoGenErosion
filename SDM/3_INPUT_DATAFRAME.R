
###3_INPUT_DATAFRAME

#Description:
#Preparation of model input (Presence/PseudoAbsences dataframe with environmental values over time, covering 1901-2015)

#Steps:
##1: CREATION OF HISTORICAL DATAFRAMES WITH ENVIRONMENTAL INFORMATION OVER TIME
##2: CREATION OF P/PA DATAFRAME (1/0) 
##3: SUBSET OF MAIN DATAFRAME in 10 SUBDATAFRAME


#Author:
#Ester Milesi (University of Copenhagen, Denmark) - Contact: estermilesi96@gmail.com

#R version: 
#R-4.2.0

#Run date: 
print(Sys.Date())

#Directories:
data_dir <- "..." #ADD YOUR PROJECT DIRECTORY 
species_dir <- paste0(data_dir,"species_data/")
env_dir <- paste0(data_dir,"env_data/")
output_dir<-paste0(env_dir,"output_data/")
dataframe_dir<-paste0(output_dir,"dataframe/")
dir.create(dataframe_dir)

#Define needed packages:
packages <- c('sp','sf', 'raster', 'rmapshaper') #list of needed packages (use search() to check which packages are loaded)

#Load or install&load packages  (to unload: unloadNamespace("packagename"))
package.check <- lapply(
  packages,
  FUN = function(x) {
    if (!require(x, character.only = TRUE)) {
      install.packages(x, dependencies = TRUE)
      library(x, character.only = TRUE) 
    }
  }
)


##1: CREATION OF HISTORICAL DATAFRAMES WITH ENVIRONMENTAL INFORMATION OVER TIME

#Define species name:
species<- "anthochaera_phrygia" 

#Upload Area Of Interest 

#Read kernel:

aoi_species_geo <- sf::st_read(paste0(species_dir,"AOI_kernel99.9.geojson"))
## convert the geometry of the `sf` object to SpatialPolygons
aoi_species <- sf::as_Spatial(st_geometry(aoi_species_geo), IDs = as.character(1:nrow(aoi_species_geo)))


##S3.1: CREATION OF HISTORICAL DATAFRAMES WITH ENVIRONMENTAL INFORMATION OVER TIME

#Upload env data for Australia

hist_env_scale <- list.files(path=paste0(output_dir,"hist_env_au_resc/"), pattern=c("\\.tif$"), full.names = TRUE)
hist_env_scale <- grep(paste0(1901:2015,collapse="|"),hist_env_scale,value = T)
print(paste("will read",length(hist_env_scale),"env layers")) # sanity check that grep selected the correct number of layers
hist_env_scale <- lapply(hist_env_scale, raster)


#Mask environmental layers using AOI (calculated using Kernel density method in 2_INPUT_SPECIES_DATA)

#Note: This step is done ONLY FOR HISTORICAL LAYERS (because the model is built only on historical data, and project to both historical and future data)

hist_env_scale_stack<-stack(hist_env_scale)
hist_env_mask<-mask(hist_env_scale_stack,mask=aoi_species)
hist_env_mask_stack<-stack(hist_env_mask)
hist_env_mask_stack


#From raster layers to table and saving of table:

hist_env<-rasterToPoints(hist_env_mask_stack)

#keep NAs
hist_env_df<-data.frame(hist_env)
sum(is.na(hist_env_df))
sum(is.na(hist_env_df$X1955_au_bio1_au))
nrow(hist_env_df)

write.csv(hist_env_df, file = paste0(dataframe_dir,"1901_2015_env_dataframe_",species,"_2024.csv") , row.names = F, col.names = T, sep=",") 

hist_env_df[1:5,1:5]


##2: CREATION OF P/PA DATAFRAME (1/0) 

#Upload saved dataframe
env <- list.files(path=dataframe_dir, pattern=c(".csv"), full.names = TRUE) 
env <- grep("1901_2015_env_dataframe",env,value = T)
env <- read.csv(env, header=TRUE, sep = ",") 

#Subset occurrences table

occ<-read.csv(file= paste0(species_dir,"filtered_and_cleaned_occ_",species,"_2024.csv") , header= T, sep=",") 
occ<-as.data.frame(cbind(occ$decimalLongitude,occ$decimalLatitude,occ$year)) #extracting only lat and long data and year
names(occ) <- c("longitude","latitude","year") #rename columns
print(head(occ))
nrow(occ)

#CREATE A TABLE WITH BOTH PRECENCES AND ABSENCES (to then be able to selec PA from non-occurences points)

#loop P_PA creation for each env variable for selected year 
P_PA_env<-data.frame()
data_year<-c()


for (YEAR in c(1901:2015)) {
  
  #extract data for only one year for AOI
  env_xy_year<- env[, c(grep(YEAR, names(env), value=T))] 
  env_xy_year<-cbind.data.frame(env[,c(1,2)],env_xy_year)
  env_xy_year<-env_xy_year[!is.na(env_xy_year[,3]),] #remove NA from first env variable (most NAs are shared accross variables. We want to take care of them otherwise the loop fails)

  #extract variables columns
  env_year<-env_xy_year[,-c(1,2)]
  names(env_year)<-gsub("X[0-9][0-9][0-9][0-9]_au","",names(env_year),perl = F)
  names(env_year)<-gsub("_","",names(env_year),perl = F)
  names(env_year)<-gsub("au","",names(env_year),perl = F)
  
  #extract coordinates 
  env_xy <- env_xy_year[,c(1,2)]  
  nrow(env_xy)
  nrow(env_year)
  #build an empty raster of the same extent of AOI 
  r <- hist_env_mask_stack[[1]]
  plot(r)
  values(r)[!is.na(values(r))] <- 1000 #assign 1000 to all grids inside AOI
 
  #select occurences points (rows) of selected year
  xy <- occ[occ$year == YEAR ,]  
  xy<-xy[,c(1,2)] #select long and lat
  
  print(paste("NUMBER OF OCCURENCES FOR YEAR", YEAR))
  print(nrow(xy))
  
  if(nrow(xy)== 0) next
  
  
  #count occurences in each grid of empty raster and assign value to grids (give 0 when no occurences) 
  r_P_PA <- raster::rasterize(x=xy, y=r, fun = "count", background = 0, na.rm=TRUE) 
  values(r_P_PA)[is.na(values(r))]<-NA
  values(r_P_PA)[(values(r_P_PA)>0)]<-1  #assign 1 if a grid has one or more occurences inside 
  plot(r_P_PA)
  
  #fill an empty dataframe, one row for each grid  
  P_PA <- values(r_P_PA)
  print(length(P_PA))
  
  P_PA <-P_PA[!is.na(P_PA)] #remove outside AU
  print(length(P_PA))
  print(nrow(env_xy))
  print(nrow(env_year))
  data_year<-rep(YEAR, nrow(env_year)) 
  
  X<-cbind.data.frame(P_PA, env_xy, env_year, data_year )
  P_PA_env<-rbind(P_PA_env,X)
  head(env_year)
  print(paste("end of loop for  year",YEAR))
}


#P_PA_env: ouput table with 0 as absences and 1 as presences 
print("Dataframe of Presences and Absences 1;0")
print(head(P_PA_env[,1:10]))


write.csv(P_PA_env, file= paste0(dataframe_dir,"1901_2015_P_PA_env_dataframe_" ,species, "_2024.csv"), row.names = FALSE ) #***TO EDIT***



##3: SUBSET OF MAIN DATAFRAME IN 10 SUBDATAFRAME

#Upload saved P/PA dataframe

P_PA_env <- list.files(path=dataframe_dir, pattern=c("\\.csv$"),full.names = TRUE)
P_PA_env <- grep(species,P_PA_env,value = T)
P_PA_env <- grep("subset", P_PA_env, value = T, invert = TRUE)
P_PA_env <- grep("P_PA", P_PA_env, value = T)
P_PA_env <- read.csv(P_PA_env, header=TRUE, sep = ",") 

#Check number of row of presences and pseudo-absences 

nrow(P_PA_env) # 157410 (in 2024) // 156969 (in 2023)
P_env<-P_PA_env[P_PA_env$P_PA==1,] #extract presences
PA_env<-P_PA_env[P_PA_env$P_PA==0,] #extract pseudo-absences
nrow(P_env) #1397 (in 2024) // 1435 (in 2023)
nrow(PA_env) #156013 (in 2024) // 155534 (in 2023)

#Calculate the number of occurrences available for all 10-years periods, and select the lowest number

seq<- seq(1901, 2015, by =10)
table_occ<-data.frame()
for (FIRST_YEAR in seq){
  occ_selection <- P_env[P_env$data_year >= FIRST_YEAR & P_env$data_year <= FIRST_YEAR+9 ,]
  occ_number <- nrow(occ_selection)
  occ_first_year<-FIRST_YEAR
  X<-cbind.data.frame(occ_first_year,occ_number)
  names(X)<-c("Period","Occ")
  
  print(paste0("Number of occurrences in period ", FIRST_YEAR, "-",FIRST_YEAR+9,":"))
  print(occ_number)
  
  table_occ<-rbind.data.frame(table_occ,X)
  
}
plot(table_occ, type="h")
table_occ

#Create 10 subset dataframes in which each one has #min_occ P and #min_occ*2 PAs

min_occ<-min(table_occ[table_occ$Occ>0,]$Occ) #which is the period with lowest num of occ (but > 0)?

seq<-seq(from=1901,to=2011,by=10)
seeds<-c(44072,7001,46865,61430,67661,37546,52621,41494,7800,12767)


for (SUBSET in 1:10){
  
  subset_n<-as.character(SUBSET)
  set.seed(seeds[SUBSET])
  print(paste0("Set seed: ",seeds[SUBSET]," for subset #",SUBSET ))
  P_PA_env_subset<-c()
  
  for (FIRST_YEAR in seq) {
    
    #Now, we can draw a random subsample of (#min_occ) presences and (#2*min_occ) pseudoabsences -> the same quantity for each 10-years quantity 
    
    P_env_year <- P_env[P_env$data_year >= FIRST_YEAR & P_env$data_year <= FIRST_YEAR+9 ,]
    PA_env_year<- PA_env[PA_env$data_year >= FIRST_YEAR & PA_env$data_year <= FIRST_YEAR+9 ,]
    
    if(nrow(P_env_year)==0) next
    
    p_subset_year <- P_env_year[sample(1:nrow(P_env_year), min_occ), ] #presences: min_occ
    pa_subset_year <- PA_env_year[sample(1:nrow(PA_env_year), min_occ*2), ] #psuedo-absences: 2 times min_occ
    X<-rbind.data.frame(p_subset_year,pa_subset_year)
    P_PA_env_subset<-rbind(P_PA_env_subset,X)
    print(paste0("nrow P_PA_env_subset for period ",min(P_env_year$data_year),"-",max(P_env_year$data_year)))
    print(nrow(P_PA_env_subset))
    
  }
  
  #save subset
  write.csv(P_PA_env_subset, file= paste0(dataframe_dir,"/","1901_2015_P_PA_env_dataframe_" ,species, "_2024_subset_",subset_n,"_seed_",as.character(seeds[SUBSET]),".csv"), row.names = FALSE )
  print(paste0("save subset # ", SUBSET))
}

###END__________________________________________________________________________