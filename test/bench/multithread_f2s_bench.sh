#!/bin/bash
#SBATCH --job-name=f2s_benchmark
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=100G                 # 50G input + headroom
#SBATCH --time=24:00:00
#SBATCH --output=f2s_benchmark_%j.out
#SBATCH --error=f2s_benchmark_%j.err
#SBATCH --partition=bio_part

set -x

DRY_RUN=0
if [ "$1" = "--dry-run" ] || [ "$1" = "-n" ]; then
    DRY_RUN=1
    set +x
    echo "=== DRY RUN — commands will be printed but not executed ==="
fi

# THREAD_LIST="1 2 4 8 16 32 64 128 256"
THREAD_LIST="64 32 16"
# THREAD_LIST="128 256"

FAST5DIR=/mnt/nvme1/soysalm/d3_yeast_r94/multi_fast5_files
OUTPUT_DIR=./run_d3_yeast_r94/f2s_thread_benchmark
SLOW5TOOLS=./slow5tools

if [ $DRY_RUN -eq 1 ]; then
    echo ""
    echo "mkdir -p $OUTPUT_DIR"
    echo "find $FAST5DIR -name '*.fast5' | xargs du -sb | awk '{sum+=\$1} END {print sum}'"
    echo ""
    for num in $THREAD_LIST; do
        echo "/usr/bin/time -v $SLOW5TOOLS f2s $FAST5DIR -p $num --compress zlib --bench 2> $OUTPUT_DIR/$num/timelog"
    done
    return 0 2>/dev/null || exit 0
fi

mkdir -p $OUTPUT_DIR

# Get total input size once
INPUT_BYTES=$(find $FAST5DIR -name "*.fast5" | xargs du -sb | awk '{sum+=$1} END {print sum}')
echo "Total input size: $INPUT_BYTES bytes"

if [ ! -f $OUTPUT_DIR/results.txt ]; then
    echo -e "threads\twall_time_hrs\tcpu_usage\tinput_bytes\traw_signal_bytes\tcompressed_bytes\tcompress_ratio\tthroughput_MB_s" > $OUTPUT_DIR/results.txt
fi

for num in $THREAD_LIST
do
    folder=$OUTPUT_DIR/$num
    test -d $folder && rm -r $folder
    mkdir -p $folder

    # Bench mode: conversion + compression without file I/O
    /usr/bin/time -v $SLOW5TOOLS f2s \
        $FAST5DIR \
        -p $num \
        --compress zlib \
        --bench \
        --allow \
        2> $folder/timelog

    wall=$(grep "Elapsed (wall clock) time" $folder/timelog \
        | awk '{t=$NF; n=split(t,a,":"); if(n==2) print (a[1]*60+a[2])/3600; else print (a[1]*3600+a[2]*60+a[3])/3600}')
    cpu=$(grep "Percent of CPU this job got" $folder/timelog \
        | awk '{print $NF}')

    # Sum compressed and raw signal bytes from all child processes
    compressed=$(grep '\[BENCH\]' $folder/timelog \
        | awk '{for(i=1;i<=NF;i++) if($i ~ /^compressed_bytes=/) {split($i,a,"="); sum+=a[2]}} END {print sum+0}')
    raw_signal=$(grep '\[BENCH\]' $folder/timelog \
        | awk '{for(i=1;i<=NF;i++) if($i ~ /^raw_signal_bytes=/) {split($i,a,"="); sum+=a[2]}} END {print sum+0}')
    ratio=$(awk "BEGIN {if ($compressed > 0) printf \"%.2f\", $raw_signal / $compressed; else print \"N/A\"}")
    throughput=$(awk "BEGIN {printf \"%.2f\", ($raw_signal / 1000000) / ($wall * 3600)}")

    echo -e "$num\t$wall\t$cpu\t$INPUT_BYTES\t$raw_signal\t$compressed\t$ratio\t$throughput" >> $OUTPUT_DIR/results.txt
done

echo ""
echo "=== Results ==="
cat $OUTPUT_DIR/results.txt

cp -r run_d4_green_algae_r94/f2s_thread_benchmark run_d4_green_algae_r94/f2s_thread_benchmark_bak
