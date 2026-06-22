#!/bin/bash
#SBATCH --job-name=bin_A_refine
#SBATCH --output=logs/bin_A_ref_%A_%a.out
#SBATCH --error=logs/bin_A_ref_%A_%a.err
#SBATCH --time=12:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --partition=rosa.p
#SBATCH --array=1-90%15

set -e

# 1. LOAD MODULES
module purge
module load hpc-env/13.1
module load metaWRAP/1.3.2-conda

# 2. PATHS
export WORK_DIR="$WORK/RP3"
export BIN_DIR="${WORK_DIR}/09_binning_mode_A"
export OUT_DIR="${WORK_DIR}/12_refined_bins_mode_A"
SAMPLE_LIST="${WORK_DIR}/my_samples_full_paths.txt"

mkdir -p "$OUT_DIR"

# 3. IDENTIFY SAMPLE
sample_path=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")
[ -z "$sample_path" ] && exit 0
SAMPLE=$(basename "$sample_path")

METABAT_BINS="${BIN_DIR}/${SAMPLE}/metabat2"
MAXBIN_BINS="${BIN_DIR}/${SAMPLE}/maxbin2"
CONCOCT_BINS="${BIN_DIR}/${SAMPLE}/concoct/bins"

if [ ! -d "$METABAT_BINS" ] || [ ! -d "$MAXBIN_BINS" ] || [ ! -d "$CONCOCT_BINS" ]; then
    echo "Warning: Missing directories for $SAMPLE. Skipping."
    exit 0
fi

# ==========================================================
# 4. UNIVERSAL CLEANUP
# Filter out non-genome junk (depth files, unbinned contigs, seeds)
# ==========================================================
CLEAN_METABAT="${BIN_DIR}/${SAMPLE}/metabat2_clean"
CLEAN_MAXBIN="${BIN_DIR}/${SAMPLE}/maxbin2_clean"
CLEAN_CONCOCT="${BIN_DIR}/${SAMPLE}/concoct_clean"

mkdir -p "$CLEAN_METABAT" "$CLEAN_MAXBIN" "$CLEAN_CONCOCT"

# Clean MaxBin2 (Only grab .fasta, ignore .log/.seed)
cp ${MAXBIN_BINS}/*.fasta "$CLEAN_MAXBIN/" 2>/dev/null || true

# Clean MetaBAT2 (Grab .fa, but explicitly EXCLUDE the depth and unbinned files)
for file in ${METABAT_BINS}/*.fa; do
    if [[ "$file" != *"depth"* ]] && [[ "$file" != *"unbinned"* ]]; then
        cp "$file" "$CLEAN_METABAT/" 2>/dev/null || true
    fi
done

# Clean CONCOCT
cp ${CONCOCT_BINS}/*.fa "$CLEAN_CONCOCT/" 2>/dev/null || true

SAMPLE_OUT="${OUT_DIR}/${SAMPLE}"

# Clean up broken output from the previous crashed run
rm -rf "$SAMPLE_OUT"

echo "=========================================================="
echo "Starting metaWRAP Bin Refinement for: $SAMPLE"
echo "=========================================================="

# 5. RUN METAWRAP BIN_REFINEMENT
# Notice we are now pointing to the 3 CLEAN folders
metawrap bin_refinement \
    -o "$SAMPLE_OUT" \
    -t 16 \
    -A "$CLEAN_METABAT" \
    -B "$CLEAN_MAXBIN" \
    -C "$CLEAN_CONCOCT" \
    -c 50 -x 10

echo "SUCCESS: Bin Refinement completed for $SAMPLE"
