#!/bin/bash
#SBATCH --job-name=dRep_ult
#SBATCH --output=logs/dRep_ult_%j.out
#SBATCH --error=logs/dRep_ult_%j.err
#SBATCH --time=48:00:00               
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32           
#SBATCH --mem=128G                   
#SBATCH --partition=rosa.p

set -e

echo "=========================================================="
echo "🏆 MODE A vs B vs C 🏆"
echo "=========================================================="

# 1. LOAD MODULES
module purge
module load hpc-env/13.1
module load dRep/3.4.3.dev-foss-2023a 

# 2. PATHS
BASE="/fs/dss/work/wuki2078/RP3"
PREV_COMBINED="$BASE/07_dRep_comparison/combined_mags"
MODEC_REFINED="$BASE/12_modeC_refined"
ULTIMATE_BASE="$BASE/13_ultimate_dRep"
STAGING="$ULTIMATE_BASE/staging_mags"
OUT_DIR="$ULTIMATE_BASE/dRep_output"

# Clean up any previous attempts and make fresh folders
rm -rf "$ULTIMATE_BASE"
mkdir -p "$STAGING"

echo "1. Copying the previous Mode A & B competitors..."
cp "$PREV_COMBINED"/*.fa "$STAGING/"

echo "2. Adding the new Mode C competitors..."
# Loop through all the 28 Mode C pairs, grab the good bins, and add the "mC_" prefix
for BIN in "$MODEC_REFINED"/*/metawrap_50_10_bins/*.fa; do
    if [ -f "$BIN" ]; then
        # Extract the Pair name (e.g., P34354_192_P34354_228) from the file path
        PAIR_NAME=$(echo "$BIN" | awk -F'/' '{print $(NF-2)}')
        BIN_FILE=$(basename "$BIN")
        
        # Copy and rename with mC_ prefix
        cp "$BIN" "$STAGING/mC_${PAIR_NAME}_${BIN_FILE}"
    fi
done

TOTAL_MAGS=$(ls -1 "$STAGING"/*.fa | wc -l)
echo "Staging complete! Total MAGs entering the arena: $TOTAL_MAGS"

# 3. RUN DREP
echo "=========================================================="
echo "Starting dRep Dereplication on $TOTAL_MAGS genomes..."
echo "=========================================================="

# -comp 50 -con 10 : Keep only >50% complete, <10% contamination
# -sa 0.95 : 95% ANI for species level clustering
dRep dereplicate "$OUT_DIR" -g "$STAGING"/*.fa -p 32 -comp 50 -con 10 -sa 0.95

echo "=========================================================="
echo "Ultimate dRep successfully finished!"
echo "=========================================================="

