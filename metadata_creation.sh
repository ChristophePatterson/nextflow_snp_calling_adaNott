# srun -t 8:00:00 -c 1 --mem=1G --pty bash

# Load modules
module purge
module load R-uoneasy/4.2.1-foss-2022a
module load bcftools-uoneasy/1.18-GCC-13.2.0

# Move to working directory
cd /gpfs01/home/mbzcp2/code/Github/nextflow_snp_calling_adaNott/

## Get names of smaples that completed the pipeline
# Print out sample names
bcftools query -l output/final_variants.vcf.gz > complete_NF_samps.txt

# Run script for creating metadata
Rscript metadata_creation.R complete_NF_samps.txt seq/fw_seq_data.csv

# Rename output files to set as RepAdaptID
runname="rawg0173_Gasterosteus_aculeatus_Patterson"
outputdir="output/$runname"
mkdir $outputdir

# 1) vcf
cp output/final_variants.vcf.gz $outputdir/$runname.vcf.gz
# 2) Genome seq
gzip -c /gpfs01/home/mbzcp2/data/sticklebacks/genomes/GCF_016920845.1/GCF_016920845.1_GAculeatus_UGA_version5_genomic.fasta > $outputdir/$runname.fasta.gz
# 3) Genome annotation file
gzip -c /gpfs01/home/mbzcp2/data/sticklebacks/genomes/GCF_016920845.1/genomic.gff > $outputdir/$runname.gff.gz
# 4) Genome amino acid seq
cp /gpfs01/home/mbzcp2/data/sticklebacks/genomes/GCF_016920845.1/GCF_016920845.1_GAculeatus_UGA_version5_protein.faa.gz $outputdir/$runname.faa.gz
# 5) Gene depth (orignal)

# 6) Gene depth denovo
cp output/combined_genes.tsv.gz $outputdir/$runname.depth_gene_denovo.gz

# 7) Window depth
cp output/combined_windows.tsv.gz $outputdir/$runname.depth_gene_5Kb.gz

# 8) Whole genome depth
gzip -c output/combined_wg.tsv > $outputdir/$runname.depth_wg.gz
