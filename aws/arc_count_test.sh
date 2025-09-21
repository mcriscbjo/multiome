#!/usr/bin/env bash

#SBATCH --job-name=arc_count_test
#SBATCH --output=/mnt/efs/clusterfcs/data/fcs-mome-premic/logs/arc_count_test_%j.out
#SBATCH --error=/mnt/efs/clusterfcs/data/fcs-mome-premic/logs/arc_count_test_%j.err
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=0
#SBATCH --time=3-00:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=mccarbajo@fundacioncarlossimon.com
#SBATCH --partition=compute-128

# --------------Purpose-------------------------------------------------------------

#   Run Cell Ranger ARC "count" for one sample with secondary analyses enabled.
#   Suitable for 10x Multiome ATAC + GEX data.
#   Uses reference "refdata-cellranger-arc-GRCh38-2024-A".

# ---------------How to run---------------------------------------------------------

#   sbatch --export=ALL,ID=<BASE_SAMPLE_ID> arc_count_test.sh --comment <project>
#   If ID is not provided, the first entry in sample_ids.txt is used.

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

# Resolve sample ID

ID="${ID:-$(head -n1 "$IDS" 2>/dev/null || true)}"
[[ -n "${ID:-}" ]] || { echo "[FATAL] Missing sample ID (export ID=... or fill $IDS)"; exit 1; }

LIBS="$LIBDIR/${ID}_libraries.csv"
[[ -s "$LIBS" ]] || { echo "[FATAL] libraries.csv not found: $LIBS"; exit 2; }
[[ -d "$REF"   ]] || { echo "[FATAL] Reference not found: $REF"; exit 3; }

# Logging

SECONDS=0
echo "=== ARC single-sample (secondary ON) ====================================="
echo "Node:           ${SLURM_NODELIST:-<unknown>}"
echo "Cores:          ${SLURM_CPUS_PER_TASK:-16}"
echo "Sample ID:      ${ID}"
echo "Libraries CSV:  ${LIBS}"
echo "Reference:      ${REF}"
echo "Output root:    ${OUTDIR}"
echo "==========================================================================="

# Launch ARC

"$CELLARC" count \
  --id="$ID" \
  --reference="$REF" \
  --libraries="$LIBS" \
  --localcores="${SLURM_CPUS_PER_TASK}" \
  --disable-ui 
printf ">>> Completed %s in %dm %ds (secondary enabled)\n" "$ID" $((SECONDS/60)) $((SECONDS%60))
