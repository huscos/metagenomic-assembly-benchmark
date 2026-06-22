#!/bin/bash
#SBATCH --job-name=checkm_ult
#SBATCH --output=logs/checkm_ult_%j.out
#SBATCH --error=logs/checkm_ult_%j.err
#SBATCH --time=48:00:00               
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G                    
#SBATCH --partition=rosa.p

set -e

# 1. LOAD MODULES
module purge
module load hpc-env/13.1
module load CheckM/1.2.3-foss-2023a

# 2. PATHS
BASE="/fs/dss/work/wuki2078/RP3"
MAGS="$BASE/13_ultimate_dRep/dRep_output/dereplicated_genomes"
OUT_DIR="$BASE/14_ultimate_checkm"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

echo "=========================================================="
echo "Starting Standalone CheckM 1.2.3 on 509 Ultimate MAGs..."
echo "=========================================================="

# Run the core CheckM workflow
checkm lineage_wf -t 32 -x fa "$MAGS" "$OUT_DIR"

# Generate a clean, tab-separated summary table
checkm qa "$OUT_DIR/lineage.ms" "$OUT_DIR" \
    -f "$OUT_DIR/checkm_summary.tsv" \
    --tab_table -o 2

echo "=========================================================="
echo "CheckM completed successfully!"
echo "=========================================================="
