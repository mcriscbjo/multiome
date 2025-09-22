#!/usr/bin/env bash

#SBATCH --job-name=arc_count
#SBATCH --output=/mnt/efs/clusterfcs/data/fcs-mome-premic/logs/arc_count_%j.out
#SBATCH --error=/mnt/efs/clusterfcs/data/fcs-mome-premic/logs/arc_count_%j.err
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=0
#SBATCH --time=3-00:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=mccarbajo@fundacioncarlossimon.com
#SBATCH --partition=compute-128

# --------------Purpose-------------------------------------------------------------

#   Run Cell Ranger ARC "count" for many samples via SLURM array.
#   Each array task processes one sample from sample_ids.txt.

# ---------------How to run---------------------------------------------------------

#   N=$(wc -l < /mnt/efs/clusterfcs/data/fcs-mome-premic/sample_ids.txt)
#   sbatch --array=0-$((N-1))%25 arc_count_array.sh

# ----------------------------------------------------------------------------------

set -euo pipefail

# Environment: call ARC with absolute path

CELLARC="/mnt/efs/clusterfcs/apps/cellranger-arc-2.0.2/bin/cellranger-arc"
[[ -x "$CELLARC" ]] || { echo "[FATAL] Not executable: $CELLARC"; exit 4; }

# Paths

BASE="/mnt/efs/clusterfcs/data/fcs-mome-premic"
REF="/mnt/efs/clusterfcs/utilities/genomes/refdata-cellranger-arc-GRCh38-2024-A"
LIBDIR="$BASE/libraries"
OUTDIR="$BASE/arc_count_out"
IDS="$BASE/sample_ids.txt"

mkdir -p "$OUTDIR"

# Resolve sample by array index (0-based -> 1-based sed)

ID="$(sed -n "$((SLURM_ARRAY_TASK_ID+1))p" "$IDS" || true)"
[[ -n "${ID:-}" ]] || { echo "[FATAL] Empty ID for index ${SLURM_ARRAY_TASK_ID}"; exit 1; }
LIBS="$LIBDIR/${ID}_libraries.csv"
[[ -s "$LIBS" ]] || { echo "[FATAL] libraries.csv not found: $LIBS"; exit 2; }
[[ -d "$REF"   ]] || { echo "[FATAL] Reference not found: $REF"; exit 3; }

# Logging

echo "=== ARC array task (secondary ON) ========================================"
echo "Task index:     ${SLURM_ARRAY_TASK_ID}"
echo "Node:           ${SLURM_NODELIST:-<unknown>}"
echo "Cores:          ${SLURM_CPUS_PER_TASK:-16}"
echo "Sample ID:      ${ID}"
echo "Libraries CSV:  ${LIBS}"
echo "Reference:      ${REF}"
echo "Output root:    ${OUTDIR}"
echo "==========================================================================="

# Launch ARC 

cd "$OUTDIR"
"$CELLARC" count \
  --id="$ID" \
  --reference="$REF" \
  --libraries="$LIBS" \
  --localcores="${SLURM_CPUS_PER_TASK}" \
  --disable-ui

echo "=== Done ==================================================================="