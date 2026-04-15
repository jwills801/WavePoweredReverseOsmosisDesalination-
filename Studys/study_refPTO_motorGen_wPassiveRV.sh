#!/bin/bash -l
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --mem=16gb
#SBATCH -t 8:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=simmo536@umn.edu
#SBATCH -p small
#SBATCH -o %A_%a.out
#SBATCH -e %A_%a.err

cd ~/2023-NSF_CPS-wavePoweredRO
module load matlab
matlab -nodisplay -r \
"iVar = ${SLURM_ARRAY_TASK_ID}; \
SS = $SS; \
study_refPTO_motorGen_wPassiveRV"

# Commands to use
# sbatch --export=SS=1 --array=1-15 ~/2023-NSF_CPS-wavePoweredRO/study_refPTO_motorGen_wPassiveRV.sh
# dos2unix  study_refPTO_accum_woRV.sh

