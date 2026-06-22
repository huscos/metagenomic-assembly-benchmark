#!/bin/bash
#SBATCH --job-name=bin_A_concoct
#SBATCH --output=logs/bin_A_cc_%A_%a.out
#SBATCH --error=logs/bin_A_cc_%A_%a.err
#SBATCH --time=08:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --partition=rosa.p
#SBATCH --array=1-90%15
#SBATCH --mail-user=your.email@institution.edu 
#SBATCH --mail-type=FAIL,END

set -e

# 1. LOAD MODULES
module purge
module load hpc-env/13.1
# Load the specific CONCOCT container you found
module load CONCOCT/1.1.0-scikit_learn-1.1.1-container
# CONCOCT's python scripts rely on BEDTools and SAMtools to read the BAM files
module load BEDTools
module load SAMtools

# 2. PATHS
export WORK_DIR="$WORK/RP3"
export ASSEMBLY_DIR="${WORK_DIR}/03_assembly_single"
export MAP_DIR="${WORK_DIR}/08_mapping_mode_A"
export OUT_DIR="${WORK_DIR}/09_binning_mode_A"
SAMPLE_LIST="${WORK_DIR}/my_samples_full_paths.txt"

# 3. IDENTIFY SAMPLE
sample_path=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")

if [ -z "$sample_path" ]; then
    exit 0
fi

SAMPLE=$(basename "$sample_path")
ASSEMBLY_FASTA="${ASSEMBLY_DIR}/${SAMPLE}/${SAMPLE}.contigs.fa"
BAM_FILE="${MAP_DIR}/${SAMPLE}/${SAMPLE}.sorted.bam"

# Safety checks
if [ ! -f "$ASSEMBLY_FASTA" ] || [ ! -f "$BAM_FILE" ]; then
    echo "Warning: Missing assembly or BAM file for $SAMPLE. Skipping."
    exit 0
fi

# Create a sample-specific output folder for CONCOCT
SAMPLE_OUT="${OUT_DIR}/${SAMPLE}/concoct"
mkdir -p "$SAMPLE_OUT"

echo "=========================================================="
echo "Starting CONCOCT Mode A Binning for: $SAMPLE"
echo "=========================================================="

# CONCOCT drops a lot of temporary files, so we cd into its output directory
cd "$SAMPLE_OUT"

# Step 1: Cut contigs into 10K chunks
echo "Cutting contigs..."
cut_up_fasta.py "$ASSEMBLY_FASTA" -c 10000 -o 0 --merge_last -b contigs_10K.bed > contigs_10K.fa

# Step 2: Generate coverage table from our existing BAM file
echo "Calculating coverage table..."
concoct_coverage_table.py contigs_10K.bed "$BAM_FILE" > coverage_table.tsv

# Prevent OpenBLAS from spawning nested threads and generating massive error logs
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

# Step 3: Run the actual CONCOCT clustering algorithm
echo "Running CONCOCT..."
concoct --composition_file contigs_10K.fa --coverage_file coverage_table.tsv -b concoct_output/ -t 16

# Step 4: Merge the clustering results back together
echo "Merging chunks..."
merge_cutup_clustering.py concoct_output/clustering_gt1000.csv > clustering_merged.csv

# Step 5: Extract the final Fasta bins
echo "Extracting bins..."
mkdir -p bins
extract_fasta_bins.py "$ASSEMBLY_FASTA" clustering_merged.csv --output_path bins/

echo "SUCCESS: CONCOCT binning completed for $SAMPLE"
