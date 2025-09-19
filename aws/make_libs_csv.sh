#!/usr/bin/env bash

#SBATCH --job-name=make_libs_csv
#SBATCH -output=/mnt/efs/clusterfcs/data/fcs-mome-premic/logs/make_libs_pref_%j.out
#SBATCH -error=/mnt/efs/clusterfcs/data/fcs-mome-premic/logs/make_libs_pref_%j.err
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8000
#SBATCH --time=01:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=mccarbajo@fundacioncarlossimon.com
#SBATCH -partition=compute-128
 
 
set -euo pipefail
 
# === PURPOSE ================================================================
# Build one libraries.csv per biological sample and a sample_ids.txt index.
# The 'sample' column is filled with the *exact FASTQ prefix*
# (everything before _S<d>_L<ddd>_), one line per unique prefix.
# This lets Cell Ranger ARC merge multiple prefixes/flowcells per library.
 
# ===================================================================

# Assignate paths
BASE="/mnt/efs/clusterfcs/data/fcs-mome-premic"
RNA_ROOT="$BASE/raw/rnaseq"
ATAC_ROOT="$BASE/raw/atac"
LIBDIR="$BASE/libraries"
IDS_FILE="$BASE/sample_ids.txt"
mkdir -p "$LIBDIR"
 

# Derive <BASE> from directory names
rna_base() {                # "<BASE>_GE" -> "<BASE>"
  local d; d="$(basename "$1")"
  echo "${d%_GE}"
}
atac_base() {               # "<BASE>_AT_<BASE>_AT" -> "<BASE>" (text before first _AT_)
  local d; d="$(basename "$1")"
  echo "${d%%_AT_*}"
}
 
# Extract FASTQ "prefix" = everything before _S## _L### _
# e.g., "EP_C40_GE-XYZ_22VTNHLT4_S9_L001_R1_001.fastq.gz"
#   -> "EP_C40_GE-XYZ_22VTNHLT4"
fastq_sample_prefix() {
  local f; f="$(basename "$1")"
  f="${f%.fastq.gz}"
  echo "$f" | sed -E 's/_S[0-9]+_L[0-9]{3}_.+$//'
}
 
# Index RNA/ATAC directories by base

declare -A RNA_DIRS ATAC_DIRS
shopt -s nullglob
 
for d in "$RNA_ROOT"/*/ ;  do
  RNA_DIRS["$(rna_base "$d")"]="${d%/}"
done
 
for d in "$ATAC_ROOT"/*/ ; do
  b="$(atac_base "$d")"
  # keep first occurrence if multiple directories match same base
  [[ -n "${ATAC_DIRS[$b]:-}" ]] || ATAC_DIRS["$b"]="${d%/}"
done
 
echo ">> RNA dirs: ${#RNA_DIRS[@]} | ATAC dirs: ${#ATAC_DIRS[@]}"
 
# Build CSVs

: > "$IDS_FILE"      # truncate index file
count=0
 
for base in "${!RNA_DIRS[@]}"; do
  # skip if ATAC missing for this base
  [[ -n "${ATAC_DIRS[$base]:-}" ]] || { echo "!! Missing ATAC for $base" >&2; continue; }
 
  rdir="${RNA_DIRS[$base]}"
  adir="${ATAC_DIRS[$base]}"
 
  # quick existence checks (avoid empty CSVs)
  compgen -G "$rdir/*.fastq.gz" > /dev/null || { echo "!! [RNA] no FASTQ in $rdir — skip $base" >&2; continue; }
  compgen -G "$adir/*.fastq.gz" > /dev/null || { echo "!! [ATAC] no FASTQ in $adir — skip $base" >&2; continue; }
 
  # collect unique prefixes per library (RNA / ATAC)
  declare -A seen_rna=() seen_atac=()
  rna_samples=()
  atac_samples=()
 
  # RNA prefixes
  for fq in "$rdir"/*.fastq.gz; do
    p="$(fastq_sample_prefix "$fq")"
    [[ -n "${seen_rna[$p]:-}" ]] || { seen_rna["$p"]=1; rna_samples+=("$p"); }
  done
  # ATAC prefixes
  for fq in "$adir"/*.fastq.gz; do
    p="$(fastq_sample_prefix "$fq")"
    [[ -n "${seen_atac[$p]:-}" ]] || { seen_atac["$p"]=1; atac_samples+=("$p"); }
  done
 
  # sanity: at least one prefix per library
  (( ${#rna_samples[@]} ))  || { echo "!! [RNA] no prefixes in $rdir — skip $base" >&2; continue; }
  (( ${#atac_samples[@]} )) || { echo "!! [ATAC] no prefixes in $adir — skip $base" >&2; continue; }
 
  # write libraries.csv
  csv="$LIBDIR/${base}_libraries.csv"
  {
    echo "fastqs,sample,library_type"
    # one line per RNA prefix (merged as one GEX library by ARC)
    for s in "${rna_samples[@]}";  do echo "$rdir,$s,Gene Expression"; done
    # one line per ATAC prefix (merged as one ATAC library by ARC)
    for s in "${atac_samples[@]}"; do echo "$adir,$s,Chromatin Accessibility"; done
  } > "$csv"
 
  # append base to sample_ids.txt (used by the array job)
  echo "$base" >> "$IDS_FILE"
 
  ((count++)) || true
  echo "OK: $csv  (GEX prefixes: ${#rna_samples[@]} | ATAC prefixes: ${#atac_samples[@]})"
done