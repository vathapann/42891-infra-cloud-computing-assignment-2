#!/bin/sh
#
# loadgen.sh - CPU and memory load generator for the SmartV lab test VMs
#
# Runs on TinyCore (busybox ash) with no extra packages.
# Generates sustained CPU load and optionally holds memory, so that
# vSphere DRS sees a real imbalance and produces migration
# recommendations.
#
# Usage:
#   ./loadgen.sh [duration_seconds] [cpu_workers] [memory_mb]
#
# Examples:
#   ./loadgen.sh                 # 600s, 2 workers, no memory ballast
#   ./loadgen.sh 900 2 64        # 15 minutes, 2 workers, hold 64 MB
#   ./loadgen.sh 300 1 0         # 5 minutes, 1 worker, CPU only
#
# Stop early with Ctrl+C. Workers and the ballast file are cleaned up.

DURATION=${1:-600}
WORKERS=${2:-2}
MEM_MB=${3:-0}

BALLAST=/tmp/loadgen_ballast
PIDS=""

# ---------------------------------------------------------------
# Clean up on exit, whether the run finishes or is interrupted
# ---------------------------------------------------------------
cleanup() {
    echo ""
    echo "Stopping workers..."
    for pid in $PIDS; do
        kill "$pid" 2>/dev/null
    done
    rm -f "$BALLAST"
    echo "Cleaned up. Load stopped at $(date)"
    exit 0
}
trap cleanup INT TERM

# ---------------------------------------------------------------
# One CPU worker: a tight arithmetic loop, pure shell, no packages
# ---------------------------------------------------------------
burn_cpu() {
    i=0
    while :; do
        i=$((i + 1))
        # Occasional modulo keeps the loop from being optimised away
        # and stops the counter growing without bound.
        if [ $((i % 100000)) -eq 0 ]; then
            i=0
        fi
    done
}

# ---------------------------------------------------------------
# Memory ballast: TinyCore runs from a RAM disk, so a file written
# under /tmp consumes real guest memory.
# ---------------------------------------------------------------
hold_memory() {
    echo "Allocating ${MEM_MB} MB of memory ballast..."
    dd if=/dev/zero of="$BALLAST" bs=1M count="$MEM_MB" 2>/dev/null
    if [ -f "$BALLAST" ]; then
        echo "Ballast allocated at $BALLAST"
    else
        echo "WARNING: could not allocate ballast. Not enough free RAM?"
    fi
}

# ---------------------------------------------------------------
# Main
# ---------------------------------------------------------------
echo "================================================"
echo " SmartV load generator"
echo "================================================"
echo " Host VM   : $(hostname)"
echo " Started   : $(date)"
echo " Duration  : ${DURATION}s"
echo " CPU load  : ${WORKERS} worker(s)"
echo " Memory    : ${MEM_MB} MB ballast"
echo "================================================"
echo ""

if [ "$MEM_MB" -gt 0 ]; then
    hold_memory
fi

n=1
while [ "$n" -le "$WORKERS" ]; do
    burn_cpu &
    PIDS="$PIDS $!"
    echo "Started CPU worker $n (pid $!)"
    n=$((n + 1))
done

echo ""
echo "Load running. Watch DRS in the vSphere Client under"
echo "Monitor > vSphere DRS > Recommendations."
echo "Press Ctrl+C to stop early."
echo ""

# Count down so the console shows progress during a demo
remaining=$DURATION
while [ "$remaining" -gt 0 ]; do
    sleep 10
    remaining=$((remaining - 10))
    echo "  ... ${remaining}s remaining"
done

cleanup
