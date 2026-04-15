#!/bin/bash
#SBATCH --job-name=f2s_benchmark
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=256
#SBATCH --mem=200G                 # 50G input + headroom
#SBATCH --time=24:00:00
#SBATCH --output=f2s_benchmark_%j.out
#SBATCH --error=f2s_benchmark_%j.err
#SBATCH --partition=bio_part

set -x

THREAD_LIST="1 2 4 8 16 32 64 128 256"

FAST5DIR=/mnt/nvme1/soysalm/d4_green_algae_r94/fast5_files/
OUTPUT_DIR=f2s_thread_benchmark
SLOW5TOOLS=slow5tools

mkdir -p $OUTPUT_DIR

# Get total input size once
INPUT_BYTES=$(find $FAST5DIR -name "*.fast5" | xargs du -sb | awk '{sum+=$1} END {print sum}')
echo "Total input size: $INPUT_BYTES bytes"

echo -e "threads\twall_time_hrs\tcpu_usage\tinput_bytes" > $OUTPUT_DIR/results.txt

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
        2> $folder/timelog

    wall=$(grep "Elapsed (wall clock) time" $folder/timelog \
        | awk '{t=$NF; n=split(t,a,":"); if(n==2) print (a[1]*60+a[2])/3600; else print (a[1]*3600+a[2]*60+a[3])/3600}')
    cpu=$(grep "Percent of CPU this job got" $folder/timelog \
        | awk '{print $NF}')

    echo -e "$num\t$wall\t$cpu\t$INPUT_BYTES" >> $OUTPUT_DIR/results.txt
done

echo ""
echo "=== Results ==="
cat $OUTPUT_DIR/results.txt
