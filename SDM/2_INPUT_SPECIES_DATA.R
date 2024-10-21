
###2_INPUT_SPECIES_DATA

#Description:
#Downloading occurrences data for the species Regent Honeyeater from 1901 to 2015
#Defying area of interest for the analysis

#Author:
#Ester Milesi (University of Copenhagen, Denmark) - Contact: estermilesi96@gmail.com

#R version: 
#R-4.2.0

#Run date: 
print(Sys.Date())

#Directories:
data_dir <- "..." #ADD YOUR PROJECT DIRECTORY 
species_dir <- paste0(data_dir,"species_data/")
dir.create(species_dir) #occurences data directory

#Define needed packages:
packages <- c('sp','sf', 'adehabitatHR', 'devtools', 'countrycode', 'dplyr' ,'rgbif','rnaturalearthdata', 'maps', 'raster', 'rmapshaper', 'geosphere') #list of needed packages (use search() to check which packages are loaded)

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

# Load or install packages from GitHub
install_github("ropensci/CoordinateCleaner")
library(CoordinateCleaner)

##Downloading occurrences data for the species Regent Honeyeater from 1901 to 2015

#Define species name:
species<- "anthochaera_phrygia" 

#Download occurences: (source: GBIF)  
occ_url<-"http://api.gbif.org/v1/occurrence/download/request/0097737-200613084148143.zip" 
occ_dir<-paste0(species_dir,species,"_occurences")
occ_zip<-paste0(occ_dir,"_zipfile",".zip")
download.file(occ_url,occ_zip)
dir.create(occ_dir)
unzip(occ_zip,exdir=occ_dir) 

#Loading occurences:
occ<-list.files(path=occ_dir, pattern =c( "\\.csv$"), full.names = TRUE) 
occ<- read.csv(occ, header=T, sep = "\t") 
head(occ[c(13,16,17)])

#Remove NA: (from columns lat, long, year, species)
occ <-occ[!is.na(occ$decimalLatitude)& 
            !is.na(occ$decimalLongitude) & 
            !is.na(occ$year) & 
            !is.na(occ$species),] 

#Clean coordinates (using CoordinateCleaner)
#https://cran.r-project.org/web/packages/CoordinateCleaner/vignettes/Cleaning_GBIF_data_with_CoordinateCleaner.html

#Convert country code from ISO2c to ISO3c
occ$countryCode <-  countrycode(occ$countryCode, 
                                origin =  'iso2c',
                                destination = 'iso3c')

#flag problems
occ <- data.frame(occ)
flags <- clean_coordinates(x = occ, 
                           lon = "decimalLongitude", 
                           lat = "decimalLatitude",
                           countries = "countryCode",
                           species = "species",
                           tests = c("capitals", "centroids",
                                     "equal", "zeros", "countries")) # most test are on by default
summary(flags)
plot(flags, lon = "decimalLongitude", lat = "decimalLatitude")

#Exclude problematic records
occ <- occ[flags$.summary,]

#Filtering occurrences:
occ <- occ[occ$countryCode == "AUS",] #occurrences only from Australia
occ <- occ[occ$year >= 1901 & occ$year <= 2015,] #occurrences only for study period (1901-2015)
occ<-occ[!(occ$decimalLongitude < 130 & occ$decimalLatitude < -23), ] #manual removal of outliers          

nrow(occ)

occ_df<-as.data.frame(cbind(occ$species,occ$decimalLongitude,occ$decimalLatitude,occ$year))
names(occ_df)<-c("species","decimalLongitude","decimalLatitude","year")
write.csv(occ_df, file = paste0(species_dir,"filtered_and_cleaned_occ_",species,"_2024.csv") , row.names = F, col.names = T, sep=",") 



#Create table of coordinates and reformat long/lat values:
occ_sp_coords<-as.data.frame(cbind(as.character(occ$species), 
                                   as.numeric(occ$decimalLongitude), as.numeric(occ$decimalLatitude))) 
occ_sp_coords$V2<-as.character(occ_sp_coords$V2) #change format of coordinates
occ_sp_coords$V3<-as.character(occ_sp_coords$V3) #change format of coordinates
occ_sp_coords$V2 <-as.numeric(occ_sp_coords$V2) #change format of coordinates
occ_sp_coords$V3 <-as.numeric(occ_sp_coords$V3) #change format of coordinates
occ_sp<-as.data.frame(occ_sp_coords[,1]) #species info column 
occ_coords<-as.data.frame(occ_sp_coords[,c(2,3)]) #coordinates columns (lat, long)
occ_spdf<-SpatialPointsDataFrame(occ_coords,occ_sp,match.ID=T, 
                                 proj4string=CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0 "), 
                                 bbox = NULL) #proj4string(x) <-CRS("+proj=utm +zone=10 +datum=WGS84") #CRS("+proj=longlat +datum=WGS84") #create spatial point dataframe. Use 'plot(occ_spdf)' to plot result


##Defying area of interest for the analysis

#Used method: Kernel density calculation
#Resources: 
# https://jamesepaterson.github.io/jamespatersonblog/04_trackingworkshop_kernels
# https://www.researchgate.net/post/How_can_I_pass_a_grid_into_kernelUD_package_adehabitatHR_in_R

#Input data for Kernel density calculation

occ_spdf<-SpatialPointsDataFrame(occ_coords,occ_sp,match.ID=T, 
                                 proj4string=CRS("+proj=longlat +datum=WGS84 +no_defs"), 
                                 bbox = NULL) #proj4string(x) <-CRS("+proj=utm +zone=10 +datum=WGS84") #CRS("+proj=longlat +datum=WGS84") #create spatial point dataframe. 


#Plot input data:
plot(occ_spdf)

#Calculate Kernel:
kernel.ref <- kernelUD(occ_spdf, h = "href",extent = 1) #altering extent would allow to use percentage of kernel of 100%, but the output looks not ideal with extent=2
image(kernel.ref) #plot

#Extract kernel vertices:
kernel.vertices <- getverticeshr(kernel.ref, percent=99.9,unin = c("km"), unout = c("km2")) #alternative percentages: 99.9,98,95
plot(kernel.vertices) #plot

#Remove kernel outlier:
kernel<-ms_explode(kernel.vertices)
kernel<-kernel[1,]
plot(kernel) #plot

#Kernel Area:
print( paste0(geosphere::areaPolygon(kernel)," square meters"))
print( paste0(geosphere::areaPolygon(kernel)/1000000," square kilometers"))


#Save kernel:
kernel_sf <- sf::st_as_sf(kernel)
sf::st_write(kernel_sf, paste0(species_dir,"AOI_kernel99.9.geojson"))


###END__________________________________________________________________________