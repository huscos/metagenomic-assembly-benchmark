#!/bin/bash
#SBATCH --job-name=mC_map
#SBATCH --output=logs/mC_map_%A_%a.out
#SBATCH --error=logs/mC_map_%A_%a.err
#SBATCH --time=48:00:00               
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --partition=rosa.p
#SBATCH --array=1-28

set -e

# 1. Load Modules
module purge
module load hpc-env/13.1
module load BWA
module load SAMtools
module load MetaBAT

# 2. Set base paths 
BASE_DIR="/fs/dss/work/wuki2078/RP3"
QC_DIR="$BASE_DIR/01_qc_all_samples"
COASSEMBLY_DIR="$BASE_DIR/09_modeC_coassembly"
OUT_DIR="$BASE_DIR/10_modeC_mapping"
LIST="$BASE_DIR/my_modeC_pairs.tsv"

# 3. Identify the pair and the target samples for this task
LINE_NUM=$((SLURM_ARRAY_TASK_ID + 1))
LINE=$(sed -n "${LINE_NUM}p" "$LIST")

# Column 1 is the pair, Column 5 is the comma-separated target list
PAIR_STRING=$(echo "$LINE" | awk '{print $1}')
S1=$(echo "$PAIR_STRING" | cut -d',' -f1)
S2=$(echo "$PAIR_STRING" | cut -d',' -f2)
RECOVER_SAMPLES=$(echo "$LINE" | awk '{print $5}')

echo "=========================================================="
echo "Starting Mode C Mapping for Co-Assembly: $S1 & $S2"
echo "=========================================================="

# 4. Define inputs and create output directory
# MEGAHIT outputs contigs as 'final.contigs.fa' inside its output folder
CONTIGS="$COASSEMBLY_DIR/${S1}_${S2}/final.contigs.fa"
SAMPLE_OUT="$OUT_DIR/${S1}_${S2}"

rm -rf "$SAMPLE_OUT"
mkdir -p "$SAMPLE_OUT"

# 5. Index the Co-assembled Contigs for BWA
echo "Indexing contigs..."
bwa index "$CONTIGS"

# 6. Map the Recovery Samples
echo "Starting targeted mapping loop..."
# 'tr' converts the commas into spaces so the bash 'for' loop can read them
for REC_SAMPLE in $(echo "$RECOVER_SAMPLES" | tr ',' ' '); do
    
    R1="$QC_DIR/${REC_SAMPLE}_QC/${REC_SAMPLE}_R1_val_1.fq.gz"
    R2="$QC_DIR/${REC_SAMPLE}_QC/${REC_SAMPLE}_R2_val_2.fq.gz"
    
    if [[ -f "$R1" && -f "$R2" ]]; then
        echo "Mapping $REC_SAMPLE..."
        # Map with BWA, convert to BAM, and sort
        bwa mem -t 16 "$CONTIGS" "$R1" "$R2" | \
        samtools view -bS - | \
        samtools sort -@ 16 -o "$SAMPLE_OUT/${REC_SAMPLE}.sorted.bam" -
        
        # FIX: Index the BAM immediately so CONCOCT is happy later!
        samtools index -@ 16 "$SAMPLE_OUT/${REC_SAMPLE}.sorted.bam"
    else
        echo "WARNING: Missing reads for $REC_SAMPLE. Skipping."
    fi
done

# 7. Generate the Master Depth Matrix
echo "Generating depth matrix for Binning..."
jgi_summarize_bam_contig_depths \
    --outputDepth "$SAMPLE_OUT/depth.txt" \
    "$SAMPLE_OUT"/*.sorted.bam

echo "=========================================================="
echo "Mode C Mapping completed for $S1 & $S2. Ready for Binning!"
echo "=========================================================="
