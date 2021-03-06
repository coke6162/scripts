#!/bin/bash

## Script for running bbduk
## Date: 11 September 2019

## Example usage:
## cd /Users/coke6162/repos/scripts/cutnrun_analysis
## inDir=/Users/coke6162/project20xx_chipseq/fastq \
## outDir=/Users/coke6162/project20xx_chipseq/bbduk \
## adapterFile=/opt/bbmap/38.05/resources/adapters.fa \
## sbatch --array 0-18 bbduk_PE.sbatch

## adapterFile options: NexteraPE-PE.fa, TruSeq2-PE.fa, TruSeq3-PE-2.fa, TruSeq3-PE.fa

## General settings
#SBATCH -p short
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --time=5:00:00
#SBATCH --mem=64G

# Job name and output
#SBATCH -J bbduk_PE
#SBATCH -o /Users/%u/sbatch_script/output/slurm-%A_%a.out
#SBATCH -e /Users/%u/sbatch_script/error/slurm-%A_%a.err

# Email notifications
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=coke6162@colorado.edu

# Set constant variables
numThreads=1

# Load module
module load bbmap

# Define query files
# Removes R1/R2 to generate a unique identifier for each pair of files
# Modify to fit input file name if necessary
queries=($(ls ${inDir}/*fastq.gz | xargs -n 1 basename | sed --expression='s/_1.fastq.gz//g' | sed --expression='s/_2.fastq.gz//g' | uniq))

# Run bbduk
pwd; hostname; date

echo "bbduk version: "$(bbduk.sh --version)
echo "Processing file: "${queries[$SLURM_ARRAY_TASK_ID]}
echo $(date +"[%b %d %H:%M:%S] Running bbduk...")

bbduk.sh -Xmx4g in1=${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}_1.fastq.gz \
in2=${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}_2.fastq.gz \
out1=${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}_1_bbduk.fastq.gz \
out2=${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}_2_bbduk.fastq.gz \
ref=${adapterFile} \
ktrim=r k=31 mink=11 hdist=1 tpe tbo \
qtrim=r trimq=10 \
stats=${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}_stats.txt \
t=${numThreads}

echo $(date +"[%b %d %H:%M:%S] Done")