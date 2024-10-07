library(data.table)
library(ggplot2)
library(patchwork)

args <- commandArgs(trailingOnly = TRUE)
# Load arguments
OUTpath=args[[1]]
brG=as.numeric(args[[2]]) # generation at which burn in period ends

LOADfile=list.files(OUTpath,"_loadSummary.txt",full.names = T)
LOAD=fread(LOADfile[1])
LOAD$genCor=LOAD$gen-brG # correct generation count from brun in time
LOAD$year=LOAD$genCor*3.4+(2016-(20*3.4)) # estimate years using generation time of 3.4 and year 2016 as present

p1=ggplot(LOAD,aes(gen,N,col=as.factor(pop))) + geom_line() + ggtitle("Ne over generation time")
p2=ggplot(LOAD,aes(year,N,col=as.factor(pop))) + geom_line() + ggtitle("Ne over transformed time to years")
P=(p1|p2)
ggsave(paste0(OUTpath,"/0_plot_time.png"),P,height = 4,width = 14)

p1=ggplot(LOAD[year>1900 & year < 2150],aes(year,N,col=as.factor(pop))) + geom_line()  + ggtitle("Ne over study period")
p2=ggplot(LOAD[year>1900 & year < 2150],aes(year,totalLoad,col=as.factor(pop))) + geom_line()  + ggtitle("Total load over study period")
p3=ggplot(LOAD[year>1900 & year < 2150],aes(year,mskLoad,col=as.factor(pop))) + geom_line()  + ggtitle("Masked load over study period")
p4=ggplot(LOAD[year>1900 & year < 2150],aes(year,relzLoad,col=as.factor(pop))) + geom_line()  + ggtitle("Realized load over study period")
P=(p1|p2)/(p3|p4)
ggsave(paste0(OUTpath,"/0_plot_genetic_load.png"),P,height = 8,width = 14)

GENdivfile=list.files(OUTpath,"_piNeutral.txt",full.names = T)
GENdiv=fread(GENdivfile[1])
GENdiv=fread("/Users/nrv690/Dropbox/Hernan_main_dropbox/GENDANGERED/Xufen/slim/0_new_April24/0_github/out_test/testFile_SCALE1_Nest1000_mPopN3_brT1000_brG1000_btlL10_btlNe100_future100_maxMig1_btlMig1_gN1000_gL200_chrN20_muChr2.3e-09_U0.5_muEx1.25e-06_endGen1200_seed372823186_piNeutral.txt")
GENdiv$genCor=GENdiv$gen-brG
GENdiv$year=GENdiv$genCor*3.4+(2016-(20*3.4))
p1=ggplot(GENdiv[year>1900 & year < 2150],aes(year,N,col=as.factor(pop))) + geom_line()  + ggtitle("Ne over study period")
p2=ggplot(GENdiv[year>1900 & year < 2150],aes(year,pi,col=as.factor(pop))) + geom_line()  + ggtitle("Nuc diversity over study period")
P=(p1|p2)
ggsave(paste0(OUTpath,"/0_plot_genetic_diversity.png"),P,height = 4,width = 14)

