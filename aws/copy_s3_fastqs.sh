#!/usr/bin/env bash
#SBATCH --job-name=copy_s3_fastqs
#SBATCH --output=/mnt/efs/clusterfcs/data/fcs-mome-premic/logs/copy_arc_%j.out
#SBATCH --error=copy_s3_fastqs_%j.err
#SBATCH --nodes=1
#SBATCH --cpus-per-task 16
#SBATCH --time=12:00:00
#SBATCH --mail-user= mccarbajo@fundacioncarlossimon.com
#SBATCH --mail-type=END,FAIL
#SBATCH --partition=file-transfer
 
set -euo pipefail

# Input Variables from arguments

DEST="/mnt/efs/clusterfcs/data/fcs-mome-premic"
ATAC_S3="s3://fcs-mome-pe/raw/atac/X204SC25068713-Z01-F002/01.RawData/"
GEX_S3="s3://fcs-mome-pe/raw/rnaseq/X204SC25068713-Z01-F001/01.RawData/"
 
# Create destination directories

mkdir -p "$DEST/raw/atac" "$DEST/raw/rnaseq" "$DEST/logs"
 
# Copy data from S3 to local destination

echo ">> Copy ATAC"
aws s3 cp "$ATAC_S3" "$DEST/raw/atac/" \
  --recursive --only-show-errors --no-progress --exclude "*Undetermined*"
 
echo ">> Copy GEX"
aws s3 cp "$GEX_S3" "$DEST/raw/rnaseq/" \
  --recursive --only-show-errors --no-progress --exclude "*Undetermined*"
 
echo ">> Done. Tamaños:"
du -sh "$DEST/raw/atac" "$DEST/raw/rnaseq" || true