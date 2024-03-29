#!/bin/bash

## Script to download a bunch of sras
## Date: 4 August 2021

## Example usage:
## cd /Users/coke6162/repos/scripts/rnaseq-analysis
## workingDir=/scratch/Users/coke6162/yyyymmdd_RNA-seq_projectName/fastq \
## referenceFile=/Users/coke6162/repos/project_files/yyymmdd_RNA-seq_projectName/SRR.txt \
## sbatch --array 0-35 fasterq-dump.sbatch

# General settings
#SBATCH -p short
#SBATCH -N 1
#SBATCH -c 1
#SBATCH --time=12:00:00
#SBATCH --mem=4GB

# Job name and output
#SBATCH -J fasterq-dump
#SBATCH -o /Users/%u/sbatch_script/output/slurm-%A_%a.out
#SBATCH -e /Users/%u/sbatch_script/error/slurm-%A_%a.err

# Email notifications 
#SBATCH --mail-type=END                                         
#SBATCH --mail-type=FAIL                                        
#SBATCH --mail-user=coke6162@colorado.edu

# Set temporary dir
tmpDir=${workingDir}/tmp/${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}

# Define query files
# This works with a txt file where the first column (starting with row #2) contains SRR IDs
# If your SRR IDs are in a column other than the first, modify the 'print $1' argument
# If you do not have a header, remove the 'NR>1' argument
queries=($(cat ${referenceFile} | awk '(NR>1){print $1}'))

# Make temporary directory
pwd; hostname; date

echo "Making temporary directory..."

mkdir -p ${tmpDir}

# Run fastq-dump
echo $(date +"[%b %d %H:%M:%S] Downloading srr...")

echo "Working directory: " ${workingDir}
echo "fastq-dump version: "$(/Shares/CL_Shared/programs/sratoolkit.3.0.0-ubuntu64/bin/fasterq-dump --version)
echo "Processing sample: "${queries[$SLURM_ARRAY_TASK_ID]}

/Shares/CL_Shared/programs/sratoolkit.3.0.0-ubuntu64/bin/fasterq-dump \
--outdir ${workingDir} \
--threads 1 \
--mem 4GB \
--temp ${tmpDir} \
--split-files ${queries[$SLURM_ARRAY_TASK_ID]}

# Compress files
echo $(date +"[%b %d %H:%M:%S] Compressing files...")

gzip ${workingDir}/${queries[$SLURM_ARRAY_TASK_ID]}*.fastq

# Remove temporary dir
echo $(date +"[%b %d %H:%M:%S] Removing temporary directory...")

rm -r ${tmpDir}

echo $(date +"[%b %d %H:%M:%S] Done")