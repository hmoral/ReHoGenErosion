#!/bin/bash
#SBATCH --job-name PCAngsd_0322   # Job name
#SBATCH -c 20                   # Use two cpu
#SBATCH --mem-per-cpu 4000
#SBATCH -t 4:00:00             # Time limit hrs:min:sec
#SBATCH -o PCAngsd_0322.out    # Standard output and error log
#SBATCH --mail-type ALL
#SBATCH --mail-user xhs315@alumni.ku.dk

module load angsd/0.935
module load pcangsd

echo -e "START: $(date)"


echo "0322 - hisComb"
echo "*** *** *** *** ***"

# remember to put this script in the output folder

BAMlist=/projects/mjolnir1/people/xhs315/xhs315.xufen/Newoldhis_combined_2023/realigned/bam.filelist
outname=HeHo_HisComb
ref=/projects/mjolnir1/people/xhs315/xhs315.xufen/ref_genomes/HeHo/chr_assembly/HeHo_1.0_HiC.fasta

# no sex chromosomes - 230314
regions_file="/projects/mjolnir1/people/xhs315/xhs315.xufen/ref_genomes/HeHo/chr_assembly/region.txt"

MinDepth=11
MaxDepth=220
# 0.05-0.99 global depth - 230314
# need new comb gl depth - 230322 / 11-220 - 230324
# total ind = 28
minind=20
# 0.75 all individuals -230314

n1=$(wc -l $BAMlist | cut -f1 -d" ")
n=$(awk -v n=$n1 'BEGIN{ printf "%.0f", n*0.75 }')

# getting GLs and Snp call in BEAGLE format
## if ANCIENT data -> -noTrans 1
# "3. if you work with ancient data. You can discard transition by adding -noTrans 1, to the angsd part of the code."

echo -e "Calculating Genotypelikelihoods and calling snps"
angsd -bam $BAMlist -GL 2 -C 50 -doMajorMinor 1 -doMaf 2 -SNP_pval 1e-6 -minmaf 0.05 \
    -doGlf 2 \
    -ref $ref -doCounts 1 -setMinDepth $MinDepth -setMaxDepth $MaxDepth \
    -minMapQ 30 -minQ 20 \
    -noTrans 1 -minInd $minind -rf $regions_file \
    -nThreads 20 -out $outname


echo -e "Running PCA with PCAngsd"
echo -e "START: $(date)"

# Run PCangsd
# Using EM algorithm based on ngsF from -1 to 1
pcangsd -beagle ${outname}.beagle.gz -o $outname.pcangsd -threads 20


echo -e "END: $(date)"

echo "0322 - hisComb"
echo "*** *** *** *** ***"
