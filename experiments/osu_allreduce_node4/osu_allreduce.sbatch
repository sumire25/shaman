#!/bin/bash
#SBATCH --job-name=osu_allreduce_node4
#SBATCH --output=/home/sumire/shaman/experiments/osu_allreduce_node4/slurm_outputs/slurm-%j.out
#SBATCH --error=/home/sumire/shaman/experiments/osu_allreduce_node4/slurm_outputs/slurm-%j.err
#SBATCH --ntasks=16
#SBATCH --nodes=1
#SBATCH --nodelist=node4
#SBATCH --partition=debug

# Enable tuned collectives
export OMPI_MCA_coll_tuned_use_dynamic_rules=1
export OMPI_MCA_coll_yhccl_priority=100

# OSU Allreduce benchmark with YHCCL optimization - Node4
# Full message size range: 64KB to 256MB

srun --mpi=pmi2 /home/sumire/mpi-build/osu-micro-benchmarks-7.5.1/c/mpi/collective/blocking/osu_allreduce -m 65536:268435456
