#!/bin/bash
#SBATCH --job-name=bc_single
#SBATCH --output=logs/bc_single_%j.out
#SBATCH --error=logs/bc_single_%j.err
#SBATCH --time=04:00:00               
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --partition=rosa.p

set -e

# 1. Activate Environment
source /user/wuki2078/miniconda3/etc/profile.d/conda.sh
conda activate binchicken_env

# 2. Paths
export SANDBOX="$WORK/RP3/03_binchicken_sandbox"
OUT_DIR="$SANDBOX/output_single"

echo "=========================================================="
echo "Generating Mode B Blueprint (Single Assembly + Multi-Binning)"
echo "=========================================================="

# Clean directory if it exists
rm -rf "$OUT_DIR"

# 3. Run the Bin Chicken 'single' module
binchicken single \
    --forward-list "$SANDBOX/fwd_reads.txt" \
    --reverse-list "$SANDBOX/rev_reads.txt" \
    --sample-singlem-list "$SANDBOX/sm_tables.txt" \
    --output "$OUT_DIR" \
    --cores 16

echo "=========================================================="
echo "SUCCESS: Mode B blueprint generated at $OUT_DIR"
echo "=========================================================="
