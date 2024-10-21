
###1_INPUT_ENV_DATA

#Description:
#Processing of environmental data (climatic and land use data)

##1: LAND-USE DATA 
#1.1: Historical land-use data: combination of variables and cropping to Australia area
#1.2: Future land-use data: combination of variables and cropping to Australia area

##2: CLIMATIC DATA
#2.1 Historical climatic data: cropping to Australia area, calculation of bioclim variables, decrease of resolution
#2.2 Future climatic data: cropping to Australia area, decrease of resolution (already in the form of bioclim vars)

##3: RESCALE ALL LAYERS' VALUES FROM 0 to 1

#Author:
#Ester Milesi (University of Copenhagen, Denmark) - Contact: estermilesi96@gmail.com

#R version: 
#R-4.2.0

#Run date: 
print(Sys.Date())

#Directories:
data_dir <- "..." #ADD YOUR PROJECT DIRECTORY 
env_dir <- paste0(data_dir,"env_data/")
dir.create(env_dir) #environmental data directory

#raw data directory
raw_dir<-paste0(env_dir,"raw_data/")
dir.create(raw_dir) #raw environmental data directory

#(Climate) Raw data source: https://envicloud.wsl.ch/#/?prefix=chelsa%2Fchelsa_V1%2Fchelsa_cruts
dir.create(paste0(raw_dir,"hist_tmax")) #it has to contain: CHELSAscruts tmax 1901-2016 
dir.create(paste0(raw_dir,"hist_tmin")) #it has to contain: CHELSAscruts tmin 1901-2016 
dir.create(paste0(raw_dir,"hist_prec")) #it has to contain: CHELSAscruts prec 1901-2016 
dir.create(paste0(raw_dir,"fut_bio"))   #it has to contain: CHELSA Future (CMIP6) - scenarios SSP1, SSP3, SSP5 - circulation model: GFDL-ESM4 (editable) 

#(Land use) Raw data source: https://luh.umd.edu/data.shtml
dir.create(paste0(raw_dir,"hist_land")) #it has to contain: LUH2 850-2015 - file name: states.nc
dir.create(paste0(raw_dir,"fut_land"))  #it has to contain: LUH2 2015-2100 - scenarios SSP1, SSP3, SSP5 

#output data directory
output_dir<-paste0(env_dir,"output_data/")
dir.create(output_dir)

dir.create(paste0(output_dir,"hist_bio_au_highres"))
dir.create(paste0(output_dir,"hist_bio_au"))
dir.create(paste0(output_dir,"hist_land_au"))     
dir.create(paste0(output_dir,"hist_land_global"))
dir.create(paste0(output_dir,"fut_bio_au_highres"))
dir.create(paste0(output_dir,"fut_bio_au"))
dir.create(paste0(output_dir,"fut_land_au"))      
dir.create(paste0(output_dir,"fut_land_global"))
dir.create(paste0(output_dir,"hist_env_resc"))    #final format bio+land (input of model)
dir.create(paste0(output_dir,"fut_env_resc"))     #final format bio+land (input of model)


#Define needed packages:
packages <- c('raster', 'rmapshaper') #list of needed packages (use search() to check which packages are loaded)

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


#Define study periods, scenarios and general circulation model (GCM)
hist_first_year<-1901
hist_last_year<-2015

fut_first_year<-2015
fut_last_year<-2040
scenario_list<-c("ssp126","ssp370","ssp585") #order is important
gcl_list<-c("gfdl","ipsl","mpi","mri","ukesm")

#Define Australia area
max.lat <- -9
min.lat <- -45 
max.lon <- 155
min.lon <- 112
geographic.extent <- extent(x = c(min.lon, max.lon, min.lat, max.lat)) 


##1: LAND-USE DATA

#Define land-use vars and crops layers to combine in a singular variable: 'crop'
vars_raw <-c("primf", "primn", "secdf", "secdn", "urban", "c3ann", "c4ann", "c3per", "c4per", "c3nfx", "pastr", "range","secmb", "secma") #last two are not fractions of grid 
crop_list<-c("c3ann", "c4ann", "c3per", "c4per", "c3nfx")
vars_list <- c("primf", "primn", "secdf", "secdn", "urban", "crop", "pastr", "range","secmb", "secma") #after combination of all crop types

