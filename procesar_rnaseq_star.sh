#!/bin/bash

# Configuración de rutas
BASE_DIR="/mnt/DATA"
FASTQ_DIR="$BASE_DIR/fastq_files"
QC_OUTPUT_DIR="$BASE_DIR/fastqc_output"
STAR_OUTPUT_DIR="$BASE_DIR/star_output"
GENOME_DIR="$BASE_DIR/GRCh38/index_rnaseq_75bp"
GENOME_FASTA="$BASE_DIR/GRCh38/Homo_sapiens.GRCh38.dna.primary_assembly.fa"
GTF_FILE="$BASE_DIR/GRCh38/Homo_sapiens.GRCh38.109.gtf"
CSV_FILE="$BASE_DIR/muestras/muestras.csv"

#Configuración de PATH y espacio de trabajo

# Leer el archivo CSV para hacer el alineamiento
while IFS=',' read -r MUESTRA LANE1 LANE2 LANE3 LANE4
do
  # Saltar la primera línea del CSV si contiene encabezados
  if [[ "$MUESTRA" == "muestra" ]]; then
    continue
  fi

  # Alinear las lecturas combinadas con STAR y guardar no alineadas en el mismo .bam
  echo "Alineando las lecturas de la muestra $MUESTRA con STAR..."
  STAR --runThreadN 15 \
       --genomeDir $GENOME_DIR \
       --readFilesIn ${FASTQ_DIR}/${MUESTRA}_combined_R1.fastq ${FASTQ_DIR}/${MUESTRA}_combined_R2.fastq \
       --outFileNamePrefix ${STAR_OUTPUT_DIR}/${MUESTRA}_ \
       --outSAMtype BAM SortedByCoordinate \
       --outSAMunmapped Within
    
    #valores predeterminados: si no indico nada, se tomará como:
    ##--seedSearchStartLmax: 50
    ##--outFilterScoreMinOverLread: 0.66
    ##--outFilterMatchNminOverLread: 0.66
done < $CSV_FILE

echo "Proceso completado. Todos los análisis han terminado."


echo "
████████████████████████████████████████
████████████████████████████████████████
██████▀░░░░░░░░▀████████▀▀░░░░░░░▀██████
████▀░░░░░░░░░░░░▀████▀░░░░░░░░░░░░▀████
██▀░░░░░░░░░░░░░░░░▀▀░░░░░░░░░░░░░░░░▀██
██░░░░░░░░░░░░░░░░░░░▄▄░░░░░░░░░░░░░░░██
██░░░░░░░░░░░░░░░░░░█░█░░░░░░░░░░░░░░░██
██░░░░░░░░░░░░░░░░░▄▀░█░░░░░░░░░░░░░░░██
██░░░░░░░░░░████▄▄▄▀░░▀▀▀▀▄░░░░░░░░░░░██
██▄░░░░░░░░░████░░░░░░░░░░█░░░░░░░░░░▄██
████▄░░░░░░░████░░░░░░░░░░█░░░░░░░░▄████
██████▄░░░░░████▄▄▄░░░░░░░█░░░░░░▄██████
████████▄░░░▀▀▀▀░░░▀▀▀▀▀▀▀░░░░░▄████████
██████████▄░░░░░░░░░░░░░░░░░░▄██████████
████████████▄░░░░░░░░░░░░░░▄████████████
██████████████▄░░░░░░░░░░▄██████████████
████████████████▄░░░░░░▄████████████████
██████████████████▄▄▄▄██████████████████
████████████████████████████████████████
████████████████████████████████████████
"