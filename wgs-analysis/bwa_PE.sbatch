#!/bin/bash

## Script for running bwa
## Date: 6 February 2020 

## Example usage:
## cd /Users/coke6162/repos/scripts/wgs-analysis
## parentDir=/scratch/Users/coke6162 \
## projectName=yyyymmdd_wgs_projectName \
## bwaIndex=/Shares/CL_Shared/db/genomes/bosTau9/1000_Bull_Genomes_Project/index/bwa/ARS-UCD1.2_Btau5.0.1Y.main \
## sbatch --array 0-35 bwa_PE.sbatch

## General settings
#SBATCH -p short
#SBATCH -N 1
#SBATCH -n 8
#SBATCH --time=24:00:00
#SBATCH --mem=16GB

# Job name and output
#SBATCH -J bwa
#SBATCH -o /Users/%u/sbatch_script/output/slurm-%A_%a.out
#SBATCH -e /Users/%u/sbatch_script/error/slurm-%A_%a.err

# Email notifications 
#SBATCH --mail-type=END                                         
#SBATCH --mail-type=FAIL                                        
#SBATCH --mail-user=coke6162@colorado.edu

# Load modules
module load bwa
module load samtools

# Set constant variables
numThreads=8

# Define path variables
inDir=${parentDir}/${projectName}/fastq
outDir=${parentDir}/${projectName}/bwa

# Define query files
# This will include all identifying information except for the file suffix
# Modify sed arguments to fit your naming system (i.e. R1 instead of 1)
queries=($(ls ${inDir}/*.fastq.gz | xargs -n 1 basename | sed 's/_1.fastq.gz//g' | sed 's/_2.fastq.gz//g' | uniq))

# Set sample variable (i.e. Limousin2)
# This stores everything up to the first underscore as the sample information
# For example, this will work with 'Limousin2_run1_lane1'
sample=$(echo ${queries[$SLURM_ARRAY_TASK_ID]} | cut -d _ -f 1)

# Make temporary directory
pwd; hostname; date

echo "bwa version: "$(bwa)
echo "Samtools version: "$(samtools --version)

echo "Processing sample: "${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}

# Run bwa
echo $(date +"[%b %d %H:%M:%S] Aligning reads to the genome & outputting sam files")

bwa mem \
-M \
-t ${numThreads} \
-R "@RG\tID:${queries[$SLURM_ARRAY_TASK_ID]}\tLB:IlluminaExome\tPL:ILLUMINA\tSM:${sample}" \
${bwaIndex} \
${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}_1.fastq.gz \
${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}_2.fastq.gz \
> ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sam

# Generate flagstat files from unfiltered sam files
echo $(date +"[%b %d %H:%M:%S] Making flagstat file from sam...")

samtools flagstat \
-@ ${numThreads} \
${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sam \
> ${outDir}/flagstat/${queries[$SLURM_ARRAY_TASK_ID]}_flagstat.txt

# Convert sam files to bam files
echo $(date +"[%b %d %H:%M:%S] Converting sam to bam")

samtools view \
-@ ${numThreads} \
-Sb \
${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sam 
> ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.bam

# Remove intermediate files
rm ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sam

echo $(date +"[%b %d %H:%M:%S] Done")