
###4_MODELLING

#Description:
#Species Distribution Model for the Regent Honeyeater using 'biomod2' package.
#Presence/PseudoAbsence dataframes are used to build the model. Once it is built, the model is projected to the past and to the future.
#Note: to build the model, you need to input P/PA dataframes. For projecting, you need to input envoronmental raster layers.


#Steps:
##1. FORMATTING INPUT DATA & BUILDING THE MODEL
##2. PROJECTING TO THE PAST (1901-2015)
##3. PROJECTING TO THE FUTURE (2015-2100)


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
dir.create(models_dir)
eval_dir <- paste0(data_dir,"evaluation_data/")
dir.create(eval_dir)

#Define needed packages:
packages <- c('biomod2', 'raster','sf','corrplot') #list of needed packages (use search() to check which packages are loaded)

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


#alternative installation for 'biomod2': install.packages("biomod2", dependencies = TRUE, repos = "http://cran.us.r-project.org")


#Define species name:
species<- "anthochaera_phrygia" 


#Upload Area Of Interest 

#Read kernel:

aoi_species_geo <- sf::st_read(paste0(species_dir,"AOI_kernel99.9.geojson"))
## convert the geometry of the `sf` object to SpatialPolygons
aoi_species <- sf::as_Spatial(st_geometry(aoi_species_geo), IDs = as.character(1:nrow(aoi_species_geo)))


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



##1: FORMATTING & BUILDING THE MODEL 


#Steps:
#S1.1: FORMATTING DATA 
#S1.2: BUILDING THE MODEL
#S1.3: ENSEMBLE 
#S1.4: MODEL EVALUATION 




#S1.1: FORMATTING DATA 


for(SUBSET in 1:10){
 
  #Assign name to run
  run_model<-paste0(run_name,"_",SUBSET) 
  
  #Model description
  
  print(paste("BIRD species consider:",species))
  print("modelling approach: multitemporal")
  print("input variable: land use + climatic")
  print(paste0("RUN NUMBER:",run_model))
  
  #Upload saved P/PA subset dataframe
  
  P_PA_env_subset <- list.files(path=dataframe_dir, pattern=c("\\.csv$"),full.names = TRUE)
  P_PA_env_subset <- grep(species,P_PA_env_subset,value = T)
  P_PA_env_subset <- grep(paste0("subset_",SUBSET,"_"),P_PA_env_subset,value = T)
  P_PA_env_subset <- read.csv(P_PA_env_subset, header=TRUE, sep = ",") 
  
  print("Number of Presences in P_PA_env_subset dataset:")
  print(nrow(P_PA_env_subset[P_PA_env_subset$P_PA==1,]))
  print("Number of Pseudo Absences in P_PA_env_subset dataset:")
  print(nrow(P_PA_env_subset[P_PA_env_subset$P_PA==0,]))
  
  #select NAs (we don't have to do it if we already have PA=2*P)
  #na_selected <- P_PA_env[sample(as.numeric(rownames(pa)), size= nrow(p)*2),]
  
  #NA removal (even if NA should be already been removed when creating P_PA_env dataframe)
  
  p_pa <- na.omit(P_PA_env_subset)

  #Creation of a P/NA column (final input in the formatting)
 
  P_na <-p_pa$P_PA 
  P_na<-ifelse(P_na==0, NA, 1)
  p_pa$P_na <- P_na #add column with 1 and NA
  p_na<-data.frame(as.numeric(p_pa$P_na)) #NEEDED FORMATTING 
  
  
  #Explanatory variables selection
  
  vars<-c("bio1","bio5","bio6","bio12","urban","crop","range","primf","secdf","pastr" ) #A. phyrgia #***TO EDIT***
  env_select <- p_pa[,names(p_pa) %in% c(vars)] #select variables in dataframe
  head(env_select)
 
  print(paste0("Rows of input env dataframe: ",nrow(env_select)))
  print(paste("correlation variables selected:"))
  print(cor(env_select))
  
  env_select_cor<-cor(env_select)
  
  #Plot correlations
  
  corrplot(env_select_cor, method="number", tl.col = "blue", bg = "white", 
           title = "\n\n Correlation Plot Regent Honeyeater Env Input Data \n",
           type = "lower",addCoef.col=T,addCoefasPercent=T) #addCoef.col = "green"
 
  print("uploading and selecting of env variables - complete")
  
  
  #BIOMOD_FormatingData()
  ?BIOMOD_FormatingData
  model_formatting_output<-BIOMOD_FormatingData(resp.name=species, 
                                                resp.var= p_na,  
                                                resp.xy = as.data.frame(cbind(p_pa$x, p_pa$y)),  
                                                
                                                expl.var = env_select,  
                                                PA.nb.rep=2, PA.nb.absences=sum(!is.na(p_pa$P_na)), PA.strategy='random',
                                                na.rm=FALSE) 
  print("Formatting the data - complete")
  
  
  save(model_formatting_output, file=paste0(models_dir,"/",run_model,"_formatting_output"))
  
}
#Note:  "! No data has been set aside for modeling evaluation" is not a problem: check forum  https://github.com/biomodhub/biomod2/issues/279



