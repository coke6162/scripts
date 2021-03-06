#!/bin/bash

## Script for running MELT Genotype (Step 4)
## Date: 14 February 2020 

## Example usage:
## cd /Users/coke6162/repos/scripts/wgs-analysis
## parentDir=/scratch/Users/coke6162 \
## projectName=20200204_wgs_bosTau9_USMARC_BL3_hybrid \
## zipDir=/Shares/CL_Shared/db/genomes/bosTau9/1000_Bull_Genomes_Project/repeats/MELT \
## bamFile=Limousin2_merged_marked_realigned_recalibrated.sorted.bam \
## fastaFile=/Shares/CL_Shared/db/genomes/bosTau9/1000_Bull_Genomes_Project/fa/ARS-UCD1.2_Btau5.0.1Y.main.fa \
## meiList=/Users/coke6162/repos/project_files/20200102_DNA-seq_bosTau9_USMARC/mei_list.txt \
## sbatch --array 0-5 MELT_4_Genotype.sbatch

## General settings
#SBATCH -p long
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --time=7-0:00:00
#SBATCH --mem=64GB

# Job name and output
#SBATCH -J Genotype
#SBATCH -o /Users/%u/sbatch_script/output/slurm-%A_%a.out
#SBATCH -e /Users/%u/sbatch_script/error/slurm-%A_%a.err

# Email notifications 
#SBATCH --mail-type=END                                         
#SBATCH --mail-type=FAIL                                        
#SBATCH --mail-user=coke6162@colorado.edu

# Set constant variables
numThreads=1

# Load modules
module load bowtie
module load samtools

# Define path variables
inDir=${parentDir}/${projectName}/melt
outDir=${parentDir}/${projectName}/melt
tmpDir=${parentDir}/${projectName}/java_tmp/${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}

# Define query files
queries=($(cat ${meiList} | xargs -n 1 basename | sed 's/_MELT.zip//g'))

# Make directories
pwd; hostname; date

echo "Making temporary directory..."

mkdir -p ${tmpDir}

# Run MELT
echo $(date +"[%b %d %H:%M:%S] Running MELT Genotype...")

java \
-Xmx64G \
-Djava.io.tmpdir=${tmpDir} \
-XX:ParallelGCThreads=${numThreads} \
-jar /Shares/CL_Shared/programs/MELTv2.1.5/MELT.jar \
Genotype \
-bamfile ${inDir}/${bamFile} \
-p ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]} \
-w ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]} \
-t ${zipDir}/${queries[$SLURM_ARRAY_TASK_ID]}_MELT.zip  \
-h ${fastaFile}

echo $(date +"[%b %d %H:%M:%S] Done")
