#!/bin/bash
#SBATCH --job-name=mB_refine
#SBATCH --output=logs/mB_refine_%A_%a.out
#SBATCH --error=logs/mB_refine_%A_%a.err
#SBATCH --time=24:00:00               
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=96G
#SBATCH --partition=rosa.p
#SBATCH --array=1-85

set -e

# 1. LOAD MODULES
module purge
module load hpc-env/13.1
module load metaWRAP/1.3.2-conda

# 2. PATHS
BASE_DIR="/fs/dss/work/wuki2078/RP3"
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$BASE_DIR/my_85_sample_ids.txt")
[ -z "$SAMPLE" ] && exit 0

echo "Starting Mode B Bin Refinement for $SAMPLE"

BIN_DIR="$BASE_DIR/06_modeB_binning"
REFINE_BASE="$BIN_DIR/refinement"


mkdir -p "$REFINE_BASE" 

# Locate the raw output folders from the three binners
METABAT_DIR="$BIN_DIR/metabat2/$SAMPLE"
MAXBIN_DIR="$BIN_DIR/maxbin2/$SAMPLE"
CONCOCT_DIR="$BIN_DIR/concoct/$SAMPLE/concoct_bins"

# ==========================================================
# 3. UNIVERSAL CLEANUP (Adapted from Mode A script)
# ==========================================================
CLEAN_METABAT="$BIN_DIR/metabat2_clean/$SAMPLE"
CLEAN_MAXBIN="$BIN_DIR/maxbin2_clean/$SAMPLE"
CLEAN_CONCOCT="$BIN_DIR/concoct_clean/$SAMPLE"

mkdir -p "$CLEAN_METABAT" "$CLEAN_MAXBIN" "$CLEAN_CONCOCT"

# Clean MaxBin2 (Only grab .fasta)
cp ${MAXBIN_DIR}/*.fasta "$CLEAN_MAXBIN/" 2>/dev/null || true

# Clean MetaBAT2 (Grab .fa, but explicitly EXCLUDE the depth files)
for file in ${METABAT_DIR}/*.fa; do
    if [[ "$file" != *"depth"* ]] && [[ "$file" != *"unbinned"* ]]; then
        cp "$file" "$CLEAN_METABAT/" 2>/dev/null || true
    fi
done

# Clean CONCOCT
cp ${CONCOCT_DIR}/*.fa "$CLEAN_CONCOCT/" 2>/dev/null || true

# 4. RUN METAWRAP BIN_REFINEMENT
OUT_DIR="$REFINE_BASE/$SAMPLE"
rm -rf "$OUT_DIR"

metawrap bin_refinement \
    -o "$OUT_DIR" \
    -t 16 \
    -A "$CLEAN_METABAT" \
    -B "$CLEAN_MAXBIN" \
    -C "$CLEAN_CONCOCT" \
    -c 50 -x 10

echo "Mode B Bin Refinement finished for $SAMPLE!"
