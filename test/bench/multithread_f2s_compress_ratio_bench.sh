#!/bin/bash
#SBATCH --job-name=f2s_compress_ratio_benchmark
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=128
#SBATCH --mem=150G                 # 100G input + headroom
#SBATCH --time=24:00:00
#SBATCH --output=f2s_compress_ratio_benchmark_%j.out
#SBATCH --error=f2s_compress_ratio_benchmark_%j.err

set -x

DRY_RUN=0
if [ "$1" = "--dry-run" ] || [ "$1" = "-n" ]; then
    DRY_RUN=1
    set +x
    echo "=== DRY RUN — commands will be printed but not executed ==="
fi

THREADS=128

SIG_PRESS_LIST="ex-zd svb-zd"

# dataset_label:fast5_dir pairs
DATASETS=(
"d1_sars-cov-2_r94:/mnt/galactica/skuvalekar/genome_data/test/data/d1_sars-cov-2_r94"
"d2_ecoli_r94:/mnt/galactica/skuvalekar/genome_data/test/data/d2_ecoli_r94"
"d3_yeast_r94:/mnt/galactica/skuvalekar/genome_data/test/data/d3_yeast_r94"
"d4_green_algae_r94:/mnt/galactica/skuvalekar/genome_data/test/data/d4_green_algae_r94"
"d5_human_na12878_r94:/mnt/galactica/skuvalekar/genome_data/test/data/d5_human_na12878_r94"
"d6_ecoli_r104:/mnt/galactica/skuvalekar/genome_data/test/data/d6_ecoli_r104"
"d7_saureus_r104:/mnt/galactica/skuvalekar/genome_data/test/data/d7_saureus_r104"
)

SLOW5TOOLS=./slow5tools

run_bench() {
    local label=$1
    local fast5dir=$2
    local output_dir=./run_${label}/f2s_compress_ratio_benchmark

    if [ $DRY_RUN -eq 1 ]; then
        echo ""
        echo "=== Dataset: $label ($fast5dir) ==="
        echo "mkdir -p $output_dir"
        for sig_press in $SIG_PRESS_LIST; do
            echo "/usr/bin/time -v $SLOW5TOOLS f2s $fast5dir -p $THREADS --compress zlib -s $sig_press --bench --allow 2> $output_dir/$sig_press/timelog"
        done
        return 0
    fi

    mkdir -p $output_dir

    if [ ! -f $output_dir/results.txt ]; then
        echo -e "sig_press\traw_signal_bytes\tcompressed_bytes\tcompression_ratio" > $output_dir/results.txt
    fi

    for sig_press in $SIG_PRESS_LIST
    do
        local folder=$output_dir/$sig_press
        test -d $folder && rm -r $folder
        mkdir -p $folder

        /usr/bin/time -v $SLOW5TOOLS f2s \
            $fast5dir \
            -p $THREADS \
            --compress zlib \
            -s $sig_press \
            --bench \
            --allow \
            2> $folder/timelog

        local raw_signal compressed ratio
        raw_signal=$(grep '\[BENCH\]' $folder/timelog \
            | awk '{for(i=1;i<=NF;i++) if($i ~ /^raw_signal_bytes=/) {split($i,a,"="); sum+=a[2]}} END {print sum+0}')
        compressed=$(grep '\[BENCH\]' $folder/timelog \
            | awk '{for(i=1;i<=NF;i++) if($i ~ /^compressed_bytes=/) {split($i,a,"="); sum+=a[2]}} END {print sum+0}')
        ratio=$(awk "BEGIN {if ($compressed > 0) printf \"%.4f\", $raw_signal / $compressed; else print \"N/A\"}")

        echo -e "$sig_press\t$raw_signal\t$compressed\t$ratio" >> $output_dir/results.txt
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
