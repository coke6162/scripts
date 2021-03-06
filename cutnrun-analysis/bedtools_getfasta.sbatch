#!/bin/bash

## Script for running bedtools getfasta
## Date: 18 November 2019

## Example usage:
## cd /Users/coke6162/repos/scripts/cutnrun-analysis
## inDir=/Users/coke6162/20191111_CUTnRUN_MDCK/seacr/stringent/slopSummits/b75 \
## outDir=/Users/coke6162/20191111_CUTnRUN_MDCK/seacr/stringent/slopSummits/b75/fa \
## genomeFaFile=/Shares/CL_Shared/db/genomes/canFam3/fa/canFam3.main.fa \
## sbatch --array=0-38 bedtools_getfasta.sbatch

## General settings
#SBATCH -p short
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --time=12:00:00
#SBATCH --mem=8G

# Job name and output
#SBATCH -J bedtools_getfasta
#SBATCH -o /Users/%u/sbatch_script/output/slurm-%A_%a.out
#SBATCH -e /Users/%u/sbatch_script/error/slurm-%A_%a.err

# Email notifications
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=coke6162@colorado.edu

# Define query files
queries=($(ls ${inDir}/*.bed | xargs -n 1 basename | sed --expression='s/.bed//g' | uniq))

# load modules
module load bedtools

# make output directory
pwd; hostname; date

echo "Making output directory..."

mkdir -p ${outDir}

# run the thing
echo "Starting bedtools getfasta..."
echo "Bedtools version: "$(bedtools --version)

echo "Processing file: "${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}.bed

bedtools getfasta \
-fi ${genomeFaFile} \
-bed ${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}.bed \
-fo ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.fa

echo $(date +"[%b %d %H:%M:%S] Done")