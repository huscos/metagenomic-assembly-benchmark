#!/bin/bash
#SBATCH --job-name=qc_all
#SBATCH --output=logs/qc_all_%A_%a.out  
#SBATCH --error=logs/qc_all_%A_%a.err
#SBATCH --time=02:00:00             
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4           
#SBATCH --mem=4G                    
#SBATCH --partition=rosa.p
#SBATCH --array=1-175%20     

# 1. LOAD MODULES
module purge
module load hpc-env/13.1
module load Trim_Galore

# 2. PATHS
export WORK_DIR="$WORK/RP3"
# Point to the merged files we just created in Step 1
export RAW_DIR="${WORK_DIR}/00_raw_all_samples"
export OUT_DIR="${WORK_DIR}/01_qc_all_samples"
# Use the master list containing ALL samples
SAMPLE_LIST="${WORK_DIR}/all_samples_full_paths.txt"

# 3. GET SAMPLE FOR THIS TASK
sample_path=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")

if [ -z "$sample_path" ]; then
    echo "Error: No sample found for Array Task $SLURM_ARRAY_TASK_ID"
    exit 1
fi

SAMPLE=$(basename "$sample_path")
SAMPLE_OUT="${OUT_DIR}/${SAMPLE}_QC"

mkdir -p "$SAMPLE_OUT"

echo "=========================================================="
echo "Array Task: $SLURM_ARRAY_TASK_ID"
echo "Sample: $SAMPLE"
echo "Tool: $(which trim_galore)"
echo "=========================================================="

# 4. RUN TRIM GALORE
trim_galore \
    --paired \
    --gzip \
    --length 50 \
    --fastqc \
    --cores 4 \
    --output_dir "$SAMPLE_OUT" \
    "${RAW_DIR}/${SAMPLE}_R1.fastq.gz" \
    "${RAW_DIR}/${SAMPLE}_R2.fastq.gz"

echo "QC Finished for $SAMPLE"

