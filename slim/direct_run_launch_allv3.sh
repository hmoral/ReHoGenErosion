#!/bin/bash

#./direct_run_launch_allv3.sh out_test testFile 200 1000 20 1000 1 1e-08 0.5 3 1000 100 10 1 1

seed=`echo ${RANDOM}${RANDOM}`

outDIR=$1 # ouput path
mkdir -p ${outDIR} 
FILEname=$2 # output prefix
outName=${FILEname} 
geneLength=$3 # exome gene lenght
g=$4 # exome gene count
chrNum=$5 # exome genes distributied in N chromsome number
Ne=$6 # intial Ne for the metapaopulation
maxMig=$7 # maximum migration, set to 1 to use migration rates used in paper, lower or higher as multiplying factor. Set to 1 
muChrom_in=$8 #  mutation rate for chromsome region 
U_in=$9 # mutation rate for exome region in mutation per diploid genome, final rate depends on exome lenght
muFactor=${10} # experimental mutation divided by a set factor to achieve stable diversity between msprime and slim runs, always set to 3
burnT=${11} # generations for burning period of deleterious mutations in step #4
btlNe_in=${12} # bottleneck Ne
btlL=${13} # bottleneck lenght
btlMig=${14} # migration mutliplying factor after bottleneck to test effect of reducing migration rates after bottleneck. Set to 1 
SCALE=1 # experimental mu and roh scaling always set to 1

FILEin=${FILEname}_gN${g}_gL${geneLength}_chrN${chrNum}_SCALE${SCALE}_seed${seed}

coord_file_in="coords_SLiM_GCF_000247815.1_FicAlb1.5_chr23.txt"
rho_file_in="out_rho4Ne_win2e+05_col.hun.snpPair_runALL_chr23.txt"
hs_in="1_hs_prod1_hmode1_Ne20K_step40K.txt"

echo "### Starting file for mutation and recombination rates"
echo "COMMAND" `date` slim -d "runtype=1" -d "coord_file_in='${coord_file_in}'" -d "rho_file_in='${rho_file_in}'" -d "hs_in='${hs_in}'" -d "g=${g}" -d "geneLength=${geneLength}" -d "chrNum=${chrNum}" -d "outDIR='./'" -d "outName='${outDIR}/${outName}'" -d "SCALE=${SCALE}" -d "seed='${seed}'" ReHo_metapop_nonWF_WF_msprimeIN_v3_250624.slim
# step 1
slim -d "runtype=1" -d "coord_file_in='${coord_file_in}'" -d "rho_file_in='${rho_file_in}'" -d "hs_in='${hs_in}'" -d "g=${g}" -d "geneLength=${geneLength}" -d "chrNum=${chrNum}" -d "outDIR='./'" -d "outName='${outDIR}/${outName}'" -d "SCALE=${SCALE}" -d "seed='${seed}'" ReHo_metapop_nonWF_WF_msprimeIN_v3_250624.slim

echo "### msprime burn file"
echo "COMMAND" `date` python ReHo_metapop_nonWF_msprime_burnIn_v1_110123.py --muChrom_in ${muChrom_in} --U_in ${U_in} --muFactor ${muFactor} --Ne ${Ne} --maxMig ${maxMig} --FILEname ${outDIR}/${FILEin} --FILEin ${outDIR}/${FILEin} --geneLength ${geneLength} --g ${g} --seed ${seed} --SCALE ${SCALE}
# step 2
python ReHo_metapop_nonWF_msprime_burnIn_v2_110123.py --muChrom_in ${muChrom_in} --U_in ${U_in} --muFactor ${muFactor} --Ne ${Ne} --maxMig ${maxMig} --FILEname ${outDIR}/${FILEin} --FILEin ${outDIR}/${FILEin} --geneLength ${geneLength} --g ${g} --seed ${seed} --SCALE ${SCALE}
source ${outDIR}/${FILEin}_set_variables.sh
echo $FILE
echo $chrSize
#chrSize=8001001

echo "### msprime burn conversion"
echo "COMMAND" `date` slim -d "chrSize=${chrSize}" -d "treeIN='${FILE}.tree'" ReHo_metapop_nonWF_msprime_conversion.slim
# step 3
slim -d "chrSize=${chrSize}" -d "treeIN='${FILE}.tree'" ReHo_metapop_nonWF_msprime_conversion.slim
#rm /Users/nrv690/Dropbox/Hernan_main_dropbox/GENDANGERED/Xufen/slim/0_new_dec23/0_out_test_may2024/*
initNe=${Ne}
#burnT=5

echo "### slim run"
echo "COMMAND" `date` slim -t -d "runtype=0" -d "btlMig=${btlMig}" -d "btlL=${btlL}" -d "coord_file_in='${coord_file_in}'" -d "rho_file_in='${rho_file_in}'" -d "hs_in='${hs_in}'" -d "g=${g}" -d "geneLength=${geneLength}" -d "chrNum=${chrNum}" -d "btlNe_in=${btlNe_in}" -d "outDIR='${outDIR}'" -d "outName='${outName}'" -d "maxMig=${maxMig}" -d "burnT=${burnT}" -d "initNe=${initNe}" -d "slimIn='${FILE}_fullOut.slim'" -d "SCALE=${SCALE}" -d "seed='${seed}'" ReHo_metapop_nonWF_WF_msprimeIN_v3_250624.slim
# step 4
slim -t -d "runtype=0" -d "btlMig=${btlMig}" -d "btlL=${btlL}" -d "coord_file_in='${coord_file_in}'" -d "rho_file_in='${rho_file_in}'" -d "hs_in='${hs_in}'" -d "g=${g}" -d "geneLength=${geneLength}" -d "chrNum=${chrNum}" -d "btlNe_in=${btlNe_in}" -d "outDIR='${outDIR}'" -d "outName='${outName}'" -d "maxMig=${maxMig}" -d "burnT=${burnT}" -d "initNe=${initNe}" -d "slimIn='${FILE}_fullOut.slim'" -d "SCALE=${SCALE}" -d "seed='${seed}'" ReHo_metapop_nonWF_WF_msprimeIN_v3_250624.slim

