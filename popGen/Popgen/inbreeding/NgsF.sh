#!/bin/bash
#SBATCH --job-name Inbreeding   # Job name
#SBATCH -c 10                   # Use n cpu
#SBATCH --mem-per-cpu 10000
#SBATCH -t 1-0:00:00             # Time limit days-hrs:min:sec
#SBATCH -o NgsF_0911.out    # Standard output and error log
#SBATCH --mail-type ALL
#SBATCH --mail-user xhs315@alumni.ku.dk



# Load modules

module load angsd/0.940
module load gcc/13.2.0
module load openjdk/20.0.0
module load ngstools


SITE=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/SITES_12_23/HeHo_Ult44.list
ref=/projects/mjolnir1/people/xhs315/xhs315.xufen/ref_genomes/HeHo/chr_assembly/HeHo_1.0_HiC.fasta
INDEX=/projects/mjolnir1/people/xhs315/xhs315.xufen/ref_genomes/HeHo/chr_assembly/HeHo_1.0_HiC.fasta.fai
regions_file=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/SITES_12_23/chroms.chr
BAMS=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/PCA/FINAL_SITES_WG/Modern/Ultimate_modbam_20.list
outname=Modern_SITE_NgsF
n=$(wc -l $BAMS|cut -f1 -d" ")

MinDepth=10
MaxDepth=150
minind=18


n1=$(wc -l $BAMlist | cut -f1 -d" ")
n=$(awk -v n=$n1 'BEGIN{ printf "%.0f", n*0.75 }')

echo -e "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ Angsd START $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"
angsd -bam $BAMS -GL 2 -fai $INDEX -C 50 -doMajorMinor 1 -doMaf 2 -SNP_pval 1e-6 -minmaf 0.05 \
    -sites ${SITE} \
    -doGlf 3 \
    -ref $ref -doCounts 1 -setMinDepth $MinDepth -setMaxDepth $MaxDepth \
    -minMapQ 30 -minQ 20 \
    -noTrans 0 -minInd $minind -rf $regions_file \
    -nThreads 20 -out $outname

echo -e "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ Angsd END $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"

N_SITES=$((`zcat ${outname}.mafs.gz | wc -l`-1))
b=5



zcat ${outname}.glf.gz | ngsF --n_ind 21 --n_sites $N_SITES --glf - --min_epsilon 0.001 --n_threads 10 --init_values r --out ${outname}_F.approx_indF --approx_EM --seed 12345 1>&2
prev=${outname}_F.approx_indF.pars 

for j in $(seq 1 $b)
do
    echo -e "Run $j"
    zcat ${outname}.glf.gz | ngsF --n_ind $n --n_sites $N_SITES --glf - --min_epsilon 0.001 --n_threads 10 --init_values $prev --out ${outname}_F.${j}_indF 1>&2
    prev=${outname}_F.${j}_indF.pars
done

echo -e "Done"

ngsF --n_ind 21 --n_sites $N_SITES --glf ${outname}.glf --min_epsilon 0.001 --n_threads 10 --init_values r --out ${outname}_F.approx_indF --approx_EM --seed 12345 1>&2