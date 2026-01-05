#!/bin/bash
#SBATCH --job-name=osu_allgather
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err
#SBATCH --ntasks=4
#SBATCH --nodes=1
#SBATCH --nodelist=node4
#SBATCH --partition=debug

# Path to OpenMPI
export PATH=/home/sumire/mpi-build/ompi-install/bin:$PATH
export LD_LIBRARY_PATH=/home/sumire/mpi-build/ompi-install/lib:$LD_LIBRARY_PATH

# Enable tuned collectives
export OMPI_MCA_coll_tuned_use_dynamic_rules=1
export OMPI_MCA_coll_yhccl_priority=100

# Run OSU allgather benchmark
mpirun /home/sumire/mpi-build/osu-micro-benchmarks-7.5.1/c/mpi/collective/blocking/osu_allreduce -m 1048576:1048576
