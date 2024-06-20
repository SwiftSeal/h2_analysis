#!/bin/bash

#SBATCH -p short
#SBATCH -c 4
#SBATCH --mem=8G
#SBATCH --export=ALL

mkdir -p star_align

READ_DIRECTORY="/mnt/shared/projects/jhi/potato/202110_RenSeq_Moray"

# Align reads to the genome in first pass
singularity exec -B /mnt/:/mnt/ docker://quay.io/biocontainers/star:2.7.11b--h43eeafb_1 STAR \
    --runThreadN 4 \
    --outFilterMultimapNmax 100 \
    --genomeDir star_index \
    --readFilesIn ${READ_DIRECTORY}/IL_S2_L001_R1_001.fastq.gz ${READ_DIRECTORY}/IL_S2_L001_R2_001.fastq.gz \
    --readFilesCommand zcat \
    --outFileNamePrefix star_align/infected_leaf. \
    --outSAMtype BAM Unsorted SortedByCoordinate

singularity exec -B /mnt/:/mnt/ docker://quay.io/biocontainers/star:2.7.11b--h43eeafb_1 STAR \
    --runThreadN 4 \
    --outFilterMultimapNmax 100 \
    --genomeDir star_index \
    --readFilesIn ${READ_DIRECTORY}/IR_S4_L001_R1_001.fastq.gz ${READ_DIRECTORY}/IR_S4_L001_R2_001.fastq.gz \
    --readFilesCommand zcat \
    --outFileNamePrefix star_align/infected_root. \
    --outSAMtype BAM Unsorted SortedByCoordinate

singularity exec -B /mnt/:/mnt/ docker://quay.io/biocontainers/star:2.7.11b--h43eeafb_1 STAR \
    --runThreadN 4 \
    --outFilterMultimapNmax 100 \
    --genomeDir star_index \
    --readFilesIn ${READ_DIRECTORY}/UNL_S1_L001_R1_001.fastq.gz ${READ_DIRECTORY}/UNL_S1_L001_R2_001.fastq.gz \
    --readFilesCommand zcat \
    --outFileNamePrefix star_align/uninfected_leaf. \
    --outSAMtype BAM Unsorted SortedByCoordinate

singularity exec -B /mnt/:/mnt/ docker://quay.io/biocontainers/star:2.7.11b--h43eeafb_1 STAR \
    --runThreadN 4 \
    --outFilterMultimapNmax 100 \
    --genomeDir star_index \
    --readFilesIn ${READ_DIRECTORY}/UNR_S3_L001_R1_001.fastq.gz ${READ_DIRECTORY}/UNR_S3_L001_R1_001.fastq.gz \
    --readFilesCommand zcat \
    --outFileNamePrefix star_align/uninfected_root. \
    --outSAMtype BAM Unsorted SortedByCoordinate

# Align reads to the genome in second pass using splice junctions from all samples
singularity exec -B /mnt/:/mnt/ docker://quay.io/biocontainers/star:2.7.11b--h43eeafb_1 STAR \
    --runThreadN 4 \
    --outFilterMultimapNmax 100 \
    --genomeDir star_index \
    --readFilesIn ${READ_DIRECTORY}/IL_S2_L001_R1_001.fastq.gz ${READ_DIRECTORY}/IL_S2_L001_R2_001.fastq.gz \
    --readFilesCommand zcat \
    --outFileNamePrefix star_align/infected_leaf.pass2. \
    --sjdbFileChrStartEnd star_align/*.out.tab \
    --outSAMtype BAM Unsorted SortedByCoordinate

singularity exec -B /mnt/:/mnt/ docker://quay.io/biocontainers/star:2.7.11b--h43eeafb_1 STAR \
    --runThreadN 4 \
    --outFilterMultimapNmax 100 \
    --genomeDir star_index \
    --readFilesIn ${READ_DIRECTORY}/IR_S4_L001_R1_001.fastq.gz ${READ_DIRECTORY}/IR_S4_L001_R2_001.fastq.gz \
    --readFilesCommand zcat \
    --outFileNamePrefix star_align/infected_root.pass2. \
    --sjdbFileChrStartEnd star_align/*.out.tab \
    --outSAMtype BAM Unsorted SortedByCoordinate

singularity exec -B /mnt/:/mnt/ docker://quay.io/biocontainers/star:2.7.11b--h43eeafb_1 STAR \
    --runThreadN 4 \
    --outFilterMultimapNmax 100 \
    --genomeDir star_index \
    --readFilesIn ${READ_DIRECTORY}/UNL_S1_L001_R1_001.fastq.gz ${READ_DIRECTORY}/UNL_S1_L001_R2_001.fastq.gz \
    --readFilesCommand zcat \
    --outFileNamePrefix star_align/uninfected_leaf.pass2. \
    --sjdbFileChrStartEnd star_align/*.out.tab \
    --outSAMtype BAM Unsorted SortedByCoordinate

singularity exec -B /mnt/:/mnt/ docker://quay.io/biocontainers/star:2.7.11b--h43eeafb_1 STAR \
    --runThreadN 4 \
    --outFilterMultimapNmax 100 \
    --genomeDir star_index \
    --readFilesIn ${READ_DIRECTORY}/UNR_S3_L001_R1_001.fastq.gz ${READ_DIRECTORY}/UNR_S3_L001_R2_001.fastq.gz \
    --readFilesCommand zcat \
    --outFileNamePrefix star_align/uninfected_root.pass2. \
    --sjdbFileChrStartEnd star_align/*.out.tab \
    --outSAMtype BAM Unsorted SortedByCoordinate