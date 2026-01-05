#!/bin/bash
# Script to run two SHAMAN experiments in parallel on different nodes

cd /home/sumire/shaman
source /home/sumire/miniconda3/bin/activate shaman38
source shaman.env

# Clean up any leftover slurm files
rm -f slurm-*.out slurm-*.err

echo "=========================================="
echo "Starting parallel experiments on node3 and node4"
echo "=========================================="

# Launch experiment on node3 in background
echo "[$(date)] Starting experiment on NODE3..."
shaman-optimize \
  --component-name openmpi_allgather \
  --nbr-iteration 20 \
  --sbatch-file experiments/osu_allgather/osu_allgather_node3.sbatch \
  --experiment-name OSU_ALLGATHER_NODE3 \
  --configuration-file experiments/osu_allgather/osu_experiment.yaml \
  --slurm-dir experiments/osu_allgather/slurm_outputs_node3 \
  --sbatch-dir experiments/osu_allgather/sbatch_files_node3 \
  --result-file experiments/osu_allgather/results_node3.out \
  > experiments/osu_allgather/experiment_node3.log 2>&1 &

PID_NODE3=$!
echo "  Node3 experiment PID: $PID_NODE3"

# Launch experiment on node4 in background
echo "[$(date)] Starting experiment on NODE4..."
shaman-optimize \
  --component-name openmpi_allgather \
  --nbr-iteration 20 \
  --sbatch-file experiments/osu_allgather/osu_allgather_node4.sbatch \
  --experiment-name OSU_ALLGATHER_NODE4 \
  --configuration-file experiments/osu_allgather/osu_experiment.yaml \
  --slurm-dir experiments/osu_allgather/slurm_outputs_node4 \
  --sbatch-dir experiments/osu_allgather/sbatch_files_node4 \
  --result-file experiments/osu_allgather/results_node4.out \
  > experiments/osu_allgather/experiment_node4.log 2>&1 &

PID_NODE4=$!
echo "  Node4 experiment PID: $PID_NODE4"

echo ""
echo "Both experiments running in parallel!"
echo "Monitor progress with:"
echo "  tail -f experiments/osu_allgather/experiment_node3.log"
echo "  tail -f experiments/osu_allgather/experiment_node4.log"
echo ""

# Wait for both to complete
echo "Waiting for experiments to complete..."
wait $PID_NODE3
EXIT_NODE3=$?
echo "[$(date)] Node3 experiment finished with exit code: $EXIT_NODE3"

wait $PID_NODE4
EXIT_NODE4=$?
echo "[$(date)] Node4 experiment finished with exit code: $EXIT_NODE4"

echo ""
echo "=========================================="
echo "Both experiments completed!"
echo "=========================================="
echo "Results:"
echo "  Node3: experiments/osu_allgather/results_node3.out"
echo "  Node4: experiments/osu_allgather/results_node4.out"
