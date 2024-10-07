#!/bin/bash
#SBATCH --job-name 1_2_3_preprocessing  # Job name
#SBATCH --mem-per-cpu 4000
#SBATCH -c 24
#SBATCH -t 3-00:00:00
#SBATCH -o 1_2_3_preprocessing.out

module load jdk/1.8.0_291
module load picard
module load gatk/3.8

REF=/projects/mjolnir1/people/xhs315/xhs315.xufen/ref_genomes/HeHo/chr_assembly/HeHo_1.0_HiC.fasta



# modern

for PREFIX in ReHo16 ReHo18 ReHo19 ReHo20 ReHo21 ReHo22 ReHo23 ReHo26 ReHo35 \
ReHo36 ReHo38 ReHo40 ReHo42 ReHo44 ReHo47 ReHo48 ReHo51 ReHo53 ReHo55 ReHo57 \
ReHo58 ReHo59 ReHo61 ReHo63;

do

java -jar /groups/hologenomics/xufen/install/jar_root/picard.jar MarkDuplicates \
      I=/groups/hologenomics/xufen/data/modernreho_analysis/paleomix/${PREFIX}.HeHo.bam \
      O=/groups/hologenomics/xufen/data/modernreho_analysis/picard/${PREFIX}.HeHo.picard.bam \
      M=/groups/hologenomics/xufen/data/modernreho_analysis/picard/marked_dup_metrics_HeHo_${PREFIX}.txt

java -jar /groups/hologenomics/xufen/install/jar_root/picard.jar BuildBamIndex \
      I=/groups/hologenomics/xufen/data/modernreho_analysis/picard/${PREFIX}.HeHo.picard.bam
      O=/groups/hologenomics/xufen/data/modernreho_analysis/picard/${PREFIX}.HeHo.picard.bai

INPUT=/groups/hologenomics/xufen/data/modernreho_analysis/picard/${PREFIX}.HeHo.picard.bam
OUTRTC=/groups/hologenomics/xufen/data/modernreho_analysis/realign/${PREFIX}_realignertargetcreator.intervals
OUTPUT=/groups/hologenomics/xufen/data/modernreho_analysis/realign/${PREFIX}_indelrealigner.bam

gatk -T IndelRealigner \
    -R ${REF} \
    -targetIntervals ${OUTRTC} \
    -I ${INPUT} \
    -o ${OUTPUT}


done

#old Historicals
for PREFIX in s518 s521 s524 s527 s530 s519 s522 s525 s528 s531 s517 s520 s523 s526 s529 s532;

do

java -jar /groups/hologenomics/xufen/install/jar_root/picard.jar MarkDuplicates \
      I=/groups/hologenomics/xufen/data/historicalreho_analysis/paleomix/${PREFIX}.HeHo.bam \
      O=/groups/hologenomics/xufen/data/historicalreho_analysis/picard/${PREFIX}.his_HeHo.picard.bam \
      M=/groups/hologenomics/xufen/data/historicalreho_analysis/picard/marked_dup_metrics_his_HeHo_${PREFIX}.txt

java -jar /groups/hologenomics/xufen/install/jar_root/picard.jar BuildBamIndex \
      I=/groups/hologenomics/xufen/data/historicalreho_analysis/picard/${PREFIX}.his_HeHo.picard.bam
      O=/groups/hologenomics/xufen/data/historicalreho_analysis/picard/${PREFIX}.his_HeHo.picard.bai

INPUT=/groups/hologenomics/xufen/data/historicalreho_analysis/picard/${PREFIX}.his_HeHo.picard.bam
OUTRTC=/groups/hologenomics/xufen/data/historicalreho_analysis/realign/${PREFIX}_his_realignertargetcreator.intervals
OUTPUT=/groups/hologenomics/xufen/data/historicalreho_analysis/realign/${PREFIX}_his_indelrealigner.bam

gatk -T RealignerTargetCreator \
   -R ${REF} \
   -I ${INPUT} \
   -o ${OUTRTC}

done



# new Historicals
for PREFIX in s502 s503 s504 s505 s506 s507 s508 s509 s510 s511 s512 s513 s514 s515 s516;

do
# mark duplicates
picard MarkDuplicates \
      -I /projects/mjolnir1/people/xhs315/xhs315.xufen/Historical_analysis_2022new/paleomix/${PREFIX}.HeHo.bam \
      -O /projects/mjolnir1/people/xhs315/xhs315.xufen/Historical_analysis_2022new/picard/${PREFIX}.his_HeHo.picard.bam \
      -M /projects/mjolnir1/people/xhs315/xhs315.xufen/Historical_analysis_2022new/picard/marked_dup_metrics_his_HeHo_${PREFIX}.txt \
      --TMP_DIR /projects/mjolnir1/people/xhs315/xhs315.xufen/Historical_analysis_2022new/picard/

# indexing
picard BuildBamIndex \
      -I /projects/mjolnir1/people/xhs315/xhs315.xufen/Historical_analysis_2022new/picard/${PREFIX}.his_HeHo.picard.bam \
      -O /projects/mjolnir1/people/xhs315/xhs315.xufen/Historical_analysis_2022new/picard/${PREFIX}.his_HeHo.picard.bai

# realign
INPUT=/projects/mjolnir1/people/xhs315/xhs315.xufen/Historical_analysis_2022new/picard/${PREFIX}.his_HeHo.picard.bam
OUTRTC=/projects/mjolnir1/people/xhs315/xhs315.xufen/Historical_analysis_2022new/realign/${PREFIX}_realignertargetcreator.intervals
OUTPUT=/projects/mjolnir1/people/xhs315/xhs315.xufen/Historical_analysis_2022new/realign/${PREFIX}_indelrealigner.bam

java -jar  /projects/mjolnir1/people/xhs315/sofrware/GenomeAnalysisTK.jar -T RealignerTargetCreator \
   -R ${REF} \
   -I ${INPUT} \
   -o ${OUTRTC}



java -jar  /projects/mjolnir1/people/xhs315/sofrware/GenomeAnalysisTK.jar -T IndelRealigner \
    -R ${REF} \
    -targetIntervals ${OUTRTC} \
    -I ${INPUT} \
    -o ${OUTPUT}

done