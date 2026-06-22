#!/bin/bash
#SBATCH --job-name=merge_all
#SBATCH --output=logs/merge_all_%A_%a.out
#SBATCH --error=logs/merge_all_%A_%a.err
#SBATCH --time=01:00:00                
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1              
#SBATCH --mem=4G                       
#SBATCH --partition=rosa.p
#SBATCH --array=1-175%20     
#SBATCH --mail-user=your.email@institution.edu
#SBATCH --mail-type=END 

export WORK_DIR="$WORK/RP3"
export OUT_DIR="${WORK_DIR}/00_raw_all_samples"
SAMPLE_LIST="${WORK_DIR}/all_samples_full_paths.txt"

mkdir -p "$OUT_DIR"

sample_path=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")

if [ -z "$sample_path" ]; then
    echo "No sample found for index $SLURM_ARRAY_TASK_ID"
    exit 1
fi

sample_id=$(basename "$sample_path")
echo "Processing Array Task $SLURM_ARRAY_TASK_ID: $sample_id"

# Merge R1
find "$sample_path" -name "*_R1_*.fastq.gz" | sort | xargs cat > "${OUT_DIR}/${sample_id}_R1.fastq.gz"

# Merge R2
find "$sample_path" -name "*_R2_*.fastq.gz" | sort | xargs cat > "${OUT_DIR}/${sample_id}_R2.fastq.gz"

echo "Finished merging $sample_id"
