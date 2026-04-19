#!/bin/bash
#SBATCH --job-name=f2s_perf
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=31
#SBATCH --mem=100G
#SBATCH --time=24:00:00
#SBATCH --output=f2s_perf_%j.out
#SBATCH --error=f2s_perf_%j.err
#SBATCH --partition=bio_part
#SBATCH --exclusive

set -x

DRY_RUN=0
if [ "$1" = "--dry-run" ] || [ "$1" = "-n" ]; then
    DRY_RUN=1
    set +x
    echo "=== DRY RUN — commands will be printed but not executed ==="
fi

THREAD_LIST="32"

FAST5DIR=/mnt/nvme1/soysalm/d4_green_algae_r94/fast5_files/
OUTPUT_DIR=./run_d4_green_algae_r94/f2s_perf
SLOW5TOOLS=./slow5tools

# FlameGraph scripts (only needed for the optional SVG output):
#   git clone https://github.com/brendangregg/FlameGraph ~/FlameGraph
FLAMEGRAPH_DIR=${FLAMEGRAPH_DIR:-$HOME/FlameGraph}

if ! command -v perf >/dev/null 2>&1; then
    echo "ERROR: perf not found. Load the linux-tools / perf module." >&2
    exit 1
fi

if [ $DRY_RUN -eq 1 ]; then
    echo ""
    echo "mkdir -p $OUTPUT_DIR"
    for num in $THREAD_LIST; do
        echo "perf record -F 99 -g --call-graph dwarf -o $OUTPUT_DIR/$num/perf.data -- \\"
        echo "    $SLOW5TOOLS f2s $FAST5DIR -p $num --compress zlib --bench --allow"
        echo "perf script -i $OUTPUT_DIR/$num/perf.data | \\"
        echo "    $FLAMEGRAPH_DIR/stackcollapse-perf.pl > $OUTPUT_DIR/$num/out.folded"
        echo "# Upload out.folded to https://www.speedscope.app"
    done
    return 0 2>/dev/null || exit 0
fi

mkdir -p "$OUTPUT_DIR"

for num in $THREAD_LIST
do
    folder="$OUTPUT_DIR/$num"
    rm -rf "$folder"
    mkdir -p "$folder"

    # 1. Record with DWARF call graphs.
    perf record \
        -F 99 \
        -g --call-graph dwarf \
        -o "$folder/perf.data" \
        -- $SLOW5TOOLS f2s \
            "$FAST5DIR" \
            -p "$num" \
            --compress zlib \
            --bench \
            --allow

    # 2. Decode samples.
    perf script -i "$folder/perf.data" > "$folder/perf.script"

    # 3. Collapse stacks — this is the file speedscope wants.
    if [ -x "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" ]; then
        "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" "$folder/perf.script" > "$folder/out.folded"
    else
        echo "WARN: stackcollapse-perf.pl not found at $FLAMEGRAPH_DIR" >&2
        echo "      clone https://github.com/brendangregg/FlameGraph to produce out.folded" >&2
    fi

    # 4. Optional: also render a self-contained SVG flamegraph.
    if [ -x "$FLAMEGRAPH_DIR/flamegraph.pl" ] && [ -s "$folder/out.folded" ]; then
        "$FLAMEGRAPH_DIR/flamegraph.pl" \
            --title "slow5tools f2s ($num threads)" \
            --width 1600 \
            "$folder/out.folded" > "$folder/flame.svg"
    fi

    echo "Speedscope input: $folder/out.folded"
    [ -f "$folder/flame.svg" ] && echo "SVG flamegraph:  $folder/flame.svg"
done

echo ""
echo "=== Done ==="
echo "Copy out.folded to your Mac, open https://www.speedscope.app, and drag the file in."
echo "(Data stays in your browser — speedscope is a static site, nothing is uploaded.)"