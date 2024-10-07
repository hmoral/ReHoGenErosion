#!/bin/bash

# get arguments - yaml file
makefile=/groups/hologenomics/xufen/data/historicalreho_analysis/paleomix/paleomix_leftover.yaml

# load modules required by paleomix
module load hologenomics
module load htslib/v1.9
module load samtools
module load java
module load R
module load python/v3.6.9
module load bwa
module load bowtie2
module load AdapterRemoval
module load mapDamage
module load paleomix
module load picard/v2.25.2

name=$(basename $makefile | cut -f1 -d".")
echo $makefile
sbatch -p hologenomics-long -t 6-00:00:00 -c 24 --mem-per-cpu 2080 --mail-type ALL,TIME_LIMIT_50 --mail-user xhs315@alumni.ku.dk --job-name $name -o $name.out -- paleomix bam_pipeline run --max-thread=24 --bwa-max-threads=4 --jre-option=-Xmx8g $makefile
