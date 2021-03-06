#!/usr/bin/env Rscript

# R script to make boxplot of obs vs exp overlap from giggle output
# Example usage:
# cd /Users/coke6162/repos/scripts/atacseq-analysis
# Rscript --vanilla obs_vs_exp_boxplot.R \
# /Users/coke6162/20190429_ATAC-seq_MDBK/giggle/DE/allRep/MDBK_4h_R1_DE_summits.giggleStats.sorted \
# /Users/coke6162/repos/scripts/atacseq-analysis/obs_vs_exp_repNames.txt \
# /Users/coke6162/figures/MDBK_4h_R1_DE_summits_SINE_obs_vs_exp_boxplot.png

args = commandArgs(trailingOnly=TRUE)
# args[1] = input table
# args[2] = file containing names of repeats of interest (listed in a single column)
# args[3] = output file name

# Load required packages
library(ggplot2)
library(reshape2)
library(ggpubr)

# Read in table
data <- read.table(args[1], 
                   header = FALSE, 
                   sep = "\t") %>% 
  transform(exp = V3 / V4) %>% .[,c(1,2,3,10,4,5,6,7,8)]
colnames(data) <- c("name", "size", "obs", "exp", "odds_ratio", "fishers_two_tail", "fishers_left_tail", "fishers_right_tail", "combo_score")
data

# Subset for repeats you want to plot
names <- read.table(args[2])
names <- as.character(unlist(names[1, ]))
names
dataSubset <- subset(data, 
                     data$name %in% names)
dataSubset

# Transform into long format
dataSubset <- melt(dataSubset, 
                   id.vars = "name", 
                   measure.vars = c("obs", "exp"))
dataSubset

# Plot
pdf(file = args[3], width = 12, height = 6, units = 'in', res = 300)

ggplot(dataSubset) + 
  geom_col(aes(x = name, 
               y = value, 
               fill = variable), 
           position = "dodge2") + 
  scale_fill_manual(name = NULL, 
                    labels = c("Observed", "Expected"),
                    values = c("#56B4E9", 
                               "#999999")) +
  xlab("Repeat") +
  ylab("Number of overlaps with IFNG-inducible ATAC peaks")

dev.off()
q(save = "yes")