#1.1: Historical land-use data: combination of variables and cropping to Australia area

#Uploading land-use data into R (.nc data) - guide at https://pjbartlein.github.io/REarthSysSci/raster_intro.html

hist_land_use<-paste0(raw_dir, "hist_land/states.nc") #file path 			****TO EDIT IF NAME OF FILE IS DIFFERENT****

#Write .tif (HISTORICAL) for each variable and for each year of selected period (1901-2015)
setwd(paste0(output_dir, "hist_land_global"))
print("Creation of .tif historical land use (global) - IN PROGRESS... destination: hist_land_global ")

for (VAR in vars_raw){
  #upload the data as raster brick. one brick is relative to one variable, and it has multiple layers, one for each year, from 850 to 2015
  var_brick<-brick(hist_land_use, varname= VAR) #select variable
  names(var_brick)<-as.character(850:2015) #rename temporal layers of the brick (from year 850 to 2015)
  
  #select only years of interest
  list_brick_year_subset <- raster::subset(var_brick, grep(paste(1901:2015, collapse="|"), names(var_brick) , value=T)) 
  X<-brick(list_brick_year_subset)
  writeRaster(X, filename=paste0(VAR,".tif"), format="GTiff", bylayer=TRUE, suffix="names",overwrite=TRUE ) #layers for each year, global data
  print (paste("Variable",VAR,"written as raster"))
}

print("Exporting of .tif historical land use (global) - complete ")
remove(X,list_brick_year_subset, var_brick )

#Combine all crop-related layers in only one variable: 'crop'

#upload exported global land-use layers
setwd(paste0(output_dir, "hist_land_global"))
hist_lu<-c() # store rasterstack of each variable in a vector
for (VAR in vars_raw){
  var_n<-list.files(path=getwd(), pattern =c(VAR, ".tif")) 
  var_n<-lapply(var_n,raster)
  Y<-stack(var_n) # use stack, otherwise it will save as element in the vector each year' layer
  hist_lu<-c(hist_lu, Y)
}

hist_lu_stack<-stack(hist_lu)

#combine crop layers and export them
setwd(paste0(output_dir, "hist_land_global"))
crop_type_list<-c()

for (CROP in crop_list){
  
  #create list of all crops variables
  crop_type <- raster::subset(hist_lu_stack, grep(CROP, names(hist_lu_stack) , value=T)) 
  X<-crop_type
  crop_type_list<-c(crop_type_list, X)
}

crop_type_list_stack<-stack(crop_type_list)


for (YEAR in c(hist_first_year:hist_last_year)){
  
  crop_year <- raster::subset(crop_type_list_stack, grep(YEAR, names(crop_type_list_stack) , value=T)) 
  
  #combine (SUM) of different crop variables into one:'crop'
  crop_year_sum<-sum(crop_year)
  names(crop_year_sum)<-paste0("crop_X",YEAR)
  
  writeRaster(crop_year_sum, filename=paste0(names(crop_year_sum),".tif"), format="GTiff", overwrite=TRUE, bylayer=TRUE)
  
}

#Cropping and exporting land-use data

#upload exported global land-use layers (with also the new variable 'crop')
setwd(paste0(output_dir, "hist_land_global"))
hist_lu<-c() # store rasterstack of each variable in a vector
for (VAR in vars_list){
  var_n<-list.files(path=getwd(), pattern =c(VAR, ".tif")) 
  var_n<-lapply(var_n,raster)
  Y<-stack(var_n) # use stack, otherwise it will save as element in the vector each year' layer
  hist_lu<-c(hist_lu, Y)
}

hist_lu_stack<-stack(hist_lu)

#cropping and exporting layers
setwd(paste0(output,"hist_land_au"))
print("Exporting cropped historical land use - IN PROGRESS... destination: hist_land_au ")

for(VAR in vars_list){
  hist_lu_stack_var<-raster::subset(hist_lu_stack, grep(VAR, names(hist_lu_stack) , value=T))
  crop_var<-crop(hist_lu_stack_var, geographic.extent )
  writeRaster(crop_var, filename = paste(names(hist_lu_stack_var), "au.tif",  sep="_"), format="GTiff", overwrite=TRUE, bylayer=TRUE)
  
}

