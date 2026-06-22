#!/bin/bash
#SBATCH --job-name=gtdb_ult
#SBATCH --output=logs/gtdb_ult_%j.out
#SBATCH --error=logs/gtdb_ult_%j.err
#SBATCH --time=48:00:00               
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=250G                    
#SBATCH --partition=rosa.p

set -e

# 1. LOAD MODULES
module purge
module load hpc-env/13.1
module load GTDB-Tk/2.5.2-foss-2023a

# Quick check to ensure the HPC admins linked the database properly
if [ -z "$GTDBTK_DATA_PATH" ]; then
    echo "WARNING: GTDBTK_DATA_PATH is not set by the module!"
    # Exporting the path explicitly just in case!
    export GTDBTK_DATA_PATH="/cm/shared/uniol/sw/SYSTEM/GTDB-Tk/release214"
else
    echo "Database successfully located at: $GTDBTK_DATA_PATH"
fi

# 2. PATHS
BASE="/fs/dss/work/wuki2078/RP3"
MAGS="$BASE/13_ultimate_dRep/dRep_output/dereplicated_genomes"
OUT_DIR="$BASE/15_ultimate_taxonomy"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

echo "=========================================================="
echo "Starting GTDB-Tk Classification on 509 Ultimate MAGs..."
echo "=========================================================="

# 3. RUN GTDB-Tk
gtdbtk classify_wf \
    --genome_dir "$MAGS" \
    --extension fa \
    --out_dir "$OUT_DIR" \
    --cpus 32 \
    --skip_ani_screen

echo "=========================================================="
echo "GTDB-Tk completed successfully!"
echo "=========================================================="
