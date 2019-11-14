#!/bin/bash

## Script for running bwa
## Date: 17 September 2019 

## Example usage:
## cd /Users/coke6162/repos/scripts/cutnrun-analysis
## inDir=/Users/coke6162/project20xx_cutnrun/bbduk \
## outDir=/Users/coke6162/project20xx_cutnrun/bwa \
## bwaIndexDir=/Shares/CL_Shared/db/genomes/bosTau9/index/bwa \
## bwaIndex=bosTau9.main.fa \
## genomeChrFile=/Shares/CL_Shared/db/genomes/bosTau9/fa/bosTau9.main.chrom.sizes \
## sbatch --array 0-5 bwa_PE.sbatch

## bwaIndexDir options: hg38, mm10, bosTau8, bosTau9, canFam3
## bwaIndex options: hg38.main.fa, mm10.fa, bosTau8.fa, bosTau9.main.fa, canFam3.fa 

## General settings
#SBATCH -p short
#SBATCH -N 1
#SBATCH -n 8
#SBATCH --time=8:00:00
#SBATCH --mem=32GB

# Job name and output
#SBATCH -J bwa
#SBATCH -o /Users/%u/sbatch_script/output/slurm-%A_%a.out
#SBATCH -e /Users/%u/sbatch_script/error/slurm-%A_%a.err

# Email notifications 
#SBATCH --mail-type=END                                         
#SBATCH --mail-type=FAIL                                        
#SBATCH --mail-user=coke6162@colorado.edu

# Set constant variables
numThreads=8
nonChrM=$(cat ${genomeChrFile} | awk '{print $1}' | grep -v chrM | tr '\n' ' ')

# Load modules
module load bwa
module load samtools
module load bedtools

# Define query files
queries=($(ls ${inDir}/*fastq.gz | xargs -n 1 basename | sed --expression='s/_R1_paired.fastq.gz//g' | sed --expression='s/_R2_paired.fastq.gz//g' | uniq))

# Run bwa
pwd; hostname; date

echo "Aligning reads to the genome & outputting sam files"
echo "bwa version: "$(bwa)
echo "Samtools version: "$(samtools --version)
echo "Bedtools version: "$(bedtools --version)

echo "Processing file: "${queries[$SLURM_ARRAY_TASK_ID]}

bwa mem \
-t ${numThreads} \
${bwaIndexDir}/${bwaIndex} \
${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}_R1_paired.fastq.gz \
${inDir}/${queries[$SLURM_ARRAY_TASK_ID]}_R2_paired.fastq.gz \
> ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sam

# Convert sam files to bam files, filtering out low quality (<10) and unmapped (through '-F 4' option)
echo $(date +"[%b %d %H:%M:%S] Converting sam to unfiltered bam & sorting")

samtools view \
-@ ${numThreads} \
-Sb \
-q 10 \
-F 4 \
${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sam \
| samtools sort \
-@ ${numThreads} \
- \
> ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sorted.bam

# Generate flagstat files from unfiltered, sorted bam files
echo $(date +"[%b %d %H:%M:%S] Making flagstat file from unfiltered bam...")

samtools flagstat \
-@ ${numThreads} \
${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sorted.bam \
> ${outDir}/flagstat/${queries[$SLURM_ARRAY_TASK_ID]}_flagstat.txt

# Index unfiltered sorted bam files
echo $(date +"[%b %d %H:%M:%S] Indexing unfiltered, sorted bams...")

samtools index \
${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sorted.bam \
> ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sorted.bam.bai

# Filter out chrM reads & sort
echo $(date +"[%b %d %H:%M:%S] Removing chrM reads and sorting...")

samtools view \
-b ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sorted.bam \
${nonChrM} \
| samtools sort \
-@ ${numThreads} \
- \
> ${outDir}/filtered/${queries[$SLURM_ARRAY_TASK_ID]}_filtered.sorted.bam

# Index filtered sorted bam files
echo $(date +"[%b %d %H:%M:%S] Indexing filtered, sorted bams...")

samtools index \
${outDir}/filtered/${queries[$SLURM_ARRAY_TASK_ID]}_filtered.sorted.bam \
> ${outDir}/filtered/${queries[$SLURM_ARRAY_TASK_ID]}_filtered.sorted.bam.bai

# Generate flagstat files from unfiltered, sorted bam files
echo $(date +"[%b %d %H:%M:%S] Making flagstat file from filtered bam...")

samtools flagstat \
-@ ${numThreads} \
${outDir}/filtered/${queries[$SLURM_ARRAY_TASK_ID]}_filtered.sorted.bam \
> ${outDir}/filtered/flagstat/${queries[$SLURM_ARRAY_TASK_ID]}_filtered_flagstat.txt

# Convert to BEDPE & filter out fragments greater than 1kb
echo $(date +"[%b %d %H:%M:%S] Converting filtered bam to BEDPE...")

samtools sort \
-@ ${numThreads} \
-n ${outDir}/filtered/${queries[$SLURM_ARRAY_TASK_ID]}_filtered.sorted.bam \
| samtools fixmate -@ ${numThreads} - - \
| bamToBed -bedpe -i - \
| awk '$1==$4 && $6-$2 < 1000 {print $0}' - \
> ${outDir}/filtered/${queries[$SLURM_ARRAY_TASK_ID]}_filtered_d1000.sorted.bed

# Select the 5' and 3' coordinates of the read pair to generate a new BED3 file
echo $(date +"[%b %d %H:%M:%S] Extract read pair coordinates to generate BED3...")

cut -f 1,2,6 \
${outDir}/filtered/${queries[$SLURM_ARRAY_TASK_ID]}_filtered_d1000.sorted.bed \
> ${outDir}/filtered/${queries[$SLURM_ARRAY_TASK_ID]}_filtered_d1000_fragments.sorted.bed

# Convert the BED3 files into bedgraphs
echo $(date +"[%b %d %H:%M:%S] Generating bedgraph files...")

sort -k1,1 ${outDir}/filtered/${queries[$SLURM_ARRAY_TASK_ID]}_filtered_d1000_fragments.sorted.bed \
| bedtools genomecov \
-bg \
-i - \
-g ${genomeChrFile} \
> ${outDir}/filtered/${queries[$SLURM_ARRAY_TASK_ID]}_filtered_d1000_fragments.bdg

# Determine percentage of total reads that mapped to mitochondrial genes
echo $(date +"[%b %d %H:%M:%S] Calculating percentage of total reads mapping to mitochondrial genes")

chrMreads=`samtools view -c ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sam chrM`
totalReads=`samtools view -c ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sam`
fractionMreads=`echo "100 * ${chrMreads} / ${totalReads}" | bc -l`
touch ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}_chrMreadsFraction.txt
echo ${queries[$SLURM_ARRAY_TASK_ID]} >> ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}_chrMreadsFraction.txt
echo ${totalReads} 'total mapped reads' >> ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}_chrMreadsFraction.txt
echo ${chrMreads} 'mitochondrial reads' >> ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}_chrMreadsFraction.txt
echo ${fractionMreads} 'percentage of mitochondrial reads from total mapped reads' >> ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}_chrMreadsFraction.txt

# Remove intermediate files
rm ${outDir}/${queries[$SLURM_ARRAY_TASK_ID]}.sam

echo $(date +"[%b %d %H:%M:%S] Done")

### Explanation of bwa options
### '-t <int' - specifies number of threads to use

### Explanation of samtools options
### '-@ <int>' - number of threads
### '-Sb' - convert sam to bam
### '-q <int>' - quality threshold (filter out reads with quality below int)
### '-F 4' - exclude unmapped reads
### '-c' - print only the count of matching records