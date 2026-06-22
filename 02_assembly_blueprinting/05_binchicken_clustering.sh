#!/bin/bash
#SBATCH --job-name=b_chicken
#SBATCH --output=logs/b_chicken_%j.out
#SBATCH --error=logs/b_chicken_%j.err
#SBATCH --time=06:00:00               
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

# Clean out the failed Snakemake directory
rm -rf "$SANDBOX/output/coassemble"

echo "=========================================================="
echo "Executing Bin Chicken Coassemble"
echo "=========================================================="

# 3. The Pure Command! No hacks, no Pixi overrides!
binchicken coassemble \
    --forward-list "$SANDBOX/fwd_reads.txt" \
    --reverse-list "$SANDBOX/rev_reads.txt" \
    --sample-singlem-list "$SANDBOX/sm_tables.txt" \
    --output "$SANDBOX/output" \
    --cores 16

echo "=========================================================="
echo "SUCCESS!"
