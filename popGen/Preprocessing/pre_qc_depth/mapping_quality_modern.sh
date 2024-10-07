#!/bin/bash
#SBATCH --job-name mapping_quality   # Job name
#SBATCH -c 20                   # Use n cpu
#SBATCH --mem-per-cpu 4000
#SBATCH -t 3-00:00:00             # Time limit days-hrs:min:sec
#SBATCH -o mapping_quality.out    # Standard output and error log
#SBATCH -p hologenomics

module load hologenomics
module load java
module load qualimap/v2.2.2dev

for PREFIX in ReHo16 ReHo18 ReHo19 ReHo20 ReHo21 ReHo22 ReHo23 ReHo26 ReHo35 \
ReHo36 ReHo38 ReHo40 ReHo42 ReHo44 ReHo47 ReHo48 ReHo51 ReHo53 ReHo55 ReHo57 \
ReHo58 ReHo59 ReHo61 ReHo63;

do

qualimap bamqc -bam /groups/hologenomics/xufen/data/modernreho_analysis/realign/${PREFIX}_indelrealigner.bam -c -nw 400 -outdir /groups/hologenomics/xufen/data/modernreho_analysis/Mapping_quality/${PREFIX}

done