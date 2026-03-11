#!/bin/bash
# Christophe Patterson
# 20/03/25
# For running on the UoN HPC Ada

#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=40g
#SBATCH --time=100:00:00
#SBATCH --job-name=sequence_data_download
#SBATCH --output=/gpfs01/home/mbzcp2/slurm_outputs/slurm-%x-%j.out

# Code to make sure all reads sequenced are available

# load the Rclone module
module load rclone-uon/1.65.2
# Check rclone remotes
rclone listremotes

# Location of master dataset of all sequences
basedata=/gpfs01/home/mbzcp2/data/bigdata_Christophe_header_2025-04-28.csv

cd ~/gpfs01/home/mbzcp2/code/Github/nextflow_snp_calling_adaNott/seq

# Location of sequence data
output_dir=/gpfs01/home/mbzcp2/data/sticklebacks/seq
# Where sequence data that has been processed in stored
seqdata=$output_dir/seq_data
# Where it will be temporarly downloaded to
rawdownload=$output_dir/raw_download

# Filter out all samples that are not freshwater
awk -F',' 'NR>1 && ($13=="fw" || $13=="st")' $basedata > fw_seq_data.csv
# Create list of all sequence files that would want to be downloaded
awk -F "," '{print $5 "/" $2}' fw_seq_data.csv > seq_list.txt
awk -F "," '{print $5 "/" $3}' fw_seq_data.csv >> seq_list.txt

# Get list of sequence data that is already downloaded
find $seqdata -wholename '*.gz' | awk -F "/" '{print $NF}' | sort > existing_seq_files.txt

# Which files have not been downloaded yet?
awk -F "/" '{print $NF}' seq_list.txt | grep -v -f existing_seq_files.txt seq_list.txt > missing_seq.txt

# Total number of samples files wanted (half the number of seqs)
wc -l seq_list.txt missing_seq.txt | awk '{print $1/2, $2}'

# Get list of files to download for each online repository
# Need to subset to each separate sharepoint site and then remove leading 
grep "sites/MacCollSticklebackLab/Shared Documents/" missing_seq.txt | sed 's|sites/MacCollSticklebackLab/Shared Documents/||g' > MacCollSticklebackLab_seq_files.txt
grep "sites/MacColl_stickleback_lab_2/Shared Documents/" missing_seq.txt | sed 's|sites/MacColl_stickleback_lab_2/Shared Documents/||g' > MacColl_stickleback_lab_2_seq_files.txt

## Number of files to download
echo "Number of files to download from MacCollSticklebackLab:"
wc -l MacCollSticklebackLab_seq_files.txt
echo "Number of files to download from MacColl_stickleback_lab_2:"
wc -l MacColl_stickleback_lab_2_seq_files.txt

rclone --bwlimit 100M --checkers 4 --transfers 4 --onedrive-chunk-size 5M copy \
    --files-from MacCollSticklebackLab_seq_files.txt MacCollSticklebackLab: $rawdownload
echo "completed download for MacCollSticklebackLab"

# From MacColl_stickleback_lab_2
rclone --bwlimit 100M --checkers 4 --transfers 4 --onedrive-chunk-size 5M copy --files-from MacColl_stickleback_lab_2_seq_files.txt MacCollSticklebackLab_2: $rawdownload
echo "completed download for MacColl_stickleback_lab_2"

## Find all downloaded files and transfer to single directory
find $rawdownload -name "*.gz" -exec mv {} $output_dir/seq_data/ \;

## Create link between seq-files in working directory
### ln -s $seqdata/Uist22518_R1.fastq.gz /gpfs01/home/mbzcp2/code/Github/nextflow_snp_calling_adaNott/seq/seq_files/Uist22518_R1.fastq.gz 
### ln -s $seqdata/Uist22518_R2.fastq.gz /gpfs01/home/mbzcp2/code/Github/nextflow_snp_calling_adaNott/seq/seq_files/Uist22518_R2.fastq.gz 
### ln -s $seqdata/Uist22519_R1.fastq.gz /gpfs01/home/mbzcp2/code/Github/nextflow_snp_calling_adaNott/seq/seq_files/Uist22519_R1.fastq.gz 
### ln -s $seqdata/Uist22519_R2.fastq.gz /gpfs01/home/mbzcp2/code/Github/nextflow_snp_calling_adaNott/seq/seq_files/Uist22519_R2.fastq.gz 
### ln -s $seqdata/Uist22520_R1.fastq.gz /gpfs01/home/mbzcp2/code/Github/nextflow_snp_calling_adaNott/seq/seq_files/Uist22520_R1.fastq.gz 
### ln -s $seqdata/Uist22520_R2.fastq.gz /gpfs01/home/mbzcp2/code/Github/nextflow_snp_calling_adaNott/seq/seq_files/Uist22520_R2.fastq.gz 