#S1.2: BUILDING THE MODEL

sp<-as.character(gsub("_",".", species))

for (SUBSET in 1:10){
  
  
  #Assign name to run
  run_model<-paste0(run_name,"_",SUBSET)
  
  #Upload formatting output
  file<-paste0(models_dir,"/",run_model,"_formatting_output")
  model_formatting_output<-get(load(file))
  remove(file)
  
  #BIOMOD_Modeling()
  model_options <- BIOMOD_ModelingOptions(GAM=list(k=2, family="binomial")) #to decrease complexity of the curve of GAM
  
  setwd(models_dir)
  model_building_output<-BIOMOD_Modeling(model_formatting_output,
                                         modeling.id=run_model,
                                        
                                         #models to be computed
                                         models = c("GAM","RF"),
                                         bm.options = model_options,
                                         
                                         #cross validation settings
                                         CV.strategy='random',
                                         CV.nb.rep=10, 
                                         CV.perc=0.70, 
                                         CV.do.full.models=FALSE,
                                         
                                         
                                         #evaluation metrics
                                         var.import =2,
                                         metric.eval = c("KAPPA", "TSS", "ROC"), 
                                         scale.models = TRUE, 
                                         
                                        
                                        ) 
  ?BIOMOD_Modeling
  
  #Explanation:
  #Generalized Additive Model; Random Forest 
  #NbRunEval=1 #Only one evaluation run because I didn't specified any evaluation data subset in the formatting function
  #DataSplit=70 #splitting in training (70%) and testing data (30%)
  #VarImport=2 #number of permutation to estimate variable importance
  #Yweights=NULL, #each observation has the same importance
  #models.eval.meth = c("KAPPA", "TSS", "ROC"), #evaluation methods
  #rescal.all.models = TRUE, #in a way that are comparable (rescaling like a GLM)
  #do.full.models = FALSE #to avoid doing model with entire dataset (better to split up in training and testing data)
  #SaveObj=T) #save object in hard drive
  #for model option, use output from BIOMOD_ModelingOptions()
  
  print(paste0("Building the model for subset ",SUBSET," - complete"))
  print(date())
  
}


#S1.3: ENSEMBLE 

sp<-as.character(gsub("_",".", species))

for(SUBSET in 1:10){
  
  #Assign name to run
  run_model<-paste0(run_name,"_",SUBSET) 
  
  #Upload output of model building
  
  file<-list.files(paste0(models_dir,sp),pattern = ".out",full.names = TRUE)
  file<-grep(paste0(run_model,".models"),file,value = TRUE)
  model_building_output<-get(load(file))
  remove(file)
  
  setwd(models_dir)

  
  # defining the  rules for generating consensus projections (which projections to combine and how) and for evaluating them
  EnsMod <- BIOMOD_EnsembleModeling(bm.mod = model_building_output, 
                                    
                                    #ensemble settings
                                    models.chosen = "all", 
                                    em.by="algo",#or "algo" (do we want to combine GAM and RF results or not?) 
                                    em.algo=c("EMmean","EMci","EMcv"),
                                    
                                    metric.select = 'ROC', 
                                    metric.select.thresh = 0.80, 
                                    
                                    #evaluation of ensemble
                                    metric.eval=c('ROC','TSS','KAPPA'),
                                    var.import=1
                                     
                                    )
                                    
  
  print("ensemble model: complete")
  print(run_model)
  
}


