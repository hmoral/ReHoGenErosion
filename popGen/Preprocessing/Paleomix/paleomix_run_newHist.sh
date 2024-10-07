#!/bin/bash
#SBATCH --job-name paleomix_newhist_2302167  # Job name
#SBATCH --mem-per-cpu 2080
#SBATCH --mail-type ALL,TIME_LIMIT_50
#SBATCH --mail-user xhs315@alumni.ku.dk
#SBATCH -t 6-00:00:00             # Time limit hrs:min:sec
#SBATCH -c 24
#SBATCH -o paleomix_newhist_230217.out

# get arguments - yaml file
# 24c, 6 days, 2080

makefile=/projects/mjolnir1/people/xhs315/xhs315.xufen/Historical_analysis_2022new/paleomix/paleomix_newhist.yaml

# load modules required by paleomix

module purge
module load paleomix/1.3.6


echo $makefile
paleomix bam_pipeline run --max-thread=24 --bwa-max-threads=4 --jar-root /projects/mjolnir1/apps/conda/paleomix-1.3.6/share/picard-2.27.2-0/ --jre-option=-Xmx8g $makefile
