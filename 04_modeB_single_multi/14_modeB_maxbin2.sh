#!/bin/bash
#SBATCH --job-name=mB_maxbin
#SBATCH --output=logs/mB_maxbin_%A_%a.out
#SBATCH --error=logs/mB_maxbin_%A_%a.err
#SBATCH --time=24:00:00               
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --partition=rosa.p
#SBATCH --array=1-85

set -e

# 1. LOAD MODULES & CONDA
module purge
module load hpc-env/13.1
source /user/wuki2078/miniconda3/bin/activate maxbin2

# 2. PATHS
BASE_DIR="/fs/dss/work/wuki2078/RP3"
ASSEMBLY_DIR="$BASE_DIR/03_assembly_single"
MAPPING_DIR="$BASE_DIR/05_modeB_mapping"
OUT_DIR="$BASE_DIR/06_modeB_binning/maxbin2"

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$BASE_DIR/my_85_sample_ids.txt")

echo "Starting Mode B MaxBin2 for $SAMPLE"

CONTIGS="$ASSEMBLY_DIR/$SAMPLE/${SAMPLE}.contigs.fa"
DEPTH="$MAPPING_DIR/$SAMPLE/depth.txt"
SAMPLE_OUT="$OUT_DIR/$SAMPLE"

rm -rf "$SAMPLE_OUT"
mkdir -p "$SAMPLE_OUT"

# 3. PREP MULTI-SAMPLE ABUNDANCE FOR MAXBIN2
# The JGI depth.txt puts depth values in columns 4, 6, 8, etc.
# This loop dynamically extracts each depth column into its own file.
ABUND_LIST="$SAMPLE_OUT/abund_list.txt"
NUM_COLS=$(awk '{print NF; exit}' "$DEPTH")

for (( c=4; c<=NUM_COLS; c+=2 )); do
    abund_file="$SAMPLE_OUT/abund_col_${c}.txt"
    awk -v col="$c" 'NR>1 {print $1 "\t" $col}' "$DEPTH" > "$abund_file"
    echo "$abund_file" >> "$ABUND_LIST"
done

# 4. RUN MAXBIN2 WITH MULTIPLE ABUNDANCES
run_MaxBin.pl -contig "$CONTIGS" -out "$SAMPLE_OUT/bin" -abund_list "$ABUND_LIST" -thread 16

echo "Mode B MaxBin2 finished for $SAMPLE"
