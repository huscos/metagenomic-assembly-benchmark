#!/bin/bash
#SBATCH --job-name=bin_A_maxbin
#SBATCH --output=logs/bin_A_mx_%A_%a.out
#SBATCH --error=logs/bin_A_mx_%A_%a.err
#SBATCH --time=06:00:00             
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16       
#SBATCH --mem=32G                  
#SBATCH --partition=rosa.p
#SBATCH --array=1-90%15
#SBATCH --mail-user=your.email@institution.edu 
#SBATCH --mail-type=FAIL,END
set -e

# 1. LOAD MODULES & CONDA
module purge
module load hpc-env/13.1

source /user/wuki2078/miniconda3/bin/activate maxbin2

# 2. PATHS
export WORK_DIR="$WORK/RP3"
export ASSEMBLY_DIR="${WORK_DIR}/03_assembly_single"
export MAP_DIR="${WORK_DIR}/08_mapping_mode_A"
export OUT_DIR="${WORK_DIR}/09_binning_mode_A"  
SAMPLE_LIST="${WORK_DIR}/my_samples_full_paths.txt"

# 3. IDENTIFY SAMPLE
sample_path=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")

if [ -z "$sample_path" ]; then
    exit 0
fi

SAMPLE=$(basename "$sample_path")
ASSEMBLY_FASTA="${ASSEMBLY_DIR}/${SAMPLE}/${SAMPLE}.contigs.fa"

# We will use the depth file we already made for MetaBAT2
METABAT_DEPTH="${OUT_DIR}/${SAMPLE}/metabat2/${SAMPLE}_depth.txt"

# Safety checks
if [ ! -f "$ASSEMBLY_FASTA" ] || [ ! -f "$METABAT_DEPTH" ]; then
    echo "Warning: Missing assembly or MetaBAT depth file for $SAMPLE. Skipping."
    exit 0
fi

# Create a sample-specific output folder for MaxBin2
SAMPLE_OUT="${OUT_DIR}/${SAMPLE}/maxbin2"
mkdir -p "$SAMPLE_OUT"

echo "=========================================================="
echo "Starting MaxBin2 Mode A Binning for: $SAMPLE"
echo "=========================================================="

# 4. PREPARE THE ABUNDANCE FILE
# MaxBin2 needs a simple 2-column text file: [Contig Name] [Coverage]
# We use `awk` to extract columns 1 and 3 from the JGI depth file, skipping the header line (NR>1)
MAXBIN_ABUND="${SAMPLE_OUT}/${SAMPLE}_abund.txt"
awk 'NR>1 {print $1 "\t" $3}' "$METABAT_DEPTH" > "$MAXBIN_ABUND"

# 5. RUN MAXBIN2
run_MaxBin.pl \
    -contig "$ASSEMBLY_FASTA" \
    -abund "$MAXBIN_ABUND" \
    -out "${SAMPLE_OUT}/bin" \
    -min_contig_length 1500 \
    -thread 16

echo "SUCCESS: MaxBin2 binning completed for $SAMPLE"
