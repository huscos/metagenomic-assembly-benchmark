#!/bin/bash
#SBATCH --job-name=sm_pipe
#SBATCH --output=logs/sm_pipe_%A_%a.out
#SBATCH --error=logs/sm_pipe_%A_%a.err
#SBATCH --time=24:00:00                
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16             
#SBATCH --mem=64G                    
#SBATCH --partition=rosa.p
#SBATCH --array=1-175%20    
#SBATCH --mail-user=your.email@institution.edu 
#SBATCH --mail-type=FAIL,END

set -e

# 1. LOAD CONDA
source /user/wuki2078/miniconda3/etc/profile.d/conda.sh
conda activate singlem

# 2. PATHS & DATABASE
export WORK_DIR="$WORK/RP3"
export QC_DIR="${WORK_DIR}/01_qc_all_samples"
export OUT_DIR="${WORK_DIR}/02a_singlem_pipe_array"
SAMPLE_LIST="${WORK_DIR}/all_samples_full_paths.txt"

# --- THE FIX: Point to the SingleM Database ---
DATA_PARENT_DIR="$WORK/RP3/singlem_data"
REAL_DB_PATH=$(find "$DATA_PARENT_DIR" -name "CONTENTS.json" -print -quit | xargs dirname)
export SINGLEM_METAPACKAGE_PATH="$REAL_DB_PATH"
# ----------------------------------------------

mkdir -p "$OUT_DIR"

# 3. GET SAMPLE
sample_path=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")
[ -z "$sample_path" ] && exit 1
SAMPLE=$(basename "$sample_path")

echo "Running SingleM Pipe on $SAMPLE..."

# 4. LOCATE TRIM GALORE QC FILES
R1="${QC_DIR}/${SAMPLE}_QC/${SAMPLE}_R1_val_1.fq.gz"
R2="${QC_DIR}/${SAMPLE}_QC/${SAMPLE}_R2_val_2.fq.gz"

if [ ! -f "$R1" ] || [ ! -f "$R2" ]; then
    echo "Error: QC files for $SAMPLE not found!"
    exit 1
fi

# 5. RUN SINGLEM PIPE
singlem pipe \
    --sequences "$R1" "$R2" \
    --otu-table "${OUT_DIR}/${SAMPLE}_otu_table.csv" \
    --archive-otu-table "${OUT_DIR}/${SAMPLE}.json" \
    --threads 16

echo "Pipe finished for $SAMPLE"
