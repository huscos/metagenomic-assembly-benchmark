#!/bin/bash
#SBATCH --job-name=mC_megahit
#SBATCH --output=logs/mC_megahit_%A_%a.out
#SBATCH --error=logs/mC_megahit_%A_%a.err
#SBATCH --time=48:00:00               
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G                   
#SBATCH --partition=rosa.p
#SBATCH --array=1-28                

set -e

# 1. LOAD MODULES
module purge
module load hpc-env/13.1
module load MEGAHIT

# 2. PATHS (Updated to the exact QC folder architecture)
BASE="/fs/dss/work/wuki2078/RP3"
QC_DIR="$BASE/01_qc_all_samples"       
LIST="$BASE/my_modeC_pairs.tsv"
OUT_BASE="$BASE/09_modeC_coassembly"

mkdir -p "$OUT_BASE"

# 3. EXTRACT THE PAIR FOR THIS ARRAY TASK
# Add +1 because line 1 is the header
LINE_NUM=$((SLURM_ARRAY_TASK_ID + 1))
LINE=$(sed -n "${LINE_NUM}p" "$LIST")

# Extract the two sample names from the first column
PAIR_STRING=$(echo "$LINE" | awk '{print $1}')
S1=$(echo "$PAIR_STRING" | cut -d',' -f1)
S2=$(echo "$PAIR_STRING" | cut -d',' -f2)

echo "=========================================================="
echo "Starting Mode C Co-Assembly for: $S1 and $S2"
echo "=========================================================="

COASSEMBLY_OUT="$OUT_BASE/${S1}_${S2}"

# Remove the folder if it already exists from a previous run
rm -rf "$COASSEMBLY_OUT"

# 4. RUN MEGAHIT
# Passing both R1s separated by a comma, and both R2s separated by a comma
megahit \
    -1 "$QC_DIR/${S1}_QC/${S1}_R1_val_1.fq.gz,$QC_DIR/${S2}_QC/${S2}_R1_val_1.fq.gz" \
    -2 "$QC_DIR/${S1}_QC/${S1}_R2_val_2.fq.gz,$QC_DIR/${S2}_QC/${S2}_R2_val_2.fq.gz" \
    -o "$COASSEMBLY_OUT" \
    -t 16

echo "=========================================================="
echo "Co-Assembly finished for $S1 and $S2!"
echo "=========================================================="
