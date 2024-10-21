
###8_MESS_EXTRAPOLATION_ANALYSIS

#Description:
#A Multivariate Environmental Similarity Surface (MESS) analysis was performed 
#to account for potential model extrapolation issues when projecting the SDM to
#future or novel environmental conditions. MESS was needed because the focus of 
#the analysis was to transfer the model predictions to a different time period 
#than the calibration period.

#Author:
#Ester Milesi (University of Copenhagen, Denmark) - Contact: estermilesi96@gmail.com

#R version: 
#R-4.2.0

#Run date: 
print(Sys.Date())

#Directories:
data_dir <- "..." #ADD YOUR PROJECT DIRECTORY 
models_dir<-paste0(data_dir,"models/")
MESS_output_dir<-paste0(data_dir,"MESS_extrapolation_analysis/")
rasters_dir<-paste0(data_dir,"maps/summary_2024/")
species_dir <- paste0(data_dir,"species_data/")
env_dir <- paste0(data_dir,"env_data/")
output_dir<-paste0(env_dir,"output_data/")
dir.create(paste0(output_dir,"elevation_data"))
elevation_dir<-paste0(output_dir,"elevation_data")
dataframe_dir<-paste0(output_dir,"dataframe/")

#Define needed packages:
packages <- c('terra','RColorBrewer', 'rnaturalearth', 'rasterVis','elevatr','ecospat','raster') #list of needed packages (use search() to check which packages are loaded)

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

#MANUALLY SELECT SCENARIO (SC) AND PROJECTION YEAR (PJ) FOR WHICH YOU WANT TO CALCULATE MESS
#Example:
SC="ssp370"
PJ="2100"

#UPLOAD TRAINING DATA

#Upload model
run_family<-"run_ap_mt" #species initials (ap) and multitemporal approach (mt)
summary<-c("_2024") #date
run_name<-paste0(run_family,summary)
sp<-as.character(gsub("_",".", species))
run_model<-paste0(run_name,"_1") 
file<-list.files(paste0(models_dir,sp),pattern = ".out",full.names = TRUE)
file<-grep(paste0(run_model,".models"),file,value = TRUE)
model_building_output<-get(load(file))

#Extract variables from model
vars <- get_formal_data(model_building_output, "expl.var.names")

#Upload training data (used to build the model)

  #Upload saved P/PA subset dataframe
  
  P_PA_env_subset <- list.files(path=dataframe_dir, pattern=c("\\.csv$"),full.names = TRUE)
  P_PA_env_subset <- grep(species,P_PA_env_subset,value = T)
  P_PA_env_subset <- grep("subset_",P_PA_env_subset,value = T)
  P_PA_env_all_subsets<-c()
  
  for(PATH in P_PA_env_subset[1:10]){
    
    X <- read.csv(PATH, header=TRUE, sep = ",") 
   
    P_PA_env_all_subsets<-rbind.data.frame(X,P_PA_env_all_subsets)
    print(nrow(P_PA_env_all_subsets))
    }

head(P_PA_env_all_subsets)


#UPLOAD PROJECTION DATA (FUTURE)
sp<-as.character(gsub("_",".", species))
gcms <- c("gfdl.esm4","ipsl.cm6a.lr","mpi.esm1.2.hr","mri.esm2.0","ukesm1.0.ll")
scenarios <- c("ssp126","ssp370","ssp585")
proj_year<-c(2040,2070,2100)
future_data<-c()

for(SCENARIO in scenarios){

for (PROJ_YEAR in proj_year){
  
  
  layers_all<-list.files(path=paste0(output_dir,"fut_env_au_resc/"), pattern = "\\.tif$", full.names = TRUE)
  layers<-grep(PROJ_YEAR,layers_all,value = TRUE)
  
  
  for(GCM in gcms){
    
    bio_au<-grep(SCENARIO, layers, value = TRUE)
    bio_au<-grep(GCM, bio_au, value = TRUE)
    bio_au<-grep(paste0(vars,".tif",collapse="|"),bio_au,value = TRUE)
    
    land_au<-grep(SCENARIO, layers, value = TRUE)
    to_remove<-grep("bio", land_au, value = TRUE)
    land_au<-setdiff(land_au, to_remove)
    land_au<-grep(paste0(vars,"_",collapse="|"),land_au,value = TRUE)
    
    
    env_au<-c(bio_au,land_au)
    
    print(paste("will read",length(env_au),"env layers for year", PROJ_YEAR)) # sanity check that grep selected the correct number of layers
    print(env_au)
    
    
    env_au<- lapply(env_au,raster)
    env_stack<-stack(env_au)
    remove(env_au)
    
    env_mask<- mask(env_stack, aoi_species)
    env_mask_stack<-stack(env_mask)
    remove(env_mask)
    print(paste0("upload and mask of env layers - complete for year ",PROJ_YEAR))
    print(date())
    print("names of layers before modifying:")
    print(names(env_mask_stack))
    #change names to env raster layers
    names(env_mask_stack)<-gsub("X[0-9][0-9][0-9][0-9]_","",names(env_mask_stack),perl = F)
    names(env_mask_stack)<-gsub(SCENARIO,"",names(env_mask_stack),perl = F)
    names(env_mask_stack)<-gsub(GCM,"",names(env_mask_stack),perl = F)
    names(env_mask_stack)<-gsub("X__","",names(env_mask_stack),perl = F)
    names(env_mask_stack)<-gsub("__au","",names(env_mask_stack),perl = F)
    names(env_mask_stack)<-gsub("au_","",names(env_mask_stack),perl = F)
    names(env_mask_stack)<-gsub("_[0-9][0-9][0-9][0-9]_[0-9][0-9][0-9][0-9]","",names(env_mask_stack),perl = F)
    
    print("names of raster layers for selected year:")
    print(names(env_mask_stack))
    Y<-rasterToPoints(env_mask_stack)
    Y<-cbind.data.frame(Y,rep(SCENARIO,nrow(Y)),rep(PROJ_YEAR,nrow(Y)))
    
    head(Y)
    names(Y)[(ncol(Y)-1):ncol(Y)] <- c("scenario","proj_year")
    future_data<-rbind.data.frame(Y,future_data)
    
  }
}
}

nrow(future_data)
nrow(future_data[future_data$proj_year==proj_year[1],])


projData <- future_data[future_data$proj_year==PJ & future_data$scenario==SC,]

#Select needed columns (long,lat,vars)
envtData <- P_PA_env_all_subsets[c("x", "y",vars)]
head(envtData)

projData <- projData[,c("x", "y",vars)]
head(projData)

#Remove NAs
envtData <- na.omit(envtData)
projData <- na.omit(projData)

#Mess
mess <- ecospat.mess(proj = projData,
                                 cal = envtData)
#plot Mess map
ecospat.plot.mess(mess) 

#convert to df
mess_df<-as.data.frame(mess)
mess_df<-cbind.data.frame(mess_df$x,mess_df$y,mess_df$MESS)
names(mess_df)<-c("x","y","MESS")
head(mess_df)
