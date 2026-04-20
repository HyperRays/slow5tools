#!/bin/bash
#SBATCH --job-name=f2s_decompress_benchmark
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=31
#SBATCH --mem=100G                 # 50G input + headroom
#SBATCH --time=24:00:00
#SBATCH --output=f2s_decompress_benchmark_%j.out
#SBATCH --error=f2s_decompress_benchmark_%j.err
#SBATCH --partition=bio_part

set -x

DRY_RUN=0
if [ "$1" = "--dry-run" ] || [ "$1" = "-n" ]; then
    DRY_RUN=1
    set +x
    echo "=== DRY RUN — commands will be printed but not executed ==="
fi

# THREAD_LIST="1 2 4 8 16 32 64 128 256"
THREAD_LIST="32 16"
# THREAD_LIST="128 256"

SIG_PRESS_LIST="ex-zd svb-zd"

# dataset_label:fast5_dir pairs
DATASETS=(
    "d4_green_algae_r94:/mnt/nvme1/soysalm/d4_green_algae_r94/fast5_files/"
    "d3_yeast_r94:/mnt/nvme1/soysalm/d3_yeast_r94/fast5_files/"
)

SLOW5TOOLS=./slow5tools

run_bench() {
    local label=$1
    local fast5dir=$2
    local output_dir=./run_${label}/f2s_decompress_thread_benchmark

    if [ $DRY_RUN -eq 1 ]; then
        echo ""
        echo "=== Dataset: $label ($fast5dir) ==="
        echo "mkdir -p $output_dir"
        echo "find $fast5dir -name '*.fast5' | xargs du -sb | awk '{sum+=\$1} END {print sum}'"
        for sig_press in $SIG_PRESS_LIST; do
            for num in $THREAD_LIST; do
                echo "/usr/bin/time -v $SLOW5TOOLS f2s $fast5dir -p $num --compress zlib -s $sig_press --bench-decompress --allow 2> $output_dir/$sig_press/$num/timelog"
            done
        done
        return 0
    fi

    mkdir -p $output_dir

    local input_bytes
    input_bytes=$(find $fast5dir -name "*.fast5" | xargs du -sb | awk '{sum+=$1} END {print sum}')
    echo "[$label] Total input size: $input_bytes bytes"

    if [ ! -f $output_dir/results.txt ]; then
        echo -e "sig_press\tthreads\twall_time_hrs\tcpu_usage\tinput_bytes\traw_signal_bytes\tdecompress_throughput_MB_s" > $output_dir/results.txt
    fi

    for sig_press in $SIG_PRESS_LIST
    do
        for num in $THREAD_LIST
        do
            local folder=$output_dir/$sig_press/$num
            test -d $folder && rm -r $folder
            mkdir -p $folder

            # Decompress-only bench: compression still happens (required to produce data
            # to decompress) but its timing is skipped. Only decompression is profiled.
            /usr/bin/time -v $SLOW5TOOLS f2s \
                $fast5dir \
                -p $num \
                --compress zlib \
                -s $sig_press \
                --bench-decompress \
                --allow \
                2> $folder/timelog

            local wall cpu raw_signal decompress_sec decompress_tp
            wall=$(grep "Elapsed (wall clock) time" $folder/timelog \
                | awk '{t=$NF; n=split(t,a,":"); if(n==2) print (a[1]*60+a[2])/3600; else print (a[1]*3600+a[2]*60+a[3])/3600}')
            cpu=$(grep "Percent of CPU this job got" $folder/timelog \
                | awk '{print $NF}')

            raw_signal=$(grep '\[BENCH\]' $folder/timelog \
                | awk '{for(i=1;i<=NF;i++) if($i ~ /^raw_signal_bytes=/) {split($i,a,"="); sum+=a[2]}} END {print sum+0}')
            decompress_sec=$(grep '\[BENCH\]' $folder/timelog \
                | awk '{for(i=1;i<=NF;i++) if($i ~ /^decompress_sec=/) {split($i,a,"="); sum+=a[2]}} END {printf "%.6f", sum+0}')
            decompress_tp=$(awk "BEGIN {if ($decompress_sec > 0) printf \"%.2f\", ($raw_signal * $num / 1000000) / $decompress_sec; else print \"N/A\"}")

            echo -e "$sig_press\t$num\t$wall\t$cpu\t$input_bytes\t$raw_signal\t$decompress_tp" >> $output_dir/results.txt
        done
    done

    echo ""
    echo "=== [$label] Results ==="
    cat $output_dir/results.txt

    cp -r $output_dir ${output_dir}_bak
}

for entry in "${DATASETS[@]}"; do
    label="${entry%%:*}"
    dir="${entry#*:}"
    run_bench "$label" "$dir"
done
