#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=10
#SBATCH --mem=32g
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=simmo536@umn.edu
#SBATCH -p amdsmall
#SBATCH -o %A.out
#SBATCH -e %A.err

cd ~/2023-NSF_CPS-wavePoweredRO
module load matlab
matlab -nodisplay -r \
"addpath('Utilities'); \
startParPool(${SLURM_JOB_CPUS_PER_NODE}); \
study_refPTO_checkValves"

# Commands to use
# sbatch ~/2023-NSF_CPS-wavePoweredRO/study_refPTO_checkValves.sh
# dos2unix  study_refPTO_checkValves.sh

