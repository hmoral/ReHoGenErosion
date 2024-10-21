
###5_AVERAGING_MAPS

#Description:
#Averaging model output (probability of occurences maps) across subsets and across subset 1-10

#Steps:
##1. Averaging past maps across subset 1-10
##2. Averaging future maps across subset 1-10


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
raw_dir<-paste0(env_dir,"raw_data/")
output_dir<-paste0(env_dir,"output_data/")
dataframe_dir<-paste0(output_dir,"dataframe/")
dataframe_dir<-paste0(output_dir,"dataframe/")
models_dir<-paste0(data_dir,"models/")


#Define needed packages:
packages <- c( 'biomod2','raster','sf','corrplot') #list of needed packages (use search() to check which packages are loaded)

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


#Define species name:
species<- "anthochaera_phrygia" 


#Name run 

run_family<-"run_ap_mt" #species initials (ap) and multitemporal approach (mt)
summary<-c("_2024") #date
run_name<-paste0(run_family,summary)

#Name replicates subfixes #10 (1 for each dataframe subset)
replicates<-c()
for(i in 1:10){
  X<-paste0(summary,"_",i,collapse="_")
  replicates<-c(X,replicates)
}

##1. Averaging past maps across subset 1-10

#Save probability maps in MAPS folder

ens.methods <- c("MmeanBy","Mwmean", "MmedianBy", "McaBy", "McvBy", "MciSup","MciInf" )

#select period 
selected_years<-c(1901:2015)

algos<-c("GAM","RF")

for (REP in replicates){
  #REP=replicates[1]
  for (YEAR in selected_years) {
    #YEAR=selected_years[1]
    for (ALGO in algos) {
      #ALGO=algos[1]
      setwd(paste0(models_dir,sp,"/proj_",run_family,REP,"_",YEAR))
      
      #loading ensemble projection out and list of projections computed
      ens_proj_out_year<-get(load(paste0(sp,".",run_family,REP,"_", YEAR, ".ensemble.projection.out")))
      ens_projlist_year <- get_projected_models(ens_proj_out_year) # list of model names to select from
      
      #select ensemble method 
      modname <- ens_projlist_year[grep(ens.methods[1], ens_projlist_year)] 
      
      #select algoritm
      modname <- modname[grep(ALGO, modname)]
      
      #loading projections raster
      ens_proj_raster_year <- stack(paste0("proj_",run_family,REP,"_",YEAR,"_",sp,"_ensemble.tif"))
      ens_proj_raster_year <- raster(ens_proj_raster_year,modname)
       X<-stack(ens_proj_raster_year)
      names(X)<-paste0(run_family,REP,"_",ALGO,"_",YEAR)
      
      setwd(paste0(data_dir,"maps/",run_family,REP,"/" ))
      
      writeRaster(X, filename=names(X), format="GTiff", bylayer=F,overwrite=TRUE ) #layers for each year, global data, suffix="names"
      print(paste0("END FOR YEAR ",YEAR,"REP #",REP))
    }
  }
} 


# Averaging replicates

#select period

for (ALGO in algos){
  
  for (YEAR in selected_years){
    
    raster_mean_1year_algo <- c()
    
    for (REP in replicates){
      
      #upload yearly maps from different replicates
      
      setwd(paste0(data_dir,"maps/",run_family,REP,"/" ))
      
      raster_mean_1year_algo_rep <- list.files(path=getwd(), pattern=c(ALGO,"\\.tif$"))
      raster_mean_1year_algo_rep <- grep(paste0("_",YEAR), raster_mean_1year_algo_rep, value=T) 
     
       #in case this is a re-run, you will need to remove already averaged and subtracted layers
      #raster_mean_1year_algo_mean_rep <- grep("_mean_",raster_mean_1year_algo_rep,value = T)
      #raster_mean_1year_algo_difference_rep <- grep("_difference_",raster_mean_1year_algo_rep,value = T)
      #raster_mean_1year_algo_rep <- setdiff(raster_mean_1year_algo_rep,raster_mean_1year_algo_mean_rep)
      #raster_mean_1year_algo_rep <- setdiff(raster_mean_1year_algo_rep,raster_mean_1year_algo_difference_rep)
      
      X<-stack(raster(raster_mean_1year_algo_rep))
      raster_mean_1year_algo <- c(X, raster_mean_1year_algo)
      
    } 
    
    raster_mean_1year_algo<-stack(raster_mean_1year_algo)
    print("CALCULATING MEAN OF:")
    print(names(raster_mean_1year_algo))
    
    #calculate mean()
    mean_year_algo <- raster::calc(raster_mean_1year_algo, fun = mean)
    
    
    setwd(paste0(data_dir,"maps/summary",summary,"/" ))
    
    names(mean_year_algo)<-paste0(run_family,summary,"_replicate_mean_",ALGO,"_",YEAR)
    writeRaster(mean_year_algo, filename=names(mean_year_algo), format="GTiff", bylayer=F,overwrite=TRUE )
    
    setwd(paste0(data_dir,"maps/png/summary",summary,"/" ))
    
    
    
    #Preparing data for plotting
    
    #upload generic australia plot (from env data)
    australia_tif <- list.files(path=paste0(output_dir,"hist_env_au_resc/"), pattern="\\.tif$",full.names = TRUE) 
    australia_tif <- stack(australia_tif[[1]])
    values(australia_tif)[!is.na(values(australia_tif))] <- 1000
    
    extent(mean_year_algo)<-extent(australia_tif)
    res(mean_year_algo)<-res(australia_tif)
    ext <- extent(132,165,-39.30,-19)#specify plotting extent
    
    
    
    png(filename=paste0(names(mean_year_algo),".png"))
    
    plot(australia_tif,colNA=NA, col="grey90", ext=ext, legend=F)
    plot(mean_year_algo, add=TRUE, ext=ext,legend=T,xlim=c(135,160),ylim=c(-40,-20))
    
    title(sub=paste("Average across subsets","- Algorithm:",ALGO,"- Year:", YEAR,sep=" "),
          cex.sub=0.8)
    
    dev.off()
    
    print(paste0("SAVING RASTER AND AVERAGE MAP FOR ALGO ", ALGO, " - YEAR ", YEAR))
  }
}