print("Exporting cropped historical land use - complete ")

#1.2: Future land-use data: combination of variables and cropping to Australia area

#Uploading land-use data into R (.nc data) - guide at https://pjbartlein.github.io/REarthSysSci/raster_intro.html

fut_land_use_ssp_list<-c()

for(SSP in scenario_list){
  
  fut_land_use_ssp<-list.files(path=paste0(raw_dir,"fut_land/"), pattern =c(SSP, ".nc"))   #file path 			****TO EDIT IF NAME OF FILE IS DIFFERENT****
  fut_land_use_ssp<-paste0(raw_dir, "fut_land/",fut_land_use_ssp)
  
  X<-fut_land_use_ssp
  fut_land_use_ssp_list<-c(fut_land_use_ssp_list,X) #list of paths for future data (different scenarios)
}

#Write .tif for each variable & average layers from selected period (2041-2070)

setwd(paste0(output_dir, "fut_land_global"))
print("Creation of .tif future land use (global) - IN PROGRESS... destination: fut_land_global ")


for (VAR in vars_raw){
  
  
  for (NUM in 1:length(fut_land_use_ssp_list)){
    #NUM refers to different scenario
    
    #select correct path for data relative to selected scenario
    fut_land_use_ssp_list_num<-fut_land_use_ssp_list[NUM]
    
    
    
    #upload the data as raster brick. one brick is relative to one variable, and it has multiple layers, one for each year, from 2015 to 2100
    var_brick<-brick(fut_land_use_ssp_list_num, varname= VAR) #select variable
    names(var_brick)<-as.character(2015:2100) #rename temporal layers of the brick (from year 2015 to 2100)
    
    #select only years of interest
    list_brick_year_subset <- raster::subset(var_brick, grep(paste(fut_first_year:fut_last_year, collapse="|"), names(var_brick) , value=T)) 
    X<-brick(list_brick_year_subset)
    
    #average layers from selected years
    X_mean<- mean(X)
    
    writeRaster(X_mean, filename=paste0(VAR,"_",fut_first_year,"_",fut_last_year,"_",scenario_list[NUM],".tif"), format="GTiff", bylayer=TRUE,overwrite=TRUE ) #layers for each year, global data
    print (paste("Variable ",VAR," written as raster, scenario ", scenario_list[NUM]))
  }
}

print("Exporting of .tif future land use (global) - complete ")
remove(X, mean_X, list_brick_year_subset, var_brick )

#Combine all crop-related layers in only one variable: 'crop'

#upload exported global land-use layers
setwd(paste0(output_dir, "fut_land_global"))
fut_lu<-c() # store rasterstack of each variable in a vector
for (VAR in vars_raw){
  var_n<-list.files(path=getwd(), pattern =c(VAR, ".tif")) 
  var_n<-lapply(var_n,raster)
  Y<-stack(var_n) # use stack, otherwise it will save as element in the vector each year' layer
  fut_lu<-c(fut_lu, Y)
}

fut_lu_stack<-stack(fut_lu)

#combine crop layers and export them
setwd(paste0(output_dir, "fut_land_global"))
crop_type_list<-c()

for (CROP in crop_list){
  
  #create list of all crops variables
  crop_type <- raster::subset(fut_lu_stack, grep(CROP, names(fut_lu_stack) , value=T)) 
  X<-crop_type
  crop_type_list<-c(crop_type_list, X)
}

crop_type_list_stack<-stack(crop_type_list)

for (SSP in scenario_list){
  
  crop_ssp <- raster::subset(crop_type_list_stack, grep(SSP, names(crop_type_list_stack) , value=T)) 
  
  #combine (SUM) of different crop variables into one:'crop'
  crop_ssp_sum<-sum(crop_ssp)
  names(crop_ssp_sum)<-paste0("crop_",fut_first_year,"_",fut_last_year,"_",SSP)
  
  writeRaster(crop_ssp_sum, filename=paste0(names(crop_ssp_sum),".tif"), format="GTiff", overwrite=TRUE, bylayer=TRUE)
  
}


#Cropping and exporting land-use data

print("Exporting cropped future land use - IN PROGRESS... destination: fut_land_au ")

