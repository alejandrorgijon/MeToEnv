# MeToEnv
MeToEnv stands for '<b>Met</b>agenomes <b>To</b> <b>Env</b>ironment', since this pipeline aims to help you study microbial communities from metagenomic data.
This pipeline was develop by [Alejandro Rodríguez-Gijón](https://alejandrorgijon.github.io/) as part of the ARGOS project, which stands for "<b>A</b>ntimicrobial <b>R</b>esistance by meta<b>G</b>enomics <b>O</b>verview in a <b>S</b>ewage system". It is a Spanish national research project (PID2023-147830NA-I00) awarded in 2024 to [Rafael Laso-Pérez](https://rafaellasoperez.webnode.es/).

# Installation

```
conda create -n MeToEnv
conda activate MeToEnv
conda install -c conda-forge -c bioconda MeToEnv
```

# MeToARGs: Summary of usage

This pipeline was develop to be user-friendly at all levels of bioinformatic expertise. It aims to provide an assembly and annotation of antibiotic resistance genes (ARGs) by leveraging already existing tools. As a user, you will only need the following files: a folder where all the paired metagenomic reads can be found, and the MeToMAGs.sh pipeline file downloaded in that same folder. 

Once you have your MeToEnv environment installed and fully working, we can start using it! For example, a correct way to set up the conditions to use the MeToMAGs pipeline:

I strongly suggest to run this pipeline as an array. This will allow to send multiple jobs, one per paired metagenomic reads. Example of array job:
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
