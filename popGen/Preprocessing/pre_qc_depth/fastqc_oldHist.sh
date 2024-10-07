#!/bin/bash
#SBATCH --mem-per-cpu 2000
#SBATCH -c 10
#SBATCH -p hologenomics

module load hologenomics
module load java
module load fastqc


for PREFIX in 518 521 524 527 530 519 522 525 528 531 517 520 523 526 529 532;

do

OUT=/groups/hologenomics/xufen/data/historicalreho_analysis/fastqc/${PREFIX}
mkdir -p ${OUT}

fastqc -t 10 -f fastq -o ${OUT} -noextract /groups/hologenomics/xufen/data/historical_reho/${PREFIX}/*.fq.gz

done