#S1.4: MODEL EVALUATION 

#Evaluation of Model building step (non-ensembled models)

eval_summary_subsets<-c()
var_imp_summary_subsets<-c()

for (SUBSET in 1:10){

  #Assign name to run
  run_model<-paste0(run_name,"_",SUBSET)
  print(paste0("EVALUATION FOR DATAFRAME SUBSET NUMBER ", SUBSET))
  
  #Upload output of model building
  file<-list.files(paste0(models_dir,sp),pattern = ".out",full.names = TRUE)
  file<-grep(paste0(run_model,".models"),file,value = TRUE)
  
  model_building_output<-get(load(file))
  remove(file)
  
  #Set correct directory
  
  setwd(models_dir)
  #Extract evaluation metrics - get_evaluations()
  model_eval<-get_evaluations(model_building_output)
  #Extract variables importance - get_variables_importance()
  model_imp<-get_variables_importance(model_building_output)
 
  #Add column specifying SUBSET
  model_eval$SUBSET<-rep(SUBSET, nrow(model_eval))
  model_imp$SUBSET<-rep(SUBSET, nrow(model_imp))
  
  print("Model evaluation subset:")
  print(colnames(model_eval))
  model_eval[c(1:10),c(1:5,9,10,12)]
  
  print("Variable importance subset:")
  print(colnames(model_imp))
  model_imp[c(1:10),c(1:7,8)]
  

  #Combine data in one summary .csv
  
  
  X<-model_eval
  eval_summary_subsets<-rbind(X,eval_summary_subsets)
  
  Y<-model_imp
  var_imp_summary_subsets<-rbind(Y,var_imp_summary_subsets)
  
}
    
write.csv(eval_summary_subsets,file=paste0(eval_dir,"models.out_evaluation_metrics_2024.csv"))
write.csv(var_imp_summary_subsets,file=paste0(eval_dir,"models.out_variables_importance_2024.csv"))




#Evaluation of Model ensemble step (ensembled models)

ensemble_eval_summary_subsets<-c()
ensemble_var_imp_summary_subsets<-c()

for (SUBSET in 1:10){

  #Assign name to run
  run_model<-paste0(run_name,"_",SUBSET)
  print(paste0("ENSEMBLE EVALUATION FOR DATAFRAME SUBSET NUMBER ", SUBSET))
  
  
  file<-list.files(paste0(models_dir,sp),pattern = ".out",full.names = TRUE)
  file<-grep(paste0(run_model,".ensemble.models"),file,value = TRUE)
  
  EnsMod<-get(load(file))
  remove(file)
  
  setwd(models_dir)
  #Extract evaluation metrics - get_evaluations()
  ens_model_eval<-get_evaluations(EnsMod)
  #Extract variables importance - get_variables_importance()
  ens_model_imp<-get_variables_importance(EnsMod)
  
  #Add column specifying SUBSET
  ens_model_eval$SUBSET<-rep(SUBSET, nrow(ens_model_eval))
  ens_model_imp$SUBSET<-rep(SUBSET, nrow(ens_model_imp))

  print("Ensemble Model evaluation subset:")
  print(colnames(ens_model_eval))
  print(ens_model_eval)
  
  print("Ensemble Variable importance subset:")
  print(colnames(ens_model_imp))
  print(ens_model_imp[c(1:10),])
  
  #Combine data in one summary .csv
  
  
  X<-ens_model_eval
  ensemble_eval_summary_subsets<-rbind(X,ensemble_eval_summary_subsets)
  
  Y<-ens_model_imp
  ensemble_var_imp_summary_subsets<-rbind(Y,ensemble_var_imp_summary_subsets)
  
}

write.csv(ensemble_eval_summary_subsets,file=paste0(eval_dir,"ensemble.models.out_evaluation_metrics_2024.csv"))
write.csv(ensemble_var_imp_summary_subsets,file=paste0(eval_dir,"ensemble.models.out_variables_importance_2024.csv"))


#AVERAGE EVALUATION METRICS

