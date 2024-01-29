#!/bin/bash

#SBATCH -p long
#SBATCH -c 8
#SBATCH --mem=16G
#SBATCH --export=ALL

source activate canu

canu -d canu \
 -p p557 \
-pacbio P55-7_CCS.fastq \
useGrid=false \
genomeSize="3000000" \
maxInputCoverage=10000