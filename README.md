# MeToEnv
MeToEnv stands for '<b>Met</b>agenomes <b>To</b> <b>Env</b>ironment', since this tool is a compilation of pipelines that aim to help you exploring microbial communities from metagenomic raw data. This tool was developed by [Alejandro Rodríguez-Gijón](https://alejandrorgijon.github.io/) as part of the ARGOS project, a Spanish national research project (PID2023-147830NA-I00) awarded in 2024 to [Rafael Laso-Pérez](https://rafaellasoperez.webnode.es/). 
ARGOS stands for "<b>A</b>ntimicrobial <b>R</b>esistance by meta<b>G</b>enomics <b>O</b>verview in a <b>S</b>ewage system", and particularly focuses on the extant resistome in the wastewaters of Madrid (Spain).

So far the environment has the following pipelines, which are detailed below:
-  MeToARGs: Pipeline to annotate antibiotic resistance genes (ARGs) from raw metagenomic reads via assembly.
-  MeToGeneAbu: Pipeline to predict gene abundance from raw metagenomic reads and assemblies.

Other important contributors: [Lucía Muñoz](https://github.com/Lucia-Munoz)
# Installation

This tool is developed as a conda environment, and must be installed as follows:
```
git clone https://github.com/alejandrorgijon/MeToEnv.git
cd MeToEnv
mamba env create -f MeToEnv.yml 
conda activate MeToEnv
```
After installation of the environment, make the different pipelines executable by:
```
chmod +x path/to/your/directory/MeToEnv/scripts/MeToARGs
```

# MeToARGs
MeToARGs stands for '<b>Me</b>tagenomes <b>To</b> <b>A</b>ntibiotic <b>R</b>esistance <b>G</b>ene<b>s</b>', since this pipeline aims to provide an assembly and annotation of ARGs from raw metagenomics reads. This pipeline was develop to be user-friendly at all levels of bioinformatic expertise and leverages already existing tools. As a user, you will only need the following files: 1) a folder where all the paired metagenomic reads can be found, 2) the MeToEnv environment pre-installed, and 3) an output directory.
```
  MeToARGs --reads1 <file> --reads2 <file> --outdir <dir> [options]

Description:
  Annotates ARGs in raw reads via assembly and gene calling.

Required:
  --reads1      Forward metagenomic reads (.fastq.gz)
  --reads2      Reverse metagenomic reads (.fastq.gz)
  --outdir      Output directory

Optional:
  --threads     Number of CPU threads (default: 1)
  --min-length  Minimum contig length to annotate in bp (default: 1000)
  --aligner     Tool used during RGI alignment: DIAMOND or BLAST (default: DIAMOND)
```
For example:
```
MeToARGs --reads1 reads1_trimmed.fq.gz --reads2 reads2_trimmed.fq.gz --threads 20 --outdir sample_out
```

For projects with a large number of samples, I strongly suggest to run this pipeline as an array. This will allow to send multiple jobs, one per paired metagenomic reads. For example:
```
#!/bin/bash

#SBATCH --job-name=MeToARGs_Array
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --mem-per-cpu=10G
#SBATCH --time=7-00:00:00
#SBATCH --array=1-7%7
#SBATCH --output=MeToARGs_%A_%a.out
#SBATCH --error=MeToARGs_%A_%a.err

#######

module purge
module load cesga/system miniconda3/22.11.1-1
conda activate MeToEnv

cd /directory/where/your/metagenomic/paired/reads/are/located

mkdir -p results
ls *_1.fq.gz | sed 's/_1.fq.gz//' > samples.txt
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)

MeToARGs --reads1 "${SAMPLE}_1.fq.gz" \
         --reads2 "${SAMPLE}_2.fq.gz" \
         --threads $SLURM_CPUS_PER_TASK \
         --outdir "/mnt/netapp1/Store_argos/05_MeToARGs/H2/"
```
# MeToGeneAbu
MeToGeneAbu stands for '<b>Me</b>tagenomes <b>To</b> <b>Gene</b> <b>Abu</b>ndance', since this pipeline aims to provide abundance metrics (RPKM & RPM by default) for all the predicted genes by MeToARGs, using the software CoverM. This pipeline was develop to be user-friendly at all levels of bioinformatic expertise and leverages already existing tools. As a user, you will only need the following files: 1) the MeToEnv environment pre-installed, 2)a folder where all the paired metagenomic reads can be found a and 3) a folder were all predicted genes can be found 4) an output directory.

Please note that this function returns abundance values for all the predicted genes, in case you want to filter out only the resistance genes, further parsing is needed. We recommed the R script 'parse_rgi_coverm.R', that can be found in the scripts folder of this github

```
MeToGeneAbu --reads1 <file> --reads2 <file> --scaffolds <file> --genes <file> --outdir <dir> [options]

Description:
  Calculates the abundance (RPKM and TPM) of all predicted genes using CoverM.
  Required:
            --reads1      Forward metagenomic reads (.fq.gz)
            --reads2      Reverse metagenomic reads (.fq.gz)
            --scaffolds   Filtered scaffolds (_min1000bp_scaffolds.fasta)
            --genes       Gene calling FASTA (_min1000bp_scaffolds.fasta.temp.contig.fsa)
            --outdir      Output directory

  Optional (change these as you see fit):
            --threads     Number of CPU threads (default: 1)
            --methods     CoverM methods, between quotes (default: rpkm, tpm)
            --contig-end-exclusion  Bases excluded at contig ends (default: 0)
```
For example:
```
MeToGeneAbu --reads1 SAMPLE_R1_trimmed.fq.gz --reads2 SAMPLE_R2_trimmed.fq.gz --scaffolds SAMPLE_min1000bp_scaffolds.fasta --genes SAMPLE_min1000bp_scaffolds.fasta.temp.contig.fsa --outdir sample_out
```
For projects with a large number of samples, I strongly suggest to run this pipeline as an array. This will allow to send multiple jobs, one per paired metagenomic reads. For example:
