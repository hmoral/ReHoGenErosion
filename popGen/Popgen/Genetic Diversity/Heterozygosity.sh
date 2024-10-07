#!/bin/bash
#SBATCH --job-name thetaSITEregionbig  # Job name
#SBATCH -c 3                   # Use cpu
#SBATCH --mem-per-cpu 20000
#SBATCH -t 1-12:00:00             # Time limit hrs:min:sec
#SBATCH --mail-type ALL,TIME_LIMIT_50,TIME_LIMIT_80 
#SBATCH --mail-user xhs315@alumni.ku.dk
#SBATCH -o theta_noRoh_240619.out


module load angsd/0.921
module load samtools
module load gcc
module load R/3.6.1


trans=0
#because SITE already discarded SITE

SITE=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/SITES_12_23/HeHo_Ult44.list
# remember to put site and rf parameters

ref=/projects/mjolnir1/people/xhs315/xhs315.xufen/ref_genomes/HeHo/chr_assembly/HeHo_1.0_HiC.fasta
# ☆
regions_file=/projects/mjolnir1/people/xhs315/xhs315.xufen/Ultimate_MorHis/SITES_12_23/0_no_roh_angsdformated.region
# ☆
MinDepth=2
MaxDepth=80


echo "-noTrans set to $trans"

#
##
#### new historical ones ####
##
#


for bam in s502 s503 s504 s505 s506 s507 s508 s509 s510 s511 s512 s513 s514 s515 s516;

do 

echo -e "angsd: $(date)"
echo "Run angsd on $bam"

outname=ReHo_His_SITE_$bam

# -i 
angsd -i /projects/mjolnir1/people/xhs315/xhs315.xufen/Historical_analysis_2022new/realign/${bam}_indelrealigner.bam \
     -GL 2 -dosaf 1 -anc $ref -ref $ref -doCounts 1 \
     -minQ 20 -minmapq 30 -rf $regions_file -sites ${SITE} \
     -setMinDepth $MinDepth -setMaxDepth $MaxDepth \
     -noTrans $trans -remove_bads 1 -uniqueOnly 1 -only_proper_pairs 1 \
     -nthreads 20 -out ${outname}

echo -e "theta: $(date)"
echo "Run theta on $bam"

# for global heterozigosity
realSFS ${outname}.saf.idx -P 4 -fold 1 -bootstrap 10 > ${outname}.b10.est.ml # in my script, bootstrap=100, tole 1e-8, and out is .sfs
# tole = tolerence_for_breaking_EM
cat ${outname}.b10.est.ml | R -e "f <- file('stdin');a<-scan(f);print(a[2]/sum(a))"
done

#
##
#### old historical ones ####
##
#

for bam in s518 s519 s521 s523 s524 s525 s528 s529 s530 s532;

do 

echo -e "angsd: $(date)"
echo "Run angsd on $bam"

outname=ReHo_His_SITE_$bam

# -i 
angsd -i /projects/mjolnir1/people/xhs315/xhs315.xufen/Newoldhis_combined_2023/realigned/${bam}_his_indelrealigner.bam -GL 2 -dosaf 1 -anc $ref -ref $ref -doCounts 1 \
     -minQ 20 -minmapq 30 -rf $regions_file -sites ${SITE} \
     -setMinDepth $MinDepth -setMaxDepth $MaxDepth \
     -noTrans $trans -remove_bads 1 -uniqueOnly 1 -only_proper_pairs 1 \
     -nthreads 20 -out ${outname}

echo -e "theta: $(date)"
echo "Run theta on $bam"

# for global heterozigosity
realSFS ${outname}.saf.idx -P 4 -fold 1 -bootstrap 10 > ${outname}.b10.est.ml # in my script, bootstrap=100, tole 1e-8, and out is .sfs
# tole = tolerence_for_breaking_EM
cat ${outname}.b10.est.ml | R -e "f <- file('stdin');a<-scan(f);print(a[2]/sum(a))"

done

#
##
#### modern ones ####
##
#

for bam in ReHo18 ReHo20 ReHo23 ReHo35 ReHo38 ReHo40 ReHo44 ReHo47 ReHo48 ReHo51 ReHo53 ReHo55 ReHo57 ReHo58 ReHo59 ReHo61 ReHo63;

do 

echo -e "angsd: $(date)"
echo "Run angsd on $bam"

outname=ReHo_Mor_SITE_$bam

# -i 
angsd -i /projects/mjolnir1/people/xhs315/xhs315.xufen/modernreho_analysis/realign/${bam}_indelrealigner.bam -GL 2 -dosaf 1 -anc $ref -ref $ref -doCounts 1 \
     -minQ 20 -minmapq 30 -rf $regions_file -sites ${SITE} \
     -setMinDepth $MinDepth -setMaxDepth $MaxDepth \
     -noTrans $trans -remove_bads 1 -uniqueOnly 1 -only_proper_pairs 1 \
     -nthreads 20 -out ${outname}

echo -e "theta: $(date)"
echo "Run theta on $bam"

# for global heterozigosity
realSFS ${outname}.saf.idx -P 4 -fold 1 -bootstrap 10 > ${outname}.b10.est.ml # in my script, bootstrap=100, tole 1e-8, and out is .sfs
# tole = tolerence_for_breaking_EM
cat ${outname}.b10.est.ml | R -e "f <- file('stdin');a<-scan(f);print(a[2]/sum(a))"


done