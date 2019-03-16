#!/bin/bash

## Script for running multiqc
## Date: 31 Jan 2019 

## Example usage:
## inDir=/Users/%u/project20xx_rnaseq/fastqc \
## outDir=/Users/%u/project20xx_rnaseq/fastqc/multiqc \
## sbatch multiqc.sbatch

# General settings
#SBATCH -p short
#SBATCH -N 1
#SBATCH -n 8
#SBATCH --time=0:30:00
#SBATCH --mem=4GB

# Job name and output
#SBATCH -J multiqc
#SBATCH -o /Users/%u/sbatch_script/output/slurm-%j.out
#SBATCH -e /Users/%u/sbatch_script/error/slurm-%j.err

# Email notifications 
#SBATCH --mail-type=END                                         
#SBATCH --mail-type=FAIL                                        
#SBATCH --mail-user=%u@colorado.edu

# Load FastQC
module load multiqc

# Run MultiQC
pwd; hostname; date

echo "Running MultiQC..."
echo "MultiQC version: "(multiqc --version)

multiqc ${inDir}/*.zip --outdir ${outDir}

echo $(date +"[%b %d %H:%M:%S] Done")
