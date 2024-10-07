#!/bin/bash
#SBATCH --job-name RoHan_historical_0425_old_ed  # Job name
#SBATCH -c 16                   # Use cpu
#SBATCH --mem-per-cpu 20000
#SBATCH -t 10:00:00             # Time limit hrs:min:sec
#SBATCH --mail-type ALL,TIME_LIMIT_50,TIME_LIMIT_80 
#SBATCH --mail-user xhs315@alumni.ku.dk
#SBATCH -o RoHan_historical_0425_old_ed.out

# -.*.-.*.-.*.-.*.-.*.-.*.-.*.-.*.-

# -.*.-.*.-.*.-.*.-.*.-.*.-.*.-.*.-

module load rohan
export PERL5LIB=/projects/mjolnir1/apps/bin/perl # to solve the perl issue - according to conversation with Bent feb 2023
module load samtools

# all variables
dir=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/RoHan/WG_rest/historical

ref=/projects/mjolnir1/people/xhs315/xhs315.xufen/ref_genomes/HeHo/chr_assembly/HeHo_1.0_HiC.fasta

autosomes=/projects/mjolnir1/people/xhs315/xhs315.xufen/ref_genomes/HeHo/chr_assembly/region.txt



for name in s518 s519 s521 s523 s524 s525 s528 s529 s530 s532;

do 

bam=/projects/mjolnir1/people/xhs315/xhs315.xufen/Newoldhis_combined_2023/realigned/${name}_his_indelrealigner.bam

# according to https://github.com/grenaud/ROHan/issues/8

echo "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ samtool $name $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"

# samtool runs for around 30min - give it enough time

samtools calmd -b ${bam} ${ref} > ${name}_calmd.bam
samtools index -b ${name}_calmd.bam

echo "✧*̥˚ samtool $name done *̥˚✧"

echo "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ perl $name $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"

# perl /projects/mjolnir1/apps/conda/rohan-20230903/rohan/src/estimateDamage.pl --length 50 --threads 16 -o $dir/${name}_pl $ref ${name}_calmd.bam


/home/xhs315/bin/rohan/src/estimateDamage.pl --length 10 --threads 16 -o $dir/${name} $ref ${name}_calmd.bam

echo "✧*̥˚ estimateDamage $name done *̥˚✧"

# echo "⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹ rohan $name $(date)⊹₊⋆☁︎⋆⁺₊⋆ ☀︎ ⋆⁺₊⋆☁︎⋆₊ ⊹"

# rohan -t 16  --size 500000 --rohmu 2e-5 --deam5p ${name}_1.5p.prof --deam3p ${name}_1.3p.prof --auto ${autosomes} -o ${dir}/${name}_ED_WG_2e5_500k $ref ${name}_calmd.bam

# echo "✧*̥˚ rohan $name done *̥˚✧"
echo "🗝️"
done