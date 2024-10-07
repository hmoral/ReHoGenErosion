#!/bin/bash
#SBATCH --job-name SITE011924   # Job name
#SBATCH -c 20                   # Use two cpu
#SBATCH --mem-per-cpu 4000
#SBATCH -t 5-00:00:00             # Time limit hrs:min:sec
#SBATCH -o SITE_011924.out    # Standard output and error log
#SBATCH --mail-type ALL
#SBATCH --mail-user xhs315@alumni.ku.dk

module load angsd/0.940
module load winsfs/0.7.0

# -.*.-.*.-.*.-.*.-.*.-.*.-.*.-.*.-


# -.*.-.*.-.*.-.*.-.*.-.*.-.*.-.*.-

echo -e "START: $(date)"
echo "0119 - Ult"
echo "*** *** *** *** ***"

# flags

BAMlist=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/SITES_12_23/Ultimate_bam_44.list
outname=HeHo_Ult44
ref=/projects/mjolnir1/people/xhs315/xhs315.xufen/ref_genomes/HeHo/chr_assembly/HeHo_1.0_HiC.fasta

# no sex chromosomes - 230314
regions_file="/projects/mjolnir1/people/xhs315/xhs315.xufen/ref_genomes/HeHo/chr_assembly/region.txt"

echo -e ".-.*.-.angsd $(date).-.*.-."

angsd  -b $BAMlist -ref $ref -rf $regions_file -anc $ref  -out ${outname} \
    -uniqueOnly 1 -remove_bads 1 -only_proper_pairs 1 -skipTriallelic 1 -rmTrans 1 \
    -trim 0 -C 50 -baq 0 -minMapQ 20 -minQ 20 -doCounts 1 -minInd 2 -setMinDepth 4 -doMajorMinor 1 -GL 2 -doGlf 2 -doMaf 2

echo -e ".-.*.-.zcat $(date).-.*.-."

zcat ${outname}.mafs.gz  | awk '{print $1 , $2}' | sed 1d > ${outname}.list

echo -e ".-.*.-.index $(date).-.*.-."

angsd sites index ${outname}.list

echo -e ".-.*.-.test $(date).-.*.-."

# test on 1 individual
angsd  -i /projects/mjolnir1/people/xhs315/xhs315.xufen/modernreho_analysis/realign/ReHo16_indelrealigner.bam -ref $ref -sites ${outname}.list -rf ${regions_file} \
    -anc $ref -out ReHo16 -uniqueOnly 1 -remove_bads 1 -only_proper_pairs 1  -noTrans 1 -C 50 -baq 0 -minMapQ 30 -minQ 20 \
    -setMinDepth 3 -setMaxDepth 50 -doCounts 1 -nThreads 10 -GL 2 -doSaf 1

echo -e ".-.*.-.winsfs $(date).-.*.-."

winsfs ReHo16.saf.idx > ReHo16_filter_win.ml

echo -e ".-.*.-.DONE $(date).-.*.-."
