# MeToEnv
MeToEnv stands for '<b>Met</b>agenomes <b>To</b> <b>Env</b>ironment', since this pipeline aims to help you explore microbial communities from metagenomic raw data.
This pipeline was developed by [Alejandro Rodríguez-Gijón](https://alejandrorgijon.github.io/) as part of the ARGOS project, a Spanish national research project (PID2023-147830NA-I00) awarded in 2024 to [Rafael Laso-Pérez](https://rafaellasoperez.webnode.es/). ARGOS stands for "<b>A</b>ntimicrobial <b>R</b>esistance by meta<b>G</b>enomics <b>O</b>verview in a <b>S</b>ewage system", and particularly focuses on the extant resistome in the wastewaters of Madrid (Spain).

So far the environment has the following commands:
-  MeToARGs: Pipeline to annotate antibiotic resistance genes (ARGs) from raw metagenomics reads via assembly.
-  MeToParse: Pipeline to parse the results obtained from MeToARGs based on alignment and coverage statistics.

# Installation

This tool is developed as a conda environment, and must be installed as follows:
```
wget https://github.com/alejandrorgijon/MeToEnv/blob/main/MeToEnv.yml
conda env create -f MeToEnv.yml
conda activate MeToEnv
```

# MeToARGs

MeToARGs stands for '<b>Met</b>agenomes <b>To</b> <b>A</b>ntibiotic <b>R</b>esistance <b>G</b>enes', since this pipeline aims to provide an assembly and annotation of ARGs from raw metagenomics reads. This pipeline was develop to be user-friendly at all levels of bioinformatic expertise and leverages already existing tools. As a user, you will only need the following files: 1) a folder where all the paired metagenomic reads can be found, 2) a databaset to detect ARGs, and 3) an output directory. 

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
  --threads      Number of CPU threads
  --min-length   Minimum contig length to annotate (default: 1500 bp)
  --prokka-db    Path to an existing Prokka database directory (it will be downloaded if not provided)
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
#SBATCH --mem-per-cpu=10G
#SBATCH --time=7-00:00:00
#SBATCH --array=1-7%7
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
         --prokka-db ../db
```

# MeToParse
MeToParse aims to parse your results from the resulting output from MeToARGs. It considers the following statistics:
- <b>Query coverage</b>: What fraction of my metagenomic sequence is covered by the alignment? Query coverage (%) = (alignment length / query sequence length) × 100.
- <b>Subject coverage</b>: What fraction of the reference ARG is covered by my metagenomic sequence? Subject coverage (%) = (alignment length / subject sequence length) × 100.
- <b>Identity</b>: How similar are the aligned residues? Identity = (identical residues / alignment length) × 100.
- <b>E-value</b>: How random is it to find an alignment this good by change? The lower it is, the stronger is the statistical evidence that the alignment is not random.

By default, the MeToParse will consider "high-confidence candidates" those hits with an e-value ≤ 1e-10; identity ≥ 80%, query coverage ≥ 80%, and subject coverage ≥ 80%.
If several high-confidence candidate ARGs are listed for the same query sequence, the candidate with highest bitscore will be selected:
- <b>Bitscore: Indicates how good is the alignment. It is a normalized measure of the quality of the alignment, considering matches, mismatches, gaps, scoring matrix and alignment length. The higher, the better is the alignment.

# Citation

You can find all citations in the output file "citations.txt". Please, cite all the tools used in this pipeline, as well as:
