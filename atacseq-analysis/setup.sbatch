#!/bin/bash

## Script to set up directory layout 
## Date: 30 April 2019

## Example usage:
## parentDir=/Users/coke6162 projectName=project20xx_atacseq sbatch setup.sbatch

# General settings
#SBATCH -p short
#SBATCH -N 1
#SBATCH -c 1
#SBATCH --time=1:00:00
#SBATCH --mem=1GB

# Job name and output
#SBATCH -J setup
#SBATCH -o /Users/%u/sbatch_script/output/slurm-%j.out
#SBATCH -e /Users/%u/sbatch_script/error/slurm-%j.err

# Email notifications 
#SBATCH --mail-type=END                                         
#SBATCH --mail-type=FAIL                                        
#SBATCH --mail-user=coke6162@colorado.edu

# run the thing
pwd; hostname; date

echo "Working dir: "${parentDir}
echo "Project: "${projectName}
echo $(date +"[%b %d %H:%M:%S] Making project directories...")

# go to the designated work dir
cd ${parentDir}

# make a new project dir
mkdir -p ${projectName}

# make necessary subdirs
mkdir -p ${projectName}/fastq
mkdir -p ${projectName}/fastq/fastqc
mkdir -p ${projectName}/fastq/fastqc/multiqc
mkdir -p ${projectName}/bbduk
mkdir -p ${projectName}/bbduk/fastqc
mkdir -p ${projectName}/bbduk/fastqc/multiqc
mkdir -p ${projectName}/bowtie2
mkdir -p ${projectName}/bigwigs
mkdir -p ${projectName}/macs2
mkdir -p ${projectName}/giggle

echo $(date +"[%b %d %H:%M:%S] Done")