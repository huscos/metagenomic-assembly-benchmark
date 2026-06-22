#!/bin/bash
#SBATCH --job-name=mC_refine
#SBATCH --output=logs/mC_refine_%A_%a.out
#SBATCH --error=logs/mC_refine_%A_%a.err
#SBATCH --time=24:00:00               
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=96G
#SBATCH --partition=rosa.p
#SBATCH --array=1-28

set -e

# 1. LOAD MODULES
module purge
module load hpc-env/13.1
module load metaWRAP/1.3.2-conda

# 2. PATHS & ARRAY LOGIC
BASE="/fs/dss/work/wuki2078/RP3"
LIST="$BASE/my_modeC_pairs.tsv"
BIN_DIR="$BASE/11_modeC_binning"
OUT_BASE="$BASE/12_modeC_refined"

# Fix: Create parent directory
mkdir -p "$OUT_BASE"

LINE_NUM=$((SLURM_ARRAY_TASK_ID + 1))
LINE=$(sed -n "${LINE_NUM}p" "$LIST")
PAIR_STRING=$(echo "$LINE" | awk '{print $1}')
S1=$(echo "$PAIR_STRING" | cut -d',' -f1)
S2=$(echo "$PAIR_STRING" | cut -d',' -f2)
PAIR="${S1}_${S2}"

echo "=========================================================="
echo "Starting metaWRAP Refinement for Co-Assembly: $PAIR"
echo "=========================================================="

# Locate raw output folders
METABAT_DIR="$BIN_DIR/metabat2/$PAIR"
MAXBIN_DIR="$BIN_DIR/maxbin2/$PAIR"
CONCOCT_DIR="$BIN_DIR/concoct/$PAIR/concoct_bins"

# ==========================================================
# 3. UNIVERSAL CLEANUP 
# ==========================================================
CLEAN_METABAT="$BIN_DIR/metabat2_clean/$PAIR"
CLEAN_MAXBIN="$BIN_DIR/maxbin2_clean/$PAIR"
CLEAN_CONCOCT="$BIN_DIR/concoct_clean/$PAIR"

mkdir -p "$CLEAN_METABAT" "$CLEAN_MAXBIN" "$CLEAN_CONCOCT"

# Clean MaxBin2 (Only grab .fasta)
cp ${MAXBIN_DIR}/*.fasta "$CLEAN_MAXBIN/" 2>/dev/null || true

# Clean MetaBAT2 (Grab .fa, but explicitly EXCLUDE the depth files/unbinned)
for file in ${METABAT_DIR}/*.fa; do
    if [[ "$file" != *"depth"* ]] && [[ "$file" != *"unbinned"* ]]; then
        cp "$file" "$CLEAN_METABAT/" 2>/dev/null || true
    fi
done

# Clean CONCOCT
cp ${CONCOCT_DIR}/*.fa "$CLEAN_CONCOCT/" 2>/dev/null || true

# ==========================================================
# 4. RUN METAWRAP BIN_REFINEMENT
# ==========================================================
OUT_DIR="$OUT_BASE/$PAIR"
rm -rf "$OUT_DIR"

# -c 50 -x 10 : Only keep MAGs >50% complete and <10% contaminated
metawrap bin_refinement \
    -o "$OUT_DIR" \
    -t 16 \
    -A "$CLEAN_METABAT" \
    -B "$CLEAN_MAXBIN" \
    -C "$CLEAN_CONCOCT" \
    -c 50 -x 10

echo "=========================================================="
echo "Mode C Bin Refinement finished for $PAIR!"
echo "=========================================================="