#Average ensemble_eval_summary_subsets (by column "calibration")
ensemble_eval_summary_subsets<-read.csv(file=paste0(eval_dir,"ensemble.models.out_evaluation_metrics_2024.csv"),header=TRUE, sep = ",")
ensemble_eval_ROC<-ensemble_eval_summary_subsets[ensemble_eval_summary_subsets$metric.eval=="ROC",]


ROC_GAM<-mean(ensemble_eval_ROC$calibration[ensemble_eval_ROC$merged.by.algo=="GAM"])
SD_ROC_GAM<-sd(ensemble_eval_ROC$calibration[ensemble_eval_ROC$merged.by.algo=="GAM"])
ROC_RF<-mean(ensemble_eval_ROC$calibration[ensemble_eval_ROC$merged.by.algo=="RF"])
SD_ROC_RF<-sd(ensemble_eval_ROC$calibration[ensemble_eval_ROC$merged.by.algo=="RF"])

MODEL<-unique(ensemble_eval_ROC$algo)
THRESHOLD<-"0.8" #metric.select.thresh in Ensemble 
FILTERBY<-"ROC"

mean_ensemble_eval_ROC<-cbind.data.frame(ROC_GAM,SD_ROC_GAM ,ROC_RF,SD_ROC_RF , MODEL,THRESHOLD,FILTERBY)

write.csv(mean_ensemble_eval_ROC,file=paste0(eval_dir,"ensemble.models.out_evaluation_metrics_ROCmean_2024.csv"))


#AVERAGE VARIABLES IMPORTANCE

#Average ensemble_var_imp_summary_subsets (by column "calibration")
ensemble_var_imp_summary_subsets<-read.csv(file=paste0(eval_dir,"ensemble.models.out_variables_importance_2024.csv"),header=TRUE, sep = ",")

#Extract variables

mean_ensemble_var_imp<-c()



for(VAR in vars){
 
  ensemble_var_imp_var_selection<-ensemble_var_imp_summary_subsets[ensemble_var_imp_summary_subsets$expl.var==VAR,]
  VAR_NAME<-as.character(VAR)
  
  
  for (ALGO in c("GAM","RF")){
 
 
  ensemble_var_imp_var<-ensemble_var_imp_var_selection[ensemble_var_imp_var_selection$merged.by.algo==ALGO,]
  
  EMmean<-ensemble_var_imp_var[ensemble_var_imp_var$algo=="EMmean",]
  EMmean<-mean(EMmean$var.imp)
  EMcv<-ensemble_var_imp_var[ensemble_var_imp_var$algo=="EMcv",]
  EMcv<-mean(EMcv$var.imp)
  EMciSup<-ensemble_var_imp_var[ensemble_var_imp_var$algo=="EMciSup",]
  EMciSup<-mean(EMciSup$var.imp)
  EMciInf<-ensemble_var_imp_var[ensemble_var_imp_var$algo=="EMciInf",]
  EMciInf<-mean(EMciInf$var.imp)
  
  X<-cbind.data.frame(VAR_NAME,EMmean,EMcv,EMciInf,EMciSup,ALGO)
  
  mean_ensemble_var_imp<-rbind(X,mean_ensemble_var_imp)
  }
}

write.csv(mean_ensemble_var_imp,file=paste0(eval_dir,"ensemble.models.out_variables_importance_mean_2024.csv"))


##2: PROJECTING TO THE PAST (1901-2015)

#Steps:
#S2.1: Projecting
#S2.2: Ensemble


sp<-as.character(gsub("_",".", species))

#Upload Area Of Interest 

aoi_species

#S2.1: Projecting


