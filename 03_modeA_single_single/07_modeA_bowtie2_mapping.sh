#!/bin/bash
#SBATCH --job-name=map_modeA
#SBATCH --output=logs/map_A_%A_%a.out
#SBATCH --error=logs/map_A_%A_%a.err
#SBATCH --time=10:00:00             
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16         
#SBATCH --mem=32G                  
#SBATCH --partition=rosa.p
#SBATCH --array=1-90%15            
#SBATCH --mail-user=your.email@institution.edu 
#SBATCH --mail-type=FAIL,END

set -e

# 1. LOAD MODULES
module purge
module load hpc-env/13.1
module load Bowtie2
module load SAMtools

# 2. PATHS
export WORK_DIR="$WORK/RP3"
export QC_DIR="${WORK_DIR}/01_qc"
export ASSEMBLY_DIR="${WORK_DIR}/03_assembly_single"
export OUT_DIR="${WORK_DIR}/08_mapping_mode_A"
SAMPLE_LIST="${WORK_DIR}/my_samples_full_paths.txt"

mkdir -p "$OUT_DIR"

# 3. IDENTIFY SAMPLE
sample_path=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")

if [ -z "$sample_path" ]; then
    exit 0
fi

SAMPLE=$(basename "$sample_path")
ASSEMBLY_FASTA="${ASSEMBLY_DIR}/${SAMPLE}/${SAMPLE}.contigs.fa"

# If the assembly doesn't exist (e.g., if it failed earlier), skip it safely
if [ ! -f "$ASSEMBLY_FASTA" ]; then
    echo "Warning: No assembly found for $SAMPLE. Skipping."
    exit 0
fi

# Create a sample-specific output folder
SAMPLE_OUT="${OUT_DIR}/${SAMPLE}"
mkdir -p "$SAMPLE_OUT"

echo "=========================================================="
echo "Starting Mode A Mapping for: $SAMPLE"
echo "=========================================================="

# 4. FIND THE QC READS
R1=$(find "$QC_DIR/${SAMPLE}_QC" -name "*_val_1.fq.gz")
R2=$(find "$QC_DIR/${SAMPLE}_QC" -name "*_val_2.fq.gz")

# 5. BUILD BOWTIE2 INDEX
echo "Building Bowtie2 index..."
bowtie2-build --threads 16 "$ASSEMBLY_FASTA" "${SAMPLE_OUT}/${SAMPLE}_index"

# 6. RUN BOWTIE2 MAPPING AND CONVERT TO BAM
echo "Mapping reads and generating sorted BAM file..."
bowtie2 -p 16 -x "${SAMPLE_OUT}/${SAMPLE}_index" -1 "$R1" -2 "$R2" | \
    samtools view -bS - | \
    samtools sort -@ 16 -o "${SAMPLE_OUT}/${SAMPLE}.sorted.bam"

# 7. INDEX THE BAM FILE

echo "Indexing sorted BAM..."
samtools index "${SAMPLE_OUT}/${SAMPLE}.sorted.bam"

# Clean up the intermediate Bowtie2 index files to save space
rm "${SAMPLE_OUT}/${SAMPLE}_index".*

echo "SUCCESS: Mode A Mapping completed for $SAMPLE"
