#!/bin/bash
#SBATCH --job-name FastQC_histnew  # Job name
#SBATCH --mem-per-cpu 2000
#SBATCH -t 04:00:00             # Time limit hrs:min:sec
#SBATCH -c 10
#SBATCH -o 1027_fastqc_2.out

module purge
module load openjdk/13.0.1
module load perl/5.32.1
module load fastqc/0.11.9

which perl


for PREFIX in 505 506 507 508 509 510 511 512 513 514 515 516;

do

OUT=/projects/mjolnir1/people/xhs315/xhs315.xufen/Historical_analysis_2022new/fastqc/${PREFIX}
mkdir -p ${OUT}

export PERL5LIB=/projects/mjolnir1/apps/bin/perl

fastqc -t 10 -f fastq -o ${OUT} -noextract /projects/mjolnir1/people/xhs315/xhs315.xufen/Historical_Data/new2022/${PREFIX}/*gz

done