##2. Averaging future maps across subset 1-10

sp<-as.character(gsub("_",".", species))
gcms <- c("gfdl.esm4","ipsl.cm6a.lr","mpi.esm1.2.hr","mri.esm2.0","ukesm1.0.ll")
scenarios <- c("ssp126","ssp370","ssp585")

# Averaging replicates

algos<-c("GAM","RF")

for (ALGO in algos){
  for (YEAR in c(2040,2070,2100)){
    for (SCENARIO in scenarios ){
      raster_mean_1year_algo <- c()
      for (REP in replicates){
    
        #upload periodical maps from different replicates
        
        
        setwd(paste0(data_dir,"maps/",run_family,REP,"/gcms_mean" ))
        
        raster_mean_1year_algo_rep <- list.files(path=getwd(), pattern=c(ALGO,"\\.tif$"))
        raster_mean_1year_algo_rep <- grep(paste0("_",YEAR), raster_mean_1year_algo_rep, value=T) 
        raster_mean_1year_algo_rep <- grep(paste0("_",SCENARIO), raster_mean_1year_algo_rep, value=T) 
        
        #
        #if you are re-running the code, you might need this 
        #raster_mean_1year_algo_mean_rep <- grep("_mean_",raster_mean_1year_algo_rep,value = T)
        #raster_mean_1year_algo_difference_rep <- grep("_difference_",raster_mean_1year_algo_rep,value = T)
        
        #raster_mean_1year_algo_rep <- setdiff(raster_mean_1year_algo_rep,raster_mean_1year_algo_mean_rep)
        #raster_mean_1year_algo_rep <- setdiff(raster_mean_1year_algo_rep,raster_mean_1year_algo_difference_rep)
        #
        
        X<-raster(raster_mean_1year_algo_rep)
        raster_mean_1year_algo <- c(X, raster_mean_1year_algo)
        
      } 
      
      raster_mean_1year_algo<-stack(raster_mean_1year_algo)
      print("CALCULATING MEAN OF LAYERS:")
      print(names(raster_mean_1year_algo))
      
      #calculate mean()
      mean_year_algo <- raster::calc(raster_mean_1year_algo, fun = mean)
      
      
      setwd(paste0(data_dir,"maps/summary",summary,"/" ))
      
      names(mean_year_algo)<-paste0(run_family,summary,"_replicate_gcms_mean_",SCENARIO,"_",ALGO,"_",YEAR)
      writeRaster(mean_year_algo, filename=names(mean_year_algo), format="GTiff", bylayer=F,overwrite=TRUE )
      
      setwd(paste0(data_dir,"maps/png/summary",summary,"/" ))
      
      #Preparing data for plotting
      
      #upload generic australia plot (from env data)
      australia_tif <- list.files(path=paste0(output_dir,"hist_env_au_resc/"), pattern="\\.tif$",full.names = TRUE) 
      australia_tif <- stack(australia_tif[[1]])
      values(australia_tif)[!is.na(values(australia_tif))] <- 1000
      
      extent(mean_year_algo)<-extent(australia_tif)
      res(mean_year_algo)<-res(australia_tif)
      ext <- extent(132,165,-39.30,-19)#specify plotting extent
      
      png(filename=paste0(names(mean_year_algo),".png"))
     
      plot(australia_tif,colNA=NA, col="grey90", ext=ext, legend=F)
      plot(mean_year_algo, add=TRUE, ext=ext,legend=T,xlim=c(135,160),ylim=c(-40,-20))
      
      title(sub=paste("Average across subsets","- Algorithm:",ALGO,"- Year:", YEAR,"\n","Average across GCM","- Scenario:",SCENARIO, sep=" "),
            cex.sub=0.8)
      
      dev.off()
      
      print(paste0("SAVING RASTER AND AVERAGE MAP FOR ALGO ", ALGO, " - YEAR ", YEAR, " - SCENARIO: ",SCENARIO ))
      
    }
  }
}



###END_________________________________________________________________________