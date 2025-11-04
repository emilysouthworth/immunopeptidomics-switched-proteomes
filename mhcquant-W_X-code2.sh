#!/bin/bash


# ---- Load environment ----
source /etc/profile.d/modules.sh
module load roslin/nextflow/25.04.6
module load singularity/4.1.3

# ---- Clean Singularity cache (optional but good hygiene) ----
singularity cache clean -f

# ---- Directories ----
FASTA_DIR="/exports/igmm/eddie/VDA-lab/emily/projects/isgylation/fasta_files"
OUT_BASE="/exports/eddie/scratch/esouthwo/class_i/results"
WORK_DIR="/exports/eddie/scratch/esouthwo/work"
INPUT_TSV="/exports/igmm/eddie/VDA-lab/emily/projects/isgylation/immunopeptidomics/class_i/samplesheet.tsv"
CONFIG="eddie.config"

# ---- Loop over all FASTA proteomes ----
for fasta in "$FASTA_DIR"/*W-*.fasta; do
    # Get base filename without path or extension
    base=$(basename "$fasta" .fasta)

    # Define output directory
    outdir="${OUT_BASE}/${base}"

    echo "==============================="
    echo "Running MHCquant for $base"
    echo "FASTA: $fasta"
    echo "Output: $outdir"
    echo "==============================="
    outfile=$outdir/multiqc/multiqc_report.html
    if [ -f "$outfile" ]; then
        echo "Output already exists for $base — skipping."
        continue
    fi
    # Run the pipeline
    nextflow run nf-core/mhcquant -with-trace -r dev -resume \
        -c "$CONFIG" \
        -work-dir "$WORK_DIR" \
        --input "$INPUT_TSV" \
        --fasta "$fasta" \
        --outdir "$outdir" \
        --peptide_min_length 8 \
        --peptide_max_length 14 \
        --ms2pip_model 'timsTOF' \
        --feature_generators deeplc,ms2pip \
        --rescoring_engine percolator \
        --digest_mass_range '800:2500' \
        --activation_method CID \
        --prec_charge '1:4' \
        --fdr_threshold 0.01 \
        --fdr_level peptide_level_fdrs

    echo "Finished processing $base"
    echo
done
