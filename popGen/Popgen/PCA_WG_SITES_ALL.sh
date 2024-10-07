#!/bin/bash
#SBATCH --job-name PCAngsd_0425  # Job name
#SBATCH -c 20                   # Use two cpu
#SBATCH --mem-per-cpu 4000
#SBATCH -t 10:00:00             # Time limit hrs:min:sec
#SBATCH -o PCAngsd_WG_SITES_0425.out    # Standard output and error log


module load angsd/0.940
module load pcangsd

echo -e "START: $(date)"

SITE=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/SITES_12_23/HeHo_Ult44.list
ref=/projects/mjolnir1/people/xhs315/xhs315.xufen/ref_genomes/HeHo/chr_assembly/HeHo_1.0_HiC.fasta
regions_file=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/SITES_12_23/chroms.chr

echo -e "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ Combined START $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"

# remember to put this script in the output folder
BAMlist=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/SITES_12_23/Ultimate_bam_44.list
outname=Combined/ReHo_PCA_WG_SITES_T0

MinDepth=20
MaxDepth=250
# 0.05-0.99 global depth - 230314
# need new comb gl depth - 230322 / 11-220 - 230324
minind=33
# 0.75 all individuals -230314

n1=$(wc -l $BAMlist | cut -f1 -d" ")
n=$(awk -v n=$n1 'BEGIN{ printf "%.0f", n*0.75 }')

echo -e "Calculating Genotypelikelihoods and calling snps"
angsd -bam $BAMlist -GL 2 -C 50 -doMajorMinor 1 -doMaf 2 -SNP_pval 1e-6 -minmaf 0.05 \
    -sites ${SITE} \
    -doGlf 2 \
    -ref $ref -doCounts 1 -setMinDepth $MinDepth -setMaxDepth $MaxDepth \
    -minMapQ 30 -minQ 20 \
    -noTrans 0 -minInd $minind -rf $regions_file \
    -nThreads 20 -out $outname


echo -e "Running PCA with PCAngsd"
echo -e "START: $(date)"

pcangsd -b ${outname}.beagle.gz -o $outname.pcangsd -t 20

echo "✧*̥˚ Combined END $(date) *̥˚✧"


echo -e "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ Historical START $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"

BAMlist=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/PCA/FINAL_SITES_WG/Historical/Ultimate_hisbam_24.list
outname=Historical/ReHo_PCA_WG_SITES_T0_his

MinDepth=10
MaxDepth=150
minind=18

n1=$(wc -l $BAMlist | cut -f1 -d" ")
n=$(awk -v n=$n1 'BEGIN{ printf "%.0f", n*0.75 }')

echo -e "Calculating Genotypelikelihoods and calling snps"
angsd -bam $BAMlist -GL 2 -C 50 -doMajorMinor 1 -doMaf 2 -SNP_pval 1e-6 -minmaf 0.05 \
    -sites ${SITE} \
    -doGlf 2 \
    -ref $ref -doCounts 1 -setMinDepth $MinDepth -setMaxDepth $MaxDepth \
    -minMapQ 30 -minQ 20 \
    -noTrans 0 -minInd $minind -rf $regions_file \
    -nThreads 20 -out $outname


echo -e "Running PCA with PCAngsd"
echo -e "START: $(date)"

pcangsd -b ${outname}.beagle.gz -o $outname.pcangsd -t 20

echo "✧*̥˚ Historical END $(date) *̥˚✧"



echo -e "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ Modern START $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"

# remember to put this script in the output folder
BAMlist=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/PCA/FINAL_SITES_WG/Modern/Ultimate_modbam_20.list
outname=Modern/ReHo_PCA_WG_SITES_T0_mod

MinDepth=10
MaxDepth=150
minind=15

n1=$(wc -l $BAMlist | cut -f1 -d" ")
n=$(awk -v n=$n1 'BEGIN{ printf "%.0f", n*0.75 }')

echo -e "Calculating Genotypelikelihoods and calling snps"
angsd -bam $BAMlist -GL 2 -C 50 -doMajorMinor 1 -doMaf 2 -SNP_pval 1e-6 -minmaf 0.05 \
    -sites ${SITE} \
    -doGlf 2 \
    -ref $ref -doCounts 1 -setMinDepth $MinDepth -setMaxDepth $MaxDepth \
    -minMapQ 30 -minQ 20 \
    -noTrans 0 -minInd $minind -rf $regions_file \
    -nThreads 20 -out $outname


echo -e "Running PCA with PCAngsd"
echo -e "START: $(date)"

pcangsd -b ${outname}.beagle.gz -o $outname.pcangsd -t 20

echo "✧*̥˚ Modern END $(date) *̥˚✧"