for (SUBSET in 1:10 ){
  
  
  #Assign name to run
  run_model<-paste0(run_name,"_",SUBSET)
  print(paste0("HINDCASTING FOR SUBSET NUMBER ", SUBSET))
  
  #Upload output of model building
  file<-list.files(paste0(models_dir,sp),pattern = ".out",full.names = TRUE)
  file<-grep(paste0(run_model,".models"),file,value = TRUE)
  
  model_building_output<-get(load(file))
  remove(file)
  
  #Set correct directory
  
  setwd(models_dir)
  
  #Extract variables
  vars <- get_formal_data(model_building_output, "expl.var.names")
  
  for (PROJ_YEAR in 1901:2015){
    
    env_au<-list.files(path=paste0(output_dir,"hist_env_au_resc"), pattern = "\\.tif$", full.names = TRUE)
    env_au<-grep(PROJ_YEAR,env_au,value = TRUE)
    env_au<-grep(paste0(vars,"_",collapse="|"),env_au,value = TRUE) #OR subset later: env_stack<-subset<-raster::subset(x=env_stack, grep(x=names(env_stack), pattern=paste( vars, collapse="_|" )))
    print(paste("will read",length(env_au),"env layers for year", PROJ_YEAR)) # sanity check that grep selected the correct number of layers
    env_au<- lapply(env_au,raster)
    env_stack<-stack(env_au)
    remove(env_au)
   
    plot(env_stack)
    #if bioclim and landuse are uploaded separately: do this
    #bio_resample<-resample(bio_stack, land_stack) #assuring that land and climatic data have the same features 
    #extent(bio_resample) <- extent(land_stack)    #assuring that land and climatic data have the same features 
    #env_stack<-stack( bio_resample, land_stack)
    
    env_mask<- mask(env_stack, aoi_species)
    env_mask_stack<-stack(env_mask)
    remove(env_mask)
    
    print(paste0("upload and mask of env layers - complete for year ",PROJ_YEAR))
    print(date())
   
    #change names to raster layers
    names(env_mask_stack)<-gsub("X[0-9][0-9][0-9][0-9]_au","",names(env_mask_stack),perl = F)
    names(env_mask_stack)<-gsub("_","",names(env_mask_stack),perl = F)
    names(env_mask_stack)<-gsub("X","",names(env_mask_stack),perl = F)
    names(env_mask_stack)<-gsub("au","",names(env_mask_stack),perl = F)
    
    print("names of raster layers for selected year:")
    print(names(env_mask_stack))
    
    #################
   
     #PROJECTION:
    
    projname<-paste0(run_name,"_",SUBSET,"_", PROJ_YEAR)
   
     model_proj_output <-BIOMOD_Projection(
                        bm.mod = model_building_output, 
                        new.env =  env_mask_stack, 
                        proj.name = projname,
                        on_0_1000 = FALSE,
                       # metric.binary = 'ROC',
                        selected.models = 'all', 
                        build.clamping.mask = F)
    
   
    print(paste("Projection to year" , PROJ_YEAR, "- complete"))
    print(date())
    
  }
}


#S2.2: Ensemble


for (SUBSET in 1:10 ){
  
  #Assign name to run
  run_model<-paste0(run_name,"_",SUBSET)
  print(paste0("ENSEMBLE EVALUATION FOR DATAFRAME SUBSET NUMBER ", SUBSET))
  
  
  file<-list.files(paste0(models_dir,sp),pattern = ".out",full.names = TRUE)
  file<-grep(paste0(run_model,".ensemble.models"),file,value = TRUE)
  
  EnsMod<-get(load(file))
  model_EMmeanByROC<-get_built_models(EnsMod)
  model_EMmeanByROC<-grep("EMmeanByROC",model_EMmeanByROC,value = T)
  
  remove(file)
  
  setwd(models_dir)
  
  for (PROJ_YEAR in 1901:2015){
    
    model_proj_out<-paste0(models_dir,sp,"/proj_",run_name,"_",SUBSET,"_",PROJ_YEAR,"/",sp,".",run_name,"_",SUBSET,"_",PROJ_YEAR,".projection.out")
    model_proj_output<-get(load(model_proj_out))
    
    setwd(models_dir)
    EnsProj <- BIOMOD_EnsembleForecasting(bm.em = EnsMod, 
                                          bm.proj = model_proj_output, 
                                          on_0_1000 = FALSE,
                                          metric.binary = NULL ,
                                          models.chosen = model_EMmeanByROC, 
                                          build.clamping.mask = F)
    print(paste0("End ensemble proj for year " , PROJ_YEAR , "(subset #", SUBSET, ")" ))
  }
  
}

?BIOMOD_EnsembleForecasting



##3: PROJECTING TO THE FUTURE (2015-2100)


