#!/bin/bash
#SBATCH --job-name=megahit_assembly
#SBATCH --output=logs/assembly_%A_%a.out
#SBATCH --error=logs/assembly_%A_%a.err
#SBATCH --time=05:00:00             
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32          
#SBATCH --mem=64G                   
#SBATCH --partition=rosa.p
#SBATCH --array=1-90%10             
#SBATCH --mail-user=your.email@institution.edu 
#SBATCH --mail-type=FAIL,END

# 1. LOAD MODULES
module purge
module load hpc-env/13.1
module load MEGAHIT

# 2. PATHS
export WORK_DIR="$WORK/RP3"
export QC_DIR="${WORK_DIR}/01_qc"
export OUT_DIR="${WORK_DIR}/03_assembly_single"
SAMPLE_LIST="${WORK_DIR}/my_samples_full_paths.txt"

# *** CREATE THE PARENT DIRECTORY MANUALLY ***
mkdir -p "$OUT_DIR"

# 3. IDENTIFY SAMPLE
sample_path=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")

if [ -z "$sample_path" ]; then
    echo "Error: No sample found for Task $SLURM_ARRAY_TASK_ID"
    exit 1
fi

SAMPLE=$(basename "$sample_path")
SAMPLE_OUT="${OUT_DIR}/${SAMPLE}"

echo "Processing $SAMPLE..."

# 4. FIND FILES
R1=$(find "$QC_DIR/${SAMPLE}_QC" -name "*_val_1.fq.gz")
R2=$(find "$QC_DIR/${SAMPLE}_QC" -name "*_val_2.fq.gz")

if [ -z "$R1" ] || [ -z "$R2" ]; then
    echo "Error: QC files missing for $SAMPLE"
    exit 1
fi

# 5. RUN MEGAHIT
# We remove the old folder just in case a previous run left a mess
rm -rf "$SAMPLE_OUT"

megahit \
    -1 "$R1" \
    -2 "$R2" \
    --min-contig-len 1000 \
    -m 0.9 \
    -t 16 \
    --out-dir "$SAMPLE_OUT" \
    --out-prefix "$SAMPLE"

echo "SUCCESS: Assembly completed for $SAMPLE"
