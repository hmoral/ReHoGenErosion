#!/bin/bash
#SBATCH --job-name ngsRelate   # Job name
#SBATCH -c 3                   # Use n cpu
#SBATCH -t 3-00:00:00             # Time limit hrs:min:sec
#SBATCH --mem-per-cpu 20000
#SBATCH -o ngsRelate.out    # Standard output and error log
#SBATCH --mail-type ALL,TIME_LIMIT_50 
#SBATCH --mail-user xhs315@alumni.ku.dk
#SBATCH -p hologenomics

module load hologenomics
module load lib
module load htslib angsd python/v3.6.9 ngsRelate

# Read arguments
bamlist=/groups/hologenomics/xufen/data/modernreho_analysis/realign/bamnooutliers.filelist
ids=/groups/hologenomics/xufen/data/modern_reho/ids_modern_reho_clean.txt
outname=/groups/hologenomics/xufen/data/modernreho_analysis/angsd/ngsRelate/ngsRelate_clean/modern_reho_clean
trans=1 # can be 0 or 1 
MinDepth=3
MaxDepth=284
minind=18

n=$(wc -l $ids | cut -f1 -d" ")
echo -e "Number of individuals: $n"


ref="/groups/hologenomics/xufen/data/ref_genomes/HeHo/chr_assembly/HeHo_1.0_HiC.fasta"
regions_file="/groups/hologenomics/xufen/data/ref_genomes/HeHo/chr_assembly/region.txt"

echo -e "Calculating Genotypelikelihoods and calling snps"
    

angsd -b $bamlist -GL 2 -domajorminor 1 -snp_pval 1e-6 -domaf 2 -minmaf 0.05 -doGlf 3 \
     -minMapQ 30 -minQ 20 -minInd $minind -noTrans $trans \
     -doCounts 1 -setMinDepth $MinDepth -setMaxDepth $MaxDepth \
     -remove_bads 1 -uniqueOnly 1 -only_proper_pairs 1 \
     -ref $ref -rf $regions_file \
     -nThreads 20 -out $outname


### Then we extract the frequency column from the allele frequency file and remove the header (to make it in the format NgsRelate needs)
zcat $outname.mafs.gz | cut -f6 | sed 1d > $outname.freq

### run NgsRelate
ngsRelate -g $outname.glf.gz -n $n -f $outname.freq -O $outname.ngsRelate -z $ids -p 20

### Estimate Inbreeding
ngsRelate -g $outname.glf.gz -F 1 -f $outname.freq -n $n -O $outname.ngsRelate.inbreeding -p 20 