#Steps:
#3.1: Projecting
#3.2: Ensemble
#3.3: Saving probabilty maps (raster+png) for different GCMs
#3.4: Averaging probability maps across different GCMs (keep SUBSETS separeted)

sp<-as.character(gsub("_",".", species))
gcms <- c("gfdl.esm4","ipsl.cm6a.lr","mpi.esm1.2.hr","mri.esm2.0","ukesm1.0.ll")
scenarios <- c("ssp126","ssp370","ssp585")

#Upload Area Of Interest 

aoi_species


#S3.1: Projecting

SCENARIO<-scenarios[1] #Manually loop the 3 scenarios (I did not do a loop for SCENARIO otherwise it was too much a complex loop)


for (SUBSET in 1:10){
  
  model_path<-paste0(models_dir,sp,"/",sp,".",run_name,"_",SUBSET,".models.out")
  model_building_output<-get(load(model_path))
  vars <- get_formal_data(model_building_output, "expl.var.names")
  
  
  for (PROJ_YEAR in c(2040,2070,2100)){
  
    
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
      
      
      
      #################
      
        setwd(models_dir)
     
      
      projname<-paste0(run_name,"_",SUBSET,"_",GCM,"_",SCENARIO,"_", PROJ_YEAR)
      
      model_proj_output <-BIOMOD_Projection(
        bm.mod = model_building_output, 
        new.env =  env_mask_stack, 
        proj.name = projname,
        on_0_1000 = FALSE,
        metric.binary = NULL ,
        selected.models = 'all', 
        build.clamping.mask = F)
      
      print(paste("Projection to year" , PROJ_YEAR, " - subset ",SUBSET , ": complete"))
      print(date())
      
    }
  }
}


#S3.2 Ensemble

SCENARIO<-scenarios[1] #Manually loop the 3 scenarios (I did not do a loop for SCENARIO otherwise it was too much a complex loop)

for (SUBSET in 1:10 ){
 
  model_path1<-paste0(models_dir,sp,"/",sp,".",run_name,"_",SUBSET,".ensemble.models.out")
  EnsMod<-get(load(model_path1))
  
  
  for (PROJ_YEAR in c(2040, 2070, 2100)){
    
    for (GCM in gcms){
    
      
      model_proj_output<-list.files(path=paste0(models_dir,sp,"/","proj_",run_name,"_",SUBSET,"_",GCM,"_",SCENARIO,"_",PROJ_YEAR),
                                    full.names = TRUE)
      model_proj_output<-grep(paste0(PROJ_YEAR,".projection.out"), model_proj_output, value = T)
      model_proj_output<-get(load(model_proj_output))
      
      
      setwd(models_dir)
      
      EnsProj <- BIOMOD_EnsembleForecasting(bm.em = EnsMod, 
                                            bm.proj = model_proj_output, 
                                             
                                            
                                            on_0_1000 = FALSE,
                                            metric.binary = NULL,
                                            models.chosen = 'all',
                                            build.clamping.mask = FALSE
                                            )
      
      print(paste0("End ensemble proj for year " , PROJ_YEAR , "(subset #", SUBSET, ") , SCENARIO ",SCENARIO,", GCM ",GCM ))
    }
  }
}
?BIOMOD_EnsembleForecasting


#3.3: Saving probabilty maps (raster+png) for different GCMs


#Create folders MAPS for probability raster and PNG for images

dir.create(path= paste0(data_dir,"maps/"))
dir.create(path= paste0(data_dir,"maps/png"))


for (i in replicates){
  
  dir.create(path= paste0(data_dir,"maps/",run_family,i,"/" ))
  dir.create(path= paste0(data_dir,"maps/png/",run_family,i,"/" ))
  dir.create(path= paste0(data_dir,"maps/",run_family,i,"/gcms_mean" ))
  dir.create(path= paste0(data_dir,"maps/png/",run_family,i,"/gcms_mean" ))
}

dir.create(path= paste0(data_dir,"maps/summary",summary,"/" ))
dir.create(path= paste0(data_dir,"maps/png/summary",summary,"/" ))


#Save probability (raster and png) maps

ens.methods <- c("MmeanBy","Mwmean", "MmedianBy", "McaBy", "McvBy", "MciSup","MciInf" )


SCENARIO <-scenarios[3]