#upload exported global land-use layers (with also the new variable 'crop')
setwd(paste0(output_dir, "fut_land_global"))
fut_lu<-c() # store rasterstack of each variable in a vector
for (VAR in vars_list){
  var_n<-list.files(path=getwd(), pattern =c(VAR, ".tif")) 
  var_n<-lapply(var_n,raster)
  Y<-stack(var_n) # use stack, otherwise it will save as element in the vector each year' layer
  fut_lu<-c(fut_lu, Y)
}

fut_lu_stack<-stack(fut_lu)

#cropping and exporting layers 
setwd(paste0(output_dir,"fut_land_au"))
for(VAR in vars_list){
  fut_lu_stack_var<-raster::subset(fut_lu_stack, grep(VAR, names(fut_lu_stack) , value=T))
  crop_var<-crop(fut_lu_stack_var, geographic.extent )
  writeRaster(crop_var, filename = paste(names(fut_lu_stack_var), "au.tif",  sep="_"), format="GTiff", overwrite=TRUE, bylayer=TRUE)
}

print("Exporting cropped future land use - complete ")


##2: CLIMATIC DATA

#2.1 Historical climatic data: cropping to Australia area, calculation of bioclim variables, decrease of resolution

for (YEAR in 1901:2016){ 
  
  #Upload raster layers of HISTORICAL monthly climatic data from year YEAR
  
  #temperature max
  setwd(paste0(raw_dir,"hist_tmax"))
  wd<-getwd() 
  tmax <- list.files(path=wd, pattern = c("tmax","\\.tif$")) #list all .tif files from the selected working directory
  tmax <- grep( YEAR, tmax, value=T)
  print(paste("will read",length(tmax),"tmax layers for year", YEAR)) # sanity check that grep selected the correct number of layers
  tmax<- lapply(tmax,raster)
  
  #temperature min
  setwd(paste0(raw_dir,"hist_tmin"))
  wd<-getwd()
  tmin <- list.files(path=wd, pattern =c("tmin", "\\.tif$"))
  tmin <- grep( YEAR, tmin, value=T)
  print(paste("will read",length(tmin),"tmin layers for year", YEAR)) # sanity check that grep selected the correct number of layers
  tmin <- lapply(tmin,raster)
  
  #precipitation
  setwd(paste0(raw_dir,"hist_prec")) 
  wd<-getwd()
  prec <- list.files(path=wd, pattern = c("prec","\\.tif$"))
  prec <- grep( YEAR, prec, value=T)
  print(paste("will read",length(prec),"prec layers for year", YEAR)) # sanity check that grep selected the correct number of layers
  prec <- lapply(prec,raster)
  
  tmax_stack<-stack(tmax) 
  tmin_stack<-stack(tmin)
  prec_stack<-stack(prec)
  
  #Cropping and masking climatic layers
  
  #cropping to Australia extent
  tmax_au<-crop(tmax_stack, geographic.extent) 
  tmin_au<-crop(tmin_stack, geographic.extent)
  prec_au<-crop(prec_stack, geographic.extent)
  
  #stack rasters after cropping
  tmax_au_stack<-stack(tmax_au) 
  tmin_au_stack<-stack(tmin_au)
  prec_au_stack<-stack(prec_au)
  
  
  #Calculate bioclimatic variables from historical climatic data of tmax, tmin, prec
  
  setwd(paste0(output_dir,"hist_bio_au_highres"))
  print("Creation of historical high res bioclim layers - IN PROGRESS... destination: hist_bio_au_highres ")
  
  tmax_au_stack_year <- raster::subset(tmax_au_stack, grep(YEAR, names(tmax_au_stack), value=T))
  tmin_au_stack_year <- raster::subset(tmin_au_stack, grep(YEAR, names(tmin_au_stack), value=T))
  prec_au_stack_year <- raster::subset(prec_au_stack, grep(YEAR, names(prec_au_stack), value=T))
  bio_year <- biovars(tmax_au_stack_year, tmin_au_stack_year, prec_au_stack_year)
  writeRaster(bio_year, filename=paste(YEAR, "_au.tif" ,sep=""), format="GTiff", bylayer=TRUE, suffix="names")
  
  print("Exporting of historical high res bioclim layers - complete")
  
  
  #Decrease resolution of bioclim variables to the same of land-use data
  
  print("Decrease of resolution of historical bioclim layers - IN PROGRESS... destination: hist_bio_au ")
  
  #upload high res climatic layers
  setwd(paste0(output_dir,"hist_bio_au_highres")) 
  wd<-getwd() 
  past_bioclim_au <- list.files(path=wd, pattern =c("bio", "\\.tif$")) 
  past_bioclim_au <- grep( YEAR, past_bioclim_au , value=T)
  past_bioclim_au<- lapply(past_bioclim_au,raster)
  print("uploading of high resolution bioclim layers - complete")
  
  #stack the rasterlayer
  past_bioclim_au_stack<-stack(past_bioclim_au)
  remove(past_bioclim_au)
  
  #decrease resolution of cropped climatic data to be equal to the land use res. (from 0.0083x0.0083 degree to 0.25x0.25 degree resolution)
  past_bio_coarse<-aggregate(past_bioclim_au_stack, fact=30) # 30= res(landuse)/res(climatic)= 0,25/0,0083
  print("decreasing resolution of bioclim layers - complete")
  remove(past_bioclim_au_stack)
  
  #export cropped & low res. climatic layers 
  setwd(paste0(output_dir,"hist_bio_au"))
  writeRaster(past_bio_coarse, filename = paste(names(past_bio_coarse), ".tif",  sep=""), format="GTiff", overwrite=TRUE, bylayer=TRUE)
  
  
  print("Exporting of low res historical bioclim layers - complete")
  
}


