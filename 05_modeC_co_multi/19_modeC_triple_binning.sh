#!/bin/bash
#SBATCH --job-name=mC_bin
#SBATCH --output=logs/mC_bin_%A_%a.out
#SBATCH --error=logs/mC_bin_%A_%a.err
#SBATCH --time=48:00:00               
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --partition=rosa.p
#SBATCH --array=1-28

set -e

# 1. LOAD MODULES 
module purge
module load hpc-env/13.1
module load CONCOCT/1.1.0-scikit_learn-1.1.1-container
module load BEDTools
module load SAMtools
source /user/wuki2078/miniconda3/bin/activate maxbin2
module load MetaBAT

# 2. PATHS
BASE="/fs/dss/work/wuki2078/RP3"
COASSEMBLY_DIR="$BASE/09_modeC_coassembly"
MAPPING_DIR="$BASE/10_modeC_mapping"
OUT_BASE="$BASE/11_modeC_binning"
LIST="$BASE/my_modeC_pairs.tsv"

LINE_NUM=$((SLURM_ARRAY_TASK_ID + 1))
LINE=$(sed -n "${LINE_NUM}p" "$LIST")
PAIR_STRING=$(echo "$LINE" | awk '{print $1}')
S1=$(echo "$PAIR_STRING" | cut -d',' -f1)
S2=$(echo "$PAIR_STRING" | cut -d',' -f2)
PAIR="${S1}_${S2}"

CONTIGS="$COASSEMBLY_DIR/$PAIR/final.contigs.fa"
DEPTH="$MAPPING_DIR/$PAIR/depth.txt"

echo "=========================================================="
echo "Starting Triple Binning for Co-Assembly: $PAIR"
echo "=========================================================="

# ---------------------------------------------------------
# A. MetaBAT2
# ---------------------------------------------------------
echo "Running MetaBAT2..."
MB_OUT="$OUT_BASE/metabat2/$PAIR"
rm -rf "$MB_OUT" && mkdir -p "$MB_OUT"

metabat2 -i "$CONTIGS" -a "$DEPTH" -o "$MB_OUT/bin" -t 16 -m 1500

# ---------------------------------------------------------
# B. MaxBin2
# ---------------------------------------------------------
echo "Running MaxBin2..."
MAXBIN_OUT="$OUT_BASE/maxbin2/$PAIR"
rm -rf "$MAXBIN_OUT" && mkdir -p "$MAXBIN_OUT"
ABUND_LIST="$MAXBIN_OUT/abund_list.txt"

# Extract abundance columns from the JGI depth file
NUM_COLS=$(head -n 1 "$DEPTH" | awk '{print NF}')
for ((i=4; i<=NUM_COLS; i+=2)); do
    cut -f1,$i "$DEPTH" | tail -n +2 > "$MAXBIN_OUT/abund_col_${i}.txt"
    echo "$MAXBIN_OUT/abund_col_${i}.txt" >> "$ABUND_LIST"
done

run_MaxBin.pl -contig "$CONTIGS" -out "$MAXBIN_OUT/bin" -abund_list "$ABUND_LIST" -thread 16

# ---------------------------------------------------------
# C. CONCOCT
# ---------------------------------------------------------
echo "Running CONCOCT..."
CONCOCT_OUT="$OUT_BASE/concoct/$PAIR"
rm -rf "$CONCOCT_OUT" && mkdir -p "$CONCOCT_OUT"

# 1. Cut contigs & make coverage table
cut_up_fasta.py "$CONTIGS" -c 10000 -o 0 --merge_last -b "$CONCOCT_OUT/contigs_10K.bed" > "$CONCOCT_OUT/contigs_10K.fa"
concoct_coverage_table.py "$CONCOCT_OUT/contigs_10K.bed" "$MAPPING_DIR/$PAIR"/*.sorted.bam > "$CONCOCT_OUT/coverage_table.tsv"

# 2. Silence OpenBLAS to prevent the error log problem
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

# 3. Run clustering
concoct --composition_file "$CONCOCT_OUT/contigs_10K.fa" --coverage_file "$CONCOCT_OUT/coverage_table.tsv" -b "$CONCOCT_OUT/" -t 16

# 4. Extract standard .fasta bins so metaWRAP can read them later
merge_cutup_clustering.py "$CONCOCT_OUT/clustering_gt1000.csv" > "$CONCOCT_OUT/clustering_merged.csv"
mkdir -p "$CONCOCT_OUT/concoct_bins"
extract_fasta_bins.py "$CONTIGS" "$CONCOCT_OUT/clustering_merged.csv" --output_path "$CONCOCT_OUT/concoct_bins"

echo "=========================================================="
echo "Triple Binning successfully finished for $PAIR!"
echo "=========================================================="
