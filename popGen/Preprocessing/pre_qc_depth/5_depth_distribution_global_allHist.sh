#!/bin/bash
#SBATCH --job-name Depth_combined   # Job name
#SBATCH -c 12                   # Use cpu
#SBATCH -t 4:00:00             # Time limit hrs:min:sec
#SBATCH --mem-per-cpu 5000
#SBATCH --mail-type ALL
#SBATCH --mail-user xhs315@alumni.ku.dk
#SBATCH -o Depthglobal.out


module load angsd/0.935

bamlist=/projects/mjolnir1/people/xhs315/xhs315.xufen/Newoldhis_combined_2023/realigned/bam.filelist
out=/projects/mjolnir1/people/xhs315/xhs315.xufen/Newoldhis_combined_2023/depth_distribution/HisComb

angsd -bam $bamlist -doDepth 1 -out $out -doCounts 1 -minMapQ 30 -minQ 20 -dumpCounts 2 -maxDepth 5000