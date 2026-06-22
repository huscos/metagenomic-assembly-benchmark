#!/bin/bash
#SBATCH --job-name=mB_concoct
#SBATCH --output=logs/mB_concoct_%A_%a.out
#SBATCH --error=logs/mB_concoct_%A_%a.err
#SBATCH --time=24:00:00               
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --partition=rosa.p
#SBATCH --array=1-85

set -e

# 1. LOAD MODULES
module purge
module load hpc-env/13.1
module load CONCOCT/1.1.0-scikit_learn-1.1.1-container
module load BEDTools
module load SAMtools

# 2. PATHS
BASE_DIR="/fs/dss/work/wuki2078/RP3"
ASSEMBLY_DIR="$BASE_DIR/03_assembly_single"
MAPPING_DIR="$BASE_DIR/05_modeB_mapping"
OUT_DIR="$BASE_DIR/06_modeB_binning/concoct"

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$BASE_DIR/my_85_sample_ids.txt")

echo "Starting Mode B CONCOCT for $SAMPLE"

CONTIGS="$ASSEMBLY_DIR/$SAMPLE/${SAMPLE}.contigs.fa"
SAMPLE_OUT="$OUT_DIR/$SAMPLE"

rm -rf "$SAMPLE_OUT"
mkdir -p "$SAMPLE_OUT"

# 3. CUT CONTIGS
cut_up_fasta.py "$CONTIGS" -c 10000 -o 0 --merge_last -b "$SAMPLE_OUT/contigs_10K.bed" > "$SAMPLE_OUT/contigs_10K.fa"

# 4. GENERATE COVERAGE TABLE 
concoct_coverage_table.py "$SAMPLE_OUT/contigs_10K.bed" "$MAPPING_DIR/$SAMPLE"/*.sorted.bam > "$SAMPLE_OUT/coverage_table.tsv"

# Prevent OpenBLAS from spawning nested threads and generating massive error logs
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

# 5. RUN CONCOCT
concoct --composition_file "$SAMPLE_OUT/contigs_10K.fa" --coverage_file "$SAMPLE_OUT/coverage_table.tsv" -b "$SAMPLE_OUT/" -t 16

# 6. MERGE AND EXTRACT BINS
merge_cutup_clustering.py "$SAMPLE_OUT/clustering_gt1000.csv" > "$SAMPLE_OUT/clustering_merged.csv"
mkdir -p "$SAMPLE_OUT/concoct_bins"
extract_fasta_bins.py "$CONTIGS" "$SAMPLE_OUT/clustering_merged.csv" --output_path "$SAMPLE_OUT/concoct_bins"

echo "Mode B CONCOCT finished for $SAMPLE"
