#!/bin/bash

#SBATCH -p short
#SBATCH -c 4
#SBATCH --mem=8G
#SBATCH --export=ALL

singularity exec -B /mnt/:/mnt/ docker://quay.io/biocontainers/star:2.7.11b--h43eeafb_1 STAR \
    --runThreadN 4 \
    --runMode genomeGenerate \
    --genomeDir star_index \
    --genomeFastaFiles assembly/P55_7.contigs.fasta
    