for (SUBSET in 1:10){
  #SUBSET=1
  for (GCM in gcms){
    #GCM=gcms[1]
    for (PROJ_YEAR in c(2040,2070,2100)){
      #PROJ_YEAR=2040
      
        #loading ensemble projection output and list of projections computed
        path<-paste0(models_dir,sp,"/proj_",run_name,"_",SUBSET,"_",GCM,"_",SCENARIO,"_",PROJ_YEAR,"/")
        ens_proj_out_gcms_scenario_year<-list.files(path, full.names = TRUE, pattern = ".ensemble.projection.out")
        ens_proj_out_gcms_scenario_year<-get(load(ens_proj_out_gcms_scenario_year))
        ens_proj_out_gcms_scenario_year <- get_projected_models(ens_proj_out_gcms_scenario_year) # list of model names to select from
      
        #select ensemble method 
        modname <- ens_proj_out_gcms_scenario_year[grep(ens.methods[1], ens_proj_out_gcms_scenario_year)] 
        modname_RF <- modname[grep("RF",modname)]
        modname_GAM<- modname[grep("GAM",modname)]
        
        #loading projections rasters maps
        ens_proj_raster_gcms_scenario_year <- stack(paste0(path,"/proj_",run_name,"_",SUBSET,"_",GCM,"_",SCENARIO,"_",PROJ_YEAR,"_",sp,"_ensemble.tif"))
        ens_proj_raster_gcms_scenario_year_RF<-raster(ens_proj_raster_gcms_scenario_year, modname_RF)
        ens_proj_raster_gcms_scenario_year_GAM<-raster(ens_proj_raster_gcms_scenario_year, modname_GAM)
        
        XRF<-stack(ens_proj_raster_gcms_scenario_year_RF)
        XGAM<-stack(ens_proj_raster_gcms_scenario_year_GAM)
        
        names(XRF)<-paste0(run_name,"_",SUBSET,"_",GCM,"_",SCENARIO,"_","RF","_",PROJ_YEAR)
        names(XGAM)<-paste0(run_name,"_",SUBSET,"_",GCM,"_",SCENARIO,"_","GAM","_",PROJ_YEAR)
        res(XRF)<-c(0.25,0.25)
        res(XGAM)<-c(0.25,0.25)
        
        #save Tiff
        setwd(paste0(data_dir,"maps/",run_name,"_",SUBSET,"/" ))
        
        writeRaster(XRF, filename=names(XRF), format="GTiff", bylayer=F,overwrite=TRUE ) #layers for each year, global data, suffix="names"
        writeRaster(XGAM, filename=names(XGAM), format="GTiff", bylayer=F,overwrite=TRUE ) #layers for each year, global data, suffix="names"
        print(paste0("END FOR YEAR ",PROJ_YEAR,", SUBSET #",SUBSET))
      
        
        #preparing data for plotting
        
        #upload generic australia plot (from env data)
        australia_tif <- list.files(path=paste0(output_dir,"hist_env_au_resc/"), pattern="\\.tif$",full.names = TRUE) 
        australia_tif <- stack(australia_tif[[1]])
        values(australia_tif)[!is.na(values(australia_tif))] <- 1000

        
        extent(XRF)<-extent(australia_tif)
        extent(XGAM)<-extent(australia_tif)
        res(XRF)<-res(australia_tif)
        res(XGAM)<-res(australia_tif)
        
  
        #save png
        setwd(paste0(data_dir,"maps/png/",run_name,"_",SUBSET,"/" ))
        
        ext <- extent(132,165,-39.30,-19)#specify plotting extent
       
        #RF
        png(filename=paste0(names(XRF),".png"))
        
        plot(australia_tif,colNA=NA, col="grey90", ext=ext, legend=F)
        plot(XRF, add=TRUE, ext=ext,legend=T, xlab= paste0(run_name,"_",SUBSET),xlim=c(135,160),ylim=c(-40,-20))
   
        
        title(sub=paste("Subset:",SUBSET,"- Algorithm:","RF","- Year:", PROJ_YEAR,"\n","GCM:",GCM,"- Scenario:",SCENARIO,sep=" "),
             cex.sub=0.8)
        
        dev.off()
        
        #GAM
        png(filename=paste0(names(XGAM),".png"))
        
        plot(australia_tif,colNA=NA, col="grey90", ext=ext, legend=F)
        plot(XGAM, add=TRUE, ext=ext,legend=T,xlim=c(135,160),ylim=c(-40,-20))
        
        
        title(sub=paste("Subset:",SUBSET,"- Algorithm:","GAM","- Year:", PROJ_YEAR,"\n","GCM:",GCM,"- Scenario:",SCENARIO,sep=" "),
              cex.sub=0.8)
        
        dev.off()
        
        print(paste0("END FOR YEAR ",PROJ_YEAR,", SUBSET #",SUBSET))
      
    }
  } 
}


#S3.4: Averaging probability maps across different GCMs (keep SUBSETS separeted)

SCENARIO <-scenarios[1] #Manually loop the 3 scenarios (I did not do a loop for SCENARIO otherwise it was too much a complex loop)

algos<-c("GAM","RF")

for (SUBSET in 1:10){
  #SUBSET=1
  for (PROJ_YEAR in c(2040,2070,2100)){
    #PROJ_YEAR=2040
    for (ALGO in algos) {
      
      raster_mean_gcms <- c() #average between circulation models for single ALGO
      
      #upload maps from different gcms for the selected scenario, algo, year and replicate
      
      setwd(paste0(data_dir,"maps/",run_name,"_",SUBSET,"/" ))
      
      raster_gcms_list <- list.files(path=getwd(), pattern=c("\\.tif$"), full.names = T)
      raster_gcms_list <- grep(paste0("_",ALGO), raster_gcms_list, value=T) 
      raster_gcms_list <- grep(paste0("_",PROJ_YEAR), raster_gcms_list, value=T) 
      raster_gcms_list <- grep(paste0("_",SCENARIO), raster_gcms_list, value=T) 
      
      #if this code has already been run, you need also this part to exclude the mean layer 
      #raster_gcms_list_mean <- grep("_mean_",raster_gcms_list,value = T)
      #raster_gcms_list <- setdiff(raster_gcms_list,raster_gcms_list_mean)
      
      raster_gcms_list <- stack(raster_gcms_list)
      
      #calculate mean()
      mean_gcms <- raster::calc(raster_gcms_list, fun = mean)
      names(mean_gcms)<-paste0(run_name,"_",SUBSET,"_gcms_mean_",SCENARIO,"_",ALGO,"_",PROJ_YEAR)
      
      #save Tiff
      
      setwd(paste0(data_dir,"maps/",run_name,"_",SUBSET,"/gcms_mean" ))
      
      writeRaster(mean_gcms, filename=names(mean_gcms), format="GTiff", bylayer=F,overwrite=TRUE ) #layers for each year, global data, suffix="names"
      
      #preparing data for plotting
      
      #upload generic australia plot (from env data)
      australia_tif <- list.files(path=paste0(output_dir,"hist_env_au_resc/"), pattern="\\.tif$",full.names = TRUE) 
      australia_tif <- stack(australia_tif[[1]])
      values(australia_tif)[!is.na(values(australia_tif))] <- 1000
      
      extent(mean_gcms)<-extent(australia_tif)
      res(mean_gcms)<-res(australia_tif)
      
      #save png
      setwd(paste0(data_dir,"maps/png/",run_name,"_",SUBSET,"/gcms_mean" ))
      
      png(filename=paste0(names(mean_gcms),".png"))
      
      ext <- extent(132,165,-39.30,-19)#specify plotting extent
      plot(australia_tif,colNA=NA, col="grey90", ext=ext, legend=F)
      plot(mean_gcms, add=TRUE, ext=ext,legend=T,xlim=c(135,160),ylim=c(-40,-20))
    
      title(sub=paste("Subset:",SUBSET,"- Algorithm:","RF","- Year:", PROJ_YEAR,"\n","GCM: Average","- Scenario:",SCENARIO,sep=" "),
            cex.sub=0.8)
      dev.off()
      
      print(paste0("END FOR YEAR ",PROJ_YEAR,", SUBSET #",SUBSET, "ALGO: ", ALGO))
      
    }
  }
}


#END____________________________________________________________________________