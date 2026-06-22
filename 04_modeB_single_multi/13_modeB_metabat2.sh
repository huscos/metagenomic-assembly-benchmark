#!/bin/bash
#SBATCH --job-name=mB_metabat
#SBATCH --output=logs/mB_metabat_%A_%a.out
#SBATCH --error=logs/mB_metabat_%A_%a.err
#SBATCH --time=12:00:00               
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=32G
#SBATCH --partition=rosa.p
#SBATCH --array=1-85

set -e

# 1. LOAD MODULES
module purge
module load hpc-env/13.1
module load MetaBAT

# 2. PATHS
BASE_DIR="/fs/dss/work/wuki2078/RP3"
ASSEMBLY_DIR="$BASE_DIR/03_assembly_single"
MAPPING_DIR="$BASE_DIR/05_modeB_mapping"
OUT_DIR="$BASE_DIR/06_modeB_binning/metabat2"

SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$BASE_DIR/my_85_sample_ids.txt")

echo "Starting Mode B MetaBAT2 for $SAMPLE"


CONTIGS="$ASSEMBLY_DIR/$SAMPLE/${SAMPLE}.contigs.fa"
DEPTH="$MAPPING_DIR/$SAMPLE/depth.txt"
SAMPLE_OUT="$OUT_DIR/$SAMPLE"

rm -rf "$SAMPLE_OUT"
mkdir -p "$SAMPLE_OUT"

# 3. RUN METABAT2
metabat2 -i "$CONTIGS" -a "$DEPTH" -o "$SAMPLE_OUT/bin" -m 1500 -t 32

echo "Mode B MetaBAT2 finished for $SAMPLE"