#2.2 Future climatic data: cropping to Australia area, decrease of resolution (already in the form of bioclim vars)



#Uploading  raster layers of FUTURE climatic data (2041-2070)

setwd(paste0(raw_dir,"fut_bio"))
wd<-getwd()
fut_bio <- list.files(path=wd, pattern = c("bio","\\.tif$"))
fut_bio <- grep( paste0(fut_first_year,"-",fut_last_year), fut_bio , value=T)
fut_bio <- grep( "gfdl", fut_bio , value=T) #circulation model
print(paste("will read",length(fut_bio )," layers for period 2041-2070")) # sanity check that grep selected the correct number of layers
fut_bio <- lapply(fut_bio, raster)

fut_stack<-stack(fut_bio)
remove(fut_bio) 

#cropping to Australia extent
fut_au<-crop(fut_stack, geographic.extent)

#stack rasters after cropping
fut_au_stack<-stack(fut_au)

#Export FUTURE climatic data (no need to calculate bioclim variable from them)

setwd(paste0(output_dir,"fut_bio_au_highres"))
print("Exporting of future high res bioclim layers - IN PROGRESS... destination: fut_bio_au_highres ")
writeRaster(fut_au_stack, filename=paste(fut_first_year,"_",fut_last_year, "_au.tif" ,sep=""), format="GTiff", bylayer=TRUE, suffix="names") #check!!! if keeping in the name 2041-2070, or if it is already in the suffix.
print("Exporting of future high res bioclim layers - complete ")


#Decrease resolution of bioclim variables to the same of land-use data

print("Decrease of resolution of future bioclim layers - IN PROGRESS... destination: fut_bio_au ")

#upload
setwd(paste0(output_dir,"fut_bio_au_highres")) 
wd<-getwd() 
fut_bioclim_au <- list.files(path=wd, pattern =c("bio", "\\.tif$")) 
fut_bioclim_au <- grep(paste0(fut_first_year,"_",fut_last_year), fut_bioclim_au , value=T)
fut_bioclim_au<- lapply(fut_bioclim_au,raster)

#stack the rasterlayers
fut_bioclim_au_stack<-stack(fut_bioclim_au) 
remove(fut_bioclim_au)

#decrease resolution
fut_bio_coarse<-aggregate(fut_bioclim_au_stack, fact=30) #from 0.0083x0.0083 degree to 0.25x0.25 degree resolution. fact=30 because res(land-use)/res(climatic)= 0,25/0,0083= 30
print("decreasing resolution of bioclim layers - complete")
print(date())
remove(fut_bioclim_au_stack)

