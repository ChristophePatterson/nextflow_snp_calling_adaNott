#!/bin/bash
# Christophe Patterson
# 20/03/25
# For running on the UoN HPC Ada

#SBATCH --partition=defq
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8g
#SBATCH --time=6-23:00:00
#SBATCH --job-name=next-flow-RepAdapt
#SBATCH --output=/gpfs01/home/mbzcp2/slurm_outputs/slurm-%x-%j.out

## Must be run will the working directory is /gpfs01/home/mbzcp2/code/Github/nextflow_snp_calling_adaNott/ or equivalent on your system

module purge
module load nextflow-uoneasy/25.04.6
module load singularity/3.8.5

export NXF_SINGULARITY_CACHEDIR=/gpfs01/home/$USER/NXF_SINGULARITY_CACHEDIR

nextflow run main.nf \
    --ref_genome=/gpfs01/home/mbzcp2/data/sticklebacks/genomes/GCF_016920845.1/GCF_016920845.1_GAculeatus_UGA_version5_genomic.fasta \
    --gff_file=/gpfs01/home/mbzcp2/data/sticklebacks/genomes/GCF_016920845.1/genomic.gff \
    --reads "./seq/seq_files/*{R1,R2}.fastq.gz" \
    --outdir ./output/ \
    -profile ada -config nextflow.config -w ./work/
