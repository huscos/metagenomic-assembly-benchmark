#!/bin/bash
#SBATCH --job-name=modeB_map
#SBATCH --output=logs/modeB_map_%A_%a.out
#SBATCH --error=logs/modeB_map_%A_%a.err
#SBATCH --time=24:00:00               
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --partition=rosa.p
#SBATCH --array=1-85

set -e

# 1. Load Modules for Mapping and Depth Calculation
module purge
module load hpc-env/13.1
module load BWA          
module load SAMtools     
module load MetaBAT       

# 2. Set base paths
BASE_DIR="/fs/dss/work/wuki2078/RP3"
QC_DIR="$BASE_DIR/01_qc_all_samples"
ASSEMBLY_DIR="$BASE_DIR/03_assembly_single"
BLUEPRINT_DIR="$BASE_DIR/04_modeB_blueprints"
OUT_DIR="$BASE_DIR/05_modeB_mapping"

# 3. Identify the EXACT sample this specific array job is processing
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$BASE_DIR/my_85_sample_ids.txt")

if [ -z "$SAMPLE" ]; then
    echo "Error: Sample name is empty. Check my_85_sample_ids.txt"
    exit 1
fi

echo "=========================================================="
echo "Starting Mode B Mapping for Assembly: $SAMPLE"
echo "=========================================================="

# 4. Define inputs and create output directory
CONTIGS="$ASSEMBLY_DIR/$SAMPLE/${SAMPLE}.contigs.fa"
MAPPING_LIST="$BLUEPRINT_DIR/${SAMPLE}_mapping.txt"
SAMPLE_OUT="$OUT_DIR/$SAMPLE"

# Clean out the folder if this is a rerun, then remake it
rm -rf "$SAMPLE_OUT"
mkdir -p "$SAMPLE_OUT"

# 5. Index the Contigs for BWA
echo "Indexing contigs..."
bwa index "$CONTIGS"

# 6. Map the 20 Recovery Samples
echo "Starting mapping loop..."
while read -r REC_SAMPLE; do
    [ -z "$REC_SAMPLE" ] && continue 
    
    R1="$QC_DIR/${REC_SAMPLE}_QC/${REC_SAMPLE}_R1_val_1.fq.gz"
    R2="$QC_DIR/${REC_SAMPLE}_QC/${REC_SAMPLE}_R2_val_2.fq.gz"
    
    if [[ -f "$R1" && -f "$R2" ]]; then
        echo "Mapping $REC_SAMPLE..."
        # Map with BWA, convert to BAM, and sort it (all in one efficient pipeline)
        bwa mem -t 16 "$CONTIGS" "$R1" "$R2" | \
        samtools view -bS - | \
        samtools sort -@ 16 -o "$SAMPLE_OUT/${REC_SAMPLE}.sorted.bam" -
    else
        echo "WARNING: Missing reads for $REC_SAMPLE. Skipping."
    fi
done < "$MAPPING_LIST"

# 7. Generate the Master Depth Matrix
echo "Generating depth matrix for Binning..."
jgi_summarize_bam_contig_depths \
    --outputDepth "$SAMPLE_OUT/depth.txt" \
    "$SAMPLE_OUT"/*.sorted.bam

echo "=========================================================="
echo "Mode B Mapping completed for $SAMPLE. Ready for Binning!"
echo "=========================================================="
