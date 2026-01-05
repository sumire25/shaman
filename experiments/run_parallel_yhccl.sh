#!/bin/bash
# Script to run two YHCCL allreduce experiments in parallel
# Registers all components once, then runs optimizers in parallel
# Node1: 4 tasks, Node3: 8 tasks

set -e

cd /home/sumire/shaman
source /home/sumire/miniconda3/bin/activate shaman38
source shaman.env

# Clean up any old slurm files
rm -f slurm-*.out slurm-*.err
rm -f experiments/osu_allreduce_node1/slurm_outputs/slurm-*.out experiments/osu_allreduce_node1/slurm_outputs/slurm-*.err
rm -f experiments/osu_allreduce_node3/slurm_outputs/slurm-*.out experiments/osu_allreduce_node3/slurm_outputs/slurm-*.err

echo "=========================================="
echo "Registering all components..."
echo "=========================================="
shaman-install experiments/osu_allreduce_both_components.yaml
echo "Components registered!"

echo ""
echo "=========================================="
echo "Launching parallel experiments..."
echo "=========================================="

# Launch node1 experiment in background (from its own directory)
echo "Starting Node1 experiment (4 tasks)..."
(
  cd /home/sumire/shaman/experiments/osu_allreduce_node1
  shaman-optimize \
    --component-name yhccl_allreduce_node1 \
    --nbr-iteration 40 \
    --sbatch-file osu_allreduce.sbatch \
    --experiment-name YHCCL_NODE1_FULL \
    --configuration-file osu_experiment.yaml \
    --slurm-dir slurm_outputs \
    --sbatch-dir . \
    --result-file results_full.out \
    2>&1 | tee optimization_full.log
) &
PID_NODE1=$!

# Launch node3 experiment in background (from its own directory)
echo "Starting Node3 experiment (8 tasks)..."
(
  cd /home/sumire/shaman/experiments/osu_allreduce_node3
  shaman-optimize \
    --component-name yhccl_allreduce_node3 \
    --nbr-iteration 40 \
    --sbatch-file osu_allreduce.sbatch \
    --experiment-name YHCCL_NODE3_FULL \
    --configuration-file osu_experiment.yaml \
    --slurm-dir slurm_outputs \
    --sbatch-dir . \
    --result-file results_full.out \
    2>&1 | tee optimization_full.log
) &
PID_NODE3=$!

echo ""
echo "Experiments running in parallel:"
echo "  Node1 PID: $PID_NODE1 (4 tasks)"
echo "  Node3 PID: $PID_NODE3 (8 tasks)"
echo ""
echo "Waiting for all experiments to complete..."

# Wait for all experiments
wait $PID_NODE1
EXIT_NODE1=$?
echo "Node1 experiment completed with exit code: $EXIT_NODE1"

wait $PID_NODE3
EXIT_NODE3=$?
echo "Node3 experiment completed with exit code: $EXIT_NODE3"

echo ""
echo "=========================================="
echo "All experiments completed!"
echo "=========================================="

# Extract best job IDs from logs
echo ""
echo "Extracting best configurations..."

# For Node1: find the job ID with the best (minimum) fitness
BEST_NODE1=$(grep "update_history" experiments/osu_allreduce_node1/optimization_full.log | \
  grep -oP "'jobids': \d+.*?'fitness': [\d.]+" | \
  while read line; do
    jobid=$(echo "$line" | grep -oP "(?<='jobids': )\d+")
    fitness=$(echo "$line" | grep -oP "(?<='fitness': )[\d.]+")
    echo "$fitness $jobid"
  done | sort -n | head -1)
BEST_FITNESS_NODE1=$(echo "$BEST_NODE1" | awk '{print $1}')
BEST_JOBID_NODE1=$(echo "$BEST_NODE1" | awk '{print $2}')

# For Node3: find the job ID with the best (minimum) fitness
BEST_NODE3=$(grep "update_history" experiments/osu_allreduce_node3/optimization_full.log | \
  grep -oP "'jobids': \d+.*?'fitness': [\d.]+" | \
  while read line; do
    jobid=$(echo "$line" | grep -oP "(?<='jobids': )\d+")
    fitness=$(echo "$line" | grep -oP "(?<='fitness': )[\d.]+")
    echo "$fitness $jobid"
  done | sort -n | head -1)
BEST_FITNESS_NODE3=$(echo "$BEST_NODE3" | awk '{print $1}')
BEST_JOBID_NODE3=$(echo "$BEST_NODE3" | awk '{print $2}')

echo ""
echo "Results:"
echo "  Node1 (4 tasks): experiments/osu_allreduce_node1/results_full.out"
echo "                   Best Job ID: $BEST_JOBID_NODE1 (fitness: $BEST_FITNESS_NODE1)"
echo "  Node3 (8 tasks): experiments/osu_allreduce_node3/results_full.out"
echo "                   Best Job ID: $BEST_JOBID_NODE3 (fitness: $BEST_FITNESS_NODE3)"
echo ""
echo "Logs:"
echo "  Node1: experiments/osu_allreduce_node1/optimization_full.log"
echo "  Node3: experiments/osu_allreduce_node3/optimization_full.log"
echo ""
echo "Best Slurm outputs:"
echo "  Node1: experiments/osu_allreduce_node1/slurm_outputs/slurm-${BEST_JOBID_NODE1}.out"
echo "  Node3: experiments/osu_allreduce_node3/slurm_outputs/slurm-${BEST_JOBID_NODE3}.out"
