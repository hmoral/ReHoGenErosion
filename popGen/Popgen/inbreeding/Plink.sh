#!/bin/bash
#SBATCH --job-name ROH_0911  # Job name
#SBATCH -c 20                   # Use cpu
#SBATCH --mem-per-cpu 4000
#SBATCH -t 4:30:00             # Time limit hrs:min:sec
#SBATCH --mail-type ALL
#SBATCH --mail-user xhs315@alumni.ku.dk
#SBATCH -o ROH_0911.out

module load angsd/0.940
module load plink
module load gcc/13.2.0
module load openjdk/20.0.0
module load R

SITE=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/SITES_12_23/HeHo_Ult44.list
ref=/projects/mjolnir1/people/xhs315/xhs315.xufen/ref_genomes/HeHo/chr_assembly/HeHo_1.0_HiC.fasta
regions_file=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/SITES_12_23/chroms.chr
BAMlist=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/PLINK_ROH/Ultimate_bam_modern_22.list
outname=ReHo_modern_SITES

echo -e "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ genotype likelihoods START $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"


MinDepth=3
MaxDepth=284
minind=15

n1=$(wc -l $BAMlist | cut -f1 -d" ")
n=$(awk -v n=$n1 'BEGIN{ printf "%.0f", n*0.75 }')


angsd -b $BAMlist -GL 2 \
    -sites ${SITE} \
    -minQ 20 -minMapQ 30 -rf $regions_file -doCounts 1 \
    -remove_bads 1 -uniqueOnly 1 -only_proper_pairs 1 \
    -minInd $minind -noTrans 0 -setMinDepth $MinDepth -setMaxDepth $MaxDepth \
    -doPlink 2 -doGeno -4 -doPost 1 -doMaf 2 -doMajorMinor 1 -minmaf 0.05 -SNP_pval 1e-6 \
    -nThreads 20 -out ${outname}




awk '{$n=$1 + 1; print "ReHo",$n,0,0,0,-9}' ${outname}.tfam > ${outname}.2.tfam

# run time : 3h 30min









source ~/.bash_profile
conda activate /projects/mjolnir1/apps/conda/plink-1.90b6.21

n1=$(wc -l $bamlist | cut -f1 -d" ")
n=$(awk -v n=$n1 'BEGIN{ printf "%.0f", n*0.75 }')
outname=ReHo_modern_SITES
echo "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ plink 2. HWE $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"

plink -tped ${outname}.tped -tfam ${outname}.2.tfam --recode -aec --out ${outname}

plink --file ${outname} --hardy -aec --out ${outname}.hwe

echo "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ plink 3. R script $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"

Rscript /projects/mjolnir1/people/xhs315/script/ANGSD/get_snps_hwe.r ${outname}.hwe.hwe
echo "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ plink 4. HWEq $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"

plink --file ${outname} --extract hwe_chrs.txt --recode --out ${outname}.HWEq -aec

echo "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ plink 4. map $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"
contigs=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/SITES_12_23/chroms.chr
chr_list=$(tr -s '\n ' ' ,' < $contigs)

plink --file ${outname}.HWEq --chr $chr_list --recode -aec --out ${outname}.HWEq.region_all
awk 'BEGIN{chr="";n=0} {if($1!=chr){chr=$1;n+=1;} print n"\t"$2"\t"$3"\t"$4}' ${outname}.HWEq.region_all.map > ${outname}.HWEq.region_all.2.map

echo "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ plink 5. pruning $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"

plink --file ${outname}.HWEq --indep-pairwise 50 10 0.8 -aec --out ${outname}.HWEq.prune1

plink --file ${outname}.HWEq --extract ${outname}.HWEq.prune1.prune.in -aec --recode --out ${outname}.HWEq.prune1.prune
sed 's/scaffold_//g' ${outname}.HWEq.prune1.prune.map > ${outname}.HWEq.prune1.prune.2.map

# Calcular ROH
echo "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ plink 6. ROH $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"
plink -file ${outname}.HWEq.prune1.prune --homozyg --homozyg-kb 10 --homozyg-gap 100 --homozyg-window-threshold 0.05 --homozyg-window-snp 30 --homozyg-window-missing 5 --homozyg-window-het 5 --homozyg-snp 50 --homozyg-density 50 --out ${outname}.10kb.HWEq.prune1.prune.005.5.50.50 --aec

Rscript /projects/mjolnir1/people/xhs315/script/plot_ROHs.r ${outname}.10kb.HWEq.prune1.prune.005.5.50.50

echo "$now"