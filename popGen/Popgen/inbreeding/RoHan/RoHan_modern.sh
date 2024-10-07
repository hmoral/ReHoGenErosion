#!/bin/bash
#SBATCH --job-name RoHan_ReHo16_0423  # Job name
#SBATCH -c 16                   # Use cpu
#SBATCH --mem-per-cpu 20000
#SBATCH -t 80:00:00             # Time limit hrs:min:sec
#SBATCH --mail-type ALL,TIME_LIMIT_50,TIME_LIMIT_80 
#SBATCH --mail-user xhs315@alumni.ku.dk
#SBATCH -o RoHan_all_modern_0424.out

# -.*.-.*.-.*.-.*.-.*.-.*.-.*.-.*.-

# -.*.-.*.-.*.-.*.-.*.-.*.-.*.-.*.-

module load rohan
export PERL5LIB=/projects/mjolnir1/apps/bin/perl # to solve the perl issue - according to conversation with Bent feb 2023
module load samtools

# all variables
dir=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/RoHan/WG_rest

ref=/projects/mjolnir1/people/xhs315/xhs315.xufen/ref_genomes/HeHo/chr_assembly/HeHo_1.0_HiC.fasta

autosomes=/projects/mjolnir1/people/xhs315/xhs315.xufen/ref_genomes/HeHo/chr_assembly/region.txt
# autosomes=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/RoHan/tests/region_2.txt

for name in ReHo18 ReHo19 ReHo22 ReHo42 ReHo20 ReHo23 ReHo35 ReHo38 ReHo40 ReHo44 ReHo47 ReHo48 ReHo51 ReHo53 ReHo55 ReHo57 ReHo58 ReHo59 ReHo61 ReHo63;
do
bam=/projects/mjolnir1/people/xhs315/xhs315.xufen/modernreho_analysis/realign/${name}_indelrealigner.bam
### don't run perl on modern samples ###

echo "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ rohan 500k $name $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"

rohan -t 16  --size 500000 --rohmu 2e-5 --auto ${autosomes} -o ${dir}/${name}_WG_2e5_500k $ref $bam

echo "✧*̥˚ 500k rohan $name done *̥˚✧"
echo "🗝️"
done