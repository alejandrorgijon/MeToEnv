# MeToEnv
MeToEnv stands for '<b>Met</b>agenomes <b>To</b> <b>Env</b>ironment', since this pipeline aims to help you explore microbial communities from metagenomic raw data.
This pipeline was developed by [Alejandro Rodríguez-Gijón](https://alejandrorgijon.github.io/) as part of the ARGOS project, a Spanish national research project (PID2023-147830NA-I00) awarded in 2024 to [Rafael Laso-Pérez](https://rafaellasoperez.webnode.es/). ARGOS stands for "<b>A</b>ntimicrobial <b>R</b>esistance by meta<b>G</b>enomics <b>O</b>verview in a <b>S</b>ewage system", and particularly focuses on the extant resistome in the wastewaters of Madrid (Spain).

So far the environment has the following commands:
-  MeToARGs: Pipeline to annotate antibiotic resistance genes (ARGs) from raw metagenomics reads via assembly.
-  MeToParse: Pipeline to parse the results obtained from MeToARGs based on alignment and coverage statistics.

# Installation

This tool is developed as a conda environment, and must be installed as follows:
```
git clone https://github.com/alejandrorgijon/MeToEnv.git
cd MeToEnv
mamba env create -f MeToEnv.yml 
conda activate MeToEnv
```

# MeToARGs

MeToARGs stands for '<b>Met</b>agenomes <b>To</b> <b>A</b>ntibiotic <b>R</b>esistance <b>G</b>enes', since this pipeline aims to provide an assembly and annotation of ARGs from raw metagenomics reads. This pipeline was develop to be user-friendly at all levels of bioinformatic expertise and leverages already existing tools. As a user, you will only need the following files: 1) a folder where all the paired metagenomic reads can be found, 2) the MeToEnv environment pre-installed, and 3) an output directory. 

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

For large projects, I strongly suggest to run this pipeline as an array. This will allow to send multiple jobs, one per paired metagenomic reads. For example:
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
ls *_R1.trimmed.fastq.gz | sed 's/_R1.trimmed.fastq.gz//' > samples.txt
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" samples.txt)

MeToARGs --reads1 "${SAMPLE}_1.fq.gz" \
         --reads2 "${SAMPLE}_2.fq.gz" \
         --threads $SLURM_CPUS_PER_TASK \
         --outdir "/mnt/netapp1/Store_argos/05_MeToARGs/H2/"
```