#export cropped & low res. climatic layers 
setwd(paste0(output_dir,"fut_bio_au"))
writeRaster(fut_bio_coarse, filename = paste(names(fut_bio_coarse), ".tif",  sep=""), format="GTiff", overwrite=TRUE, bylayer=TRUE)




#3: RESCALE ALL LAYERS' VALUES FROM 0 to 1

#tutorial: http://www.wvview.org/spatial_analytics/Raster_Analysis/_site/index.html


# Rescaling values from 0 to 1: FUTURE DATA (BIOCLIM & LAND USE)

#upload bioclim low-res data 

setwd(paste0(output_dir,"fut_bio_au/")) 
wd<-getwd()
fut_bio_coarse <- list.files(path=wd, pattern="\\.tif$") 

print(paste("will read",length(fut_bio_coarse),"future bioclim layers")) # sanity check that grep selected the correct number of layers
fut_bio_coarse <- lapply(fut_bio_coarse, raster)
fut_bio_coarse_stack<-stack(fut_bio_coarse)
names(fut_bio_coarse_stack)

#upload land-use low-res data 

setwd(paste0(output_dir,"fut_land_au/")) 
wd<-getwd()
fut_land_coarse <- list.files(path=wd, pattern="\\.tif$") 

print(paste("will read",length(fut_land_coarse),"future land-use layers")) # sanity check that grep selected the correct number of layers
fut_land_coarse <- lapply(fut_land_coarse, raster)
fut_land_coarse_stack<-stack(fut_land_coarse)
names(fut_land_coarse_stack)

#combine fut low-res and rescale
fut_env_stack<-stack(fut_bio_coarse_stack,fut_land_coarse_stack)
var_min <- cellStats(fut_env_stack, stat=min)
var_max <- cellStats(fut_env_stack, stat=max)
fut_env_scale <- ((fut_env_stack - var_min)/(var_max - var_min))
names(fut_env_scale)


# Rescaling values from 0 to 1: HISTORICAL DATA (BIOCLIM & LAND USE)

#upload bioclim low-res data 

setwd(paste0(output_dir,"hist_bio_au/")) 
wd<-getwd()
hist_bio_coarse <- list.files(path=wd, pattern="\\.tif$") 

print(paste("will read",length(hist_bio_coarse),"hist bioclim layers")) # sanity check that grep selected the correct number of layers
hist_bio_coarse <- lapply(hist_bio_coarse, raster)
hist_bio_coarse_stack<-stack(hist_bio_coarse)

#upload land-use low-res data 

setwd(paste0(output_dir,"hist_land_au/")) 
wd<-getwd()
hist_land_coarse <- list.files(path=wd, pattern="\\.tif$") 

print(paste("will read",length(hist_land_coarse),"hist land-use layers")) # sanity check that grep selected the correct number of layers
hist_land_coarse <- lapply(hist_land_coarse, raster)
hist_land_coarse_stack<-stack(hist_land_coarse)

#combine fut low-res and rescale
hist_env_stack<-stack(hist_bio_coarse_stack,hist_land_coarse_stack)
var_min <- cellStats(hist_env_stack, stat=min)
var_max <- cellStats(hist_env_stack, stat=max)
hist_env_scale <- ((hist_env_stack - var_min)/(var_max - var_min))
names(hist_env_scale)


# Export rescaled & low res. ENVIRONMENTAL layers 

setwd(paste0(output_dir,"fut_env_au_resc"))
writeRaster(fut_env_scale, filename = paste(names(fut_env_scale), ".tif",  sep=""), format="GTiff", overwrite=TRUE, bylayer=TRUE)

setwd(paste0(output_dir,"hist_env_au_resc"))
writeRaster(hist_env_scale, filename = paste(names(hist_env_scale), ".tif",  sep=""), format="GTiff", overwrite=TRUE, bylayer=TRUE)

#upload created land-use and climatic low-res layers 

hist_env_au_resc <- list.files(path=paste0(output_dir,"hist_env_au_resc/"), pattern="\\.tif$",full.names = TRUE) 
hist_env_au_resc <- stack(hist_env_au_resc)

fut_env_au_resc <- list.files(path=paste0(output_dir,"fut_env_au_resc/"), pattern="\\.tif$", full.names = TRUE) 
fut_env_au_resc <- stack(fut_env_au_resc)

###END__________________________________________________________________________