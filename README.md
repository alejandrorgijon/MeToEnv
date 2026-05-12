# MeToEnv
MeToEnv stands for '<b>Met</b>agenomes <b>To</b> <b>Env</b>ironment', since this pipeline aims to help you explore microbial communities from metagenomic raw data.
This pipeline was develop by [Alejandro Rodríguez-Gijón](https://alejandrorgijon.github.io/) as part of the ARGOS project, a Spanish national research project (PID2023-147830NA-I00) awarded in 2024 to [Rafael Laso-Pérez](https://rafaellasoperez.webnode.es/). ARGOS stands for "<b>A</b>ntimicrobial <b>R</b>esistance by meta<b>G</b>enomics <b>O</b>verview in a <b>S</b>ewage system", and particularly focuses on the extant resistome in the wastewaters of Madrid (Spain).

# Installation

This tool is developed as a conda environment, and must be installed as follows:
```
conda create -n MeToEnv
conda activate MeToEnv
conda install -c conda-forge -c bioconda MeToEnv
```

# MeToARGs: Summary of usage and how to use it

MeToARGs stands for '<b>Met</b>agenomes <b>To</b> <b>A</b>ntibiotic <b>R</b>esistance <b>G</b>enes', since this pipeline aims to provide an assembly and annotation of antibiotic resistance genes (ARGs) from your raw metagenomics reads. This pipeline was develop to be user-friendly at all levels of bioinformatic expertise and leverages already existing tools. As a user, you will only need the following files: 1) a folder where all the paired metagenomic reads can be found, 2) a databaset to detect ARGs, and 3) an output directory. 

```
MeToARGs --reads1 <file> --reads2 <file> --ARGdb <dir> --outdir <dir> [options]

Description:
  Annotates ARGs in raw reads via assembly and gene calling.

Required:
  --reads1  Forward metagenomic reads (.fastq.gz)
  --reads2  Reverse metagenomic reads (.fastq.gz)
  --ARGdb   Directory with the db (.fasta) you want to use for ARG annotation
  --outdir  Output directory

Optional:
  --threads   Number of CPU threads
  --bakta-db  Path to an existing Bakta database directory (it will be downloaded if not provided)
```
For example:
```
MeToARGs --reads1 reads1_trimmed.fastq.gz --reads2 reads2_trimmed.fastq.gz --threads 20  --ARGdb ../CARD_db --outdir sample_out
```

For large projects, I strongly suggest to run this pipeline as an array. This will allow to send multiple jobs, one per paired metagenomic reads. For example I used the [CARD database](https://card.mcmaster.ca/) for ARGs inference as follows:
```
#!/bin/bash

#SBATCH --job-name=MeToARGs_Array
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --mem-per-cpu=100G
#SBATCH --time=7-00:00:00
#SBATCH --array=1-3%2
#SBATCH --output=meto_%A_%a.out
#SBATCH --error=meto_%A_%a.err

#######

module purge
module load cesga/system miniconda3/22.11.1-1
conda activate MeToEnv

cd /directory/where/your/metagenomic/paired/reads/are/located

mkdir -p results
ls *_R1.trimmed.fastq.gz | sed 's/_R1.trimmed.fastq.gz//' > samples.txt
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)

MeToARGs --reads1 "${SAMPLE}_R1.trimmed.fastq.gz" \
         --reads2 "${SAMPLE}_R2.trimmed.fastq.gz" \
         --threads $SLURM_CPUS_PER_TASK \
         --ARGdb ../CARD_db \
         --outdir "./results/" \
         --bakta-db ../db
```

# MeToARGs output


# Citation

You can find all citations in the output file "citations.txt". Please, cite all the tools used in this pipeline, as well as:
