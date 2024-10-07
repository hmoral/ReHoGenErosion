#!/bin/bash
#SBATCH --job-name popSFS_0624  # Job name
#SBATCH -c 3                   # Use cpu
#SBATCH --mem-per-cpu 20000
#SBATCH -t 10:00:00             # Time limit hrs:min:sec
#SBATCH --mail-type ALL,TIME_LIMIT_50,TIME_LIMIT_80 
#SBATCH --mail-user xhs315@alumni.ku.dk
#SBATCH -o popSFS_all_modern_noroh_0624.out


module load angsd/0.940
module load samtools
module load gcc
module load R/3.6.1



trans=0
#because SITE already discarded trans

SITE=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/SITES_12_23/HeHo_Ult44.list

ref=/projects/mjolnir1/people/xhs315/xhs315.xufen/ref_genomes/HeHo/chr_assembly/HeHo_1.0_HiC.fasta
# ☆
regions_file=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/SITES_12_23/0_no_roh_angsdformated.region
# ☆
MinDepth=40
MaxDepth=1600

echo -e "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ START $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"
echo "-noTrans set to $trans"

echo -e "angsd: $(date)"

outname=ReHo_modern_noroh
BAMlist=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/STAIRWAY/SFS_all_modern/modern_bam_20.list

angsd -bam $BAMlist -GL 2 -doMajorMinor 1 -doMaf 2 -dosaf 1 -anc $ref -ref $ref -doCounts 1 \
     -minQ 20 -minmapq 30 -sites ${SITE} -rf $regions_file -setMinDepth $MinDepth -setMaxDepth $MaxDepth -minInd 3  \
     -noTrans $trans -remove_bads 1 -uniqueOnly 1 -only_proper_pairs 1 -SNP_pval 1e-6 \
     -nthreads 20 -out ${outname}

echo -e "theta: $(date)"


realSFS ${outname}.saf.idx -P 4 -fold 1 -bootstrap 10 > ${outname}_fold1.b10.est.ml 
realSFS ${outname}.saf.idx -P 4 -bootstrap 10 > ${outname}_nofold.b10.est.ml 
cat ${outname}.b10.est.ml | R -e "f <- file('stdin');a<-scan(f);print(a[2]/sum(a))" 

realSFS ${outname}.saf.idx -P 4 -fold 1 > ${outname}_fold1.sfs 
realSFS saf2theta ${outname}.saf.idx -fold 1 -sfs ${outname}_fold1.sfs -P 4 -outname ${outname}
thetaStat do_stat ${outname}.thetas.idx -win 10000 -step 10000 -outnames ${outname}_fold1.10K.theta.thetasWindow.gz # -win 50000 -step 1000

realSFS ${outname}.saf.idx -P 4 > ${outname}_nofold.sfs 
realSFS saf2theta ${outname}.saf.idx -sfs ${outname}_nofold.sfs -P 4 -outname ${outname}
thetaStat do_stat ${outname}.thetas.idx -win 10000 -step 10000 -outnames ${outname}_nofold.10K.theta.thetasWindow.gz # -win 50000 -step 1000

echo -e "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ FINISH $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"