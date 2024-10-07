#!/bin/bash
#SBATCH --job-name check_depth_historical_loop_real
#SBATCH -c 10                   # Use cpu
#SBARCH --mem-per-cpu 2000
#SBATCH -t 24:00:00             # Time limit hrs:min:sec
#SBATCH -o Check_depth_historical_loop_0306.out    # Standard output and error log
#SBATCH --mail-type ALL


module load perl
module load samtools

for PREFIX in s501 s502 s503 s504 s505 s506 s507 s508 s509 s510 s511 s512 s513 s514 s515 s516;

do

BAM=/projects/mjolnir1/people/xhs315/xhs315.xufen/Historical_analysis_2022new/realign/${PREFIX}_indelrealigner.bam
scaffold_list=/projects/mjolnir1/people/xhs315/xhs315.xufen/ref_genomes/HeHo/chr_assembly/region.txt

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