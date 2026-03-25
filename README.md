# nextflow_snp_calling_computecanada
Nextflow pipeline for Ada HPC at the university of Nottingham
Altered by Christophe Patterson from the Narval/Beluga Compute Canada HPC with SLURM

This pipeline takes paired-end fastq reads, a reference genome and a gff file and will produce:
- a minimally filtered vcf (removing SNPs where all indidivuals are homozyogous ALT and any SNP with MQ < 30).
- 3 depth statistics files per dataset: samples genes depth, samples windows depth and samples whole-genome depth.

Login to Ada.
From a login node in your home dir run:

<pre>module purge # Make sure that previously loaded modules are not polluting the installation
# Load nextflow via university preinstalled modules
module load nextflow-uoneasy/25.04.6
# Check python version
python3 -V
# Load singularity
module load singularity/3.8.5
</pre>


Now, create or edit the file (you probably have to create it):  ~/.nextflow/config   

This is like a general config for EVERY workflow you will run with nextflow in this cluster. You can copy and paste the text below into it, but change def-group to your compute canada account name:



<pre>params {
    config_profile_description = 'Ada HPC config'
    config_profile_contact = 'https://uniofnottm.sharepoint.com/sites/DigitalResearch/SitePages/Ada-Compute-software.aspx'
    config_profile_url = ''
}


singularity {
  enabled = true
  autoMounts = true
}

apptainer {
  autoMounts = true
}

process {
  executor = 'slurm'
  clusterOptions = '--account=mbzcp2 --partition=defq'
  maxRetries = 1
  errorStrategy = { task.exitStatus in [125,139] ? 'retry' : 'finish' }
  memory = '4GB'
  cpu = 1
  time = '1h'
}

executor {
  pollInterval = '60 sec'
  submitRateLimit = '60/1min'
  queueSize = 900
}

profiles {
  ada {
    max_memory='361G'
    max_cpu=40
    max_time='168h'
  }
  
}
</pre>

Do not worry about the cpus, memory and time of the slurm process. These slurm global options will be overwritten by the cpus, memory and time specified for each process of the workflow defined in modules. 

I, Christophe, have changed the profiles to have one that matches ada's.

Now, download all the singularity (load using `module load singularity/3.8.5` ) images needed: https://github.com/RepAdapt/singularity/blob/main/RepAdapt.singularity.genotyping.setup.md

Create this directory and place them here ():
<pre>
cd ~
mkdir /gpfs01/home/$USER/NXF_SINGULARITY_CACHEDIR

singularity pull fastp_0.20.1.sif https://depot.galaxyproject.org/singularity/fastp:0.20.1--h8b12597_0 
singularity pull bwa_0.7.17.sif https://depot.galaxyproject.org/singularity/bwa:0.7.17--h5bf99c6_8 
singularity pull samtools_1.16.1.sif https://depot.galaxyproject.org/singularity/samtools:1.16.1--h6899075_0 
singularity pull gatk_4.4.1.sif https://depot.galaxyproject.org/singularity/gatk4:4.1.0.0--0
singularity pull picard_2.26.3.sif https://depot.galaxyproject.org/singularity/picard:2.26.3--hdfd78af_0 
singularity pull bedtools_2.27.1.sif https://depot.galaxyproject.org/singularity/bedtools:2.27.1--0 
singularity pull gatk_3.8.9.sif https://depot.galaxyproject.org/singularity/gatk:3.8--9 
singularity pull bcftools_1.16.sif https://depot.galaxyproject.org/singularity/bcftools:1.16--hfe4b78e_1
singularity pull vcftools_1.16.sif https://depot.galaxyproject.org/singularity/vcftools:0.1.16--pl5321hdcf5f25_9  

mv *.sif /gpfs01/home/$USER/NXF_SINGULARITY_CACHEDIR
</pre>
then:
<pre>export NXF_SINGULARITY_CACHEDIR=/gpfs01/home/$USER/NXF_SINGULARITY_CACHEDIR</pre>

Also add the above export command to your ~/.bashrc


Now we have everything ready to start the workflow.

The workflow should be run on a computing node, using the script <b>run_pipeline.sh</b> (submit with sbatch -- give this job only 1 cpu, 8 GB RAM but MAX available run time which is 7 days in ada, although you tend to get better allocation on the slurm queue if you're slightly under the maximun e.g 6-23:00:00). 

Change the profile flag in run_pipeline.sh to either beluga or narval (depending on which one you are using).

# Options

--reads (default CWD: "./*{1,2}.fastq.gz") ### this can be changed, use it to match your raw fastq reads path and names patterns (ie. fq.gz)

--outdir (default: "./output/") ### this can be changed to any directory

The ref genome must have the extension '.fasta', to avoid duplicating file create a symbolic link `ln path/to/ref_genome.fna path/to/ref_genome.fasta`
--ref_genome (No default, give full path)

--gff_file (No default, give full path)


# Important

It is required to pull all the singularity/apptainer images as sif files and link them to the directory where you saved  them (/project/def-group/NXF_SINGULARITY_CACHEDIR) in the config file nextflow.config

Singularity/Apptainer images vailable at: https://github.com/RepAdapt/singularity/blob/main/RepAdaptSingularity.imagelocations.md


<b>THIS PIPELINE ASSUMES THAT EACH SAMPLE HAS A SINGLE PAIR OF PAIRED END READS.</b>






# Comments

- **Reference too fragmented -- stitching the reference genome:**  
  If a reference genome is highly fragmented, consisting of thousands or even millions of scaffolds, it is beneficial to stitch them into larger contiguous sequences before running the SNP calling pipeline to reduce the total number of scaffolds.  
  Having a reference composed of too many scaffolds will cause errors in the indel realignment step with GATK3 – I am not sure which threshold is “too many". This issue mite actually be caused by having very short scaffolds rather than the number of scaffolds.  
  Additionally, the pipeline parallelizes the SNP calling step (`bcftools mpileup + call`) by chromosome (calling SNPs in each chromosome in parallel), therefore having a very fragmented reference would result in sending thousands (or millions) of very fast jobs – it would still work but it would be an overkill and probably not ideal for queue times on a job scheduler.  
  So, if your reference is too fragmented, please stitch it and unstitch it after SNP calling!  

- **Reference must have `.fasta` suffix while genes GFF must have `.gff` suffix.**  

- **Make sure that the `.gff` file and reference genome use the same exact chromosome names.**  
  If this is not the case the depth of coverage statistics will not be calculated. The names need to be exactly the same, so if, for example, the reference has `chromosome_1` and the GFF has `chr_1`, these will have to be changed to the same naming.  

- **Make sure the chromosome/scaffold names do not contain weird characters that may break commands.**  
  A very unusual case that I found was a reference that had `|` pipes included in the chromosome names – this can cause a lot of issues, as the pipe `|` may be interpreted as a Linux pipe command.  

- **If a process fails, the first thing to check is whether it was due to low run time or RAM.**  
  RAM and run time can be easily edited for each process by modifying its corresponding script in the `modules` directory. I tried to provide high enough values that will work for most datasets, but if your dataset is particularly large (in terms of reference size or raw FASTQ files size per sample), it might be necessary to increase RAM and run time for some processes in the modules directory. If the pipeline fails due to a process RAM or run time, it can be resumed from where it failed relaunching the pipeline by adding the flag -resume (after editing RAM/run time)


- **The bwa-mem step of the pipeline will produced samples SAMs simultaneously, which can result in storage issues for some users.**  
If this is the case for you, you can limit the number of bwa-mem mapping processes occurring at the same time by adding the maxForks option within the bwa_mapping.nf script in the modules directory.
This needs to be added at the top of the script, for example:

<pre> process bwaMap {
    maxForks = 10
    tag "BWA-mem mapping"
    cpus 4
    memory '4GB'
    time '12h'
    errorStrategy 'ignore'
   
    input:
    path reference
    file "${reference.baseName}.fasta.amb"
    file "${reference.baseName}.fasta.ann"
    file "${reference.baseName}.fasta.bwt"
    file "${reference.baseName}.fasta.pac"
    file "${reference.baseName}.fasta.sa"
    tuple val(sample_id), path(trimmed_reads)

    output:
    path "${sample_id}.sam"

    script:
    """
    bwa mem -t $task.cpus $reference ${trimmed_reads[0]} ${trimmed_reads[1]} > ${sample_id}.sam
    """
}</pre>

The above will force the pipeline to run a maximum of 10 mapping proccesses at the same time. This way, it will be possible to mitigate the accumulation of too many SAMs at the same time. SAMs are converted to BAMs and deleted in the following step. Adjust the number of forks as required.
