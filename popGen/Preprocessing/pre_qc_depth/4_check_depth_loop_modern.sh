#!/bin/bash
#SBATCH --job-name check_depth_modern_loop
#SBATCH -c 1                   # Use cpu
#SBARCH --mem-per-cpu 8000
#SBATCH -t 12:00:00             # Time limit hrs:min:sec
#SBATCH -p hologenomics
#SBATCH -o Check_depth_modern_loop.out    # Standard output and error log
#SBATCH --mail-type ALL,TIME_LIMIT_50,TIME_LIMIT_80

module load hologenomics
module load lib
module load htslib/v1.9 bcftools angsd python/v3.6.9 samtools

for PREFIX in  ReHo19  ReHo21  ReHo23  ReHo35\
ReHo42  ReHo47  ReHo51  ReHo55  ReHo58  ReHo61 ReHo18  ReHo20\
ReHo22  ReHo26  ReHo36  ReHo40  ReHo44  ReHo53  ReHo57  ReHo59  ReHo63;

do

BAM=/groups/hologenomics/xufen/data/Combined_bam/ReHo38_indelrealigner.bam
scaffold_list=/groups/hologenomics/xufen/data/ref_genomes/HeHo/chr_assembly/region.txt

SAMPLE=`echo $BAM | rev | cut -d "/" -f 1 | rev`
cat ${scaffold_list} | xargs samtools view -bh $BAM | samtools sort > tmp_subset_${SAMPLE}
samtools view tmp_subset_${SAMPLE} | awk '{sum+=$5} END { print "Mean MAPQ =",sum/NR}' >> summ_${SAMPLE}.txt
samtools depth tmp_subset_${SAMPLE} > tmp_depth_${SAMPLE}.txt
awk '{sum+=$3; sumsq+=$3*$3} END { print "Average DP= ",sum/NR; print "Stdev DP= ",sqrt(sumsq/NR - (sum/NR)**2)}' tmp_depth_${SAMPLE}.txt >> summ_${SAMPLE}.txt
((echo -n "sites DP>2=") && (awk '$3 > 2  {print ;}' tmp_depth_${SAMPLE}.txt | wc -l)) >> summ_${SAMPLE}.txt
((echo -n "sites DP>4=") && (awk '$3 > 4  {print ;}' tmp_depth_${SAMPLE}.txt | wc -l)) >> summ_${SAMPLE}.txt
((echo -n "sites DP>0=") && (awk '$3 > 0  {print ;}' tmp_depth_${SAMPLE}.txt | wc -l)) >> summ_${SAMPLE}.txt
rm tmp_subset_${SAMPLE} tmp_depth_${SAMPLE}.txt

done