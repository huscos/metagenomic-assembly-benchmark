#!/bin/bash
#SBATCH --job-name=bin_A_metabat
#SBATCH --output=logs/bin_A_mb_%A_%a.out
#SBATCH --error=logs/bin_A_mb_%A_%a.err
#SBATCH --time=04:00:00            
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8          
#SBATCH --mem=16G                 
#SBATCH --partition=rosa.p
#SBATCH --array=1-90%15
#SBATCH --mail-user=your.email@institution.edu 
#SBATCH --mail-type=FAIL,END

set -e

# 1. LOAD MODULES
module purge
module load hpc-env/13.1
# Let's assume MetaBAT2 is available as a module. If not, we'll conda-install it!
module load MetaBAT

# 2. PATHS
export WORK_DIR="$WORK/RP3"
export ASSEMBLY_DIR="${WORK_DIR}/03_assembly_single"
export MAP_DIR="${WORK_DIR}/08_mapping_mode_A"
export OUT_DIR="${WORK_DIR}/09_binning_mode_A"
SAMPLE_LIST="${WORK_DIR}/my_samples_full_paths.txt"

mkdir -p "$OUT_DIR"

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

# Create a sample-specific output folder for MetaBAT2
SAMPLE_OUT="${OUT_DIR}/${SAMPLE}/metabat2"
mkdir -p "$SAMPLE_OUT"

echo "=========================================================="
echo "Starting MetaBAT2 Mode A Binning for: $SAMPLE"
echo "=========================================================="

# 4. CALCULATE DEPTH MATRIX
echo "Calculating contig depths..."
DEPTH_FILE="${SAMPLE_OUT}/${SAMPLE}_depth.txt"

jgi_summarize_bam_contig_depths \
    --outputDepth "$DEPTH_FILE" \
    "$BAM_FILE"

# 5. RUN METABAT2
echo "Running MetaBAT2..."
metabat2 \
    -i "$ASSEMBLY_FASTA" \
    -a "$DEPTH_FILE" \
    -o "${SAMPLE_OUT}/bin" \
    -m 1500 \
    -t 8

echo "SUCCESS: MetaBAT2 binning completed for $SAMPLE"
