#!/bin/bash

software=${software}
dir_path=${dir_path}
bbduck_adapter=${bbduck_adapter}
sample_name_list=${sample_name_list}
ppn=${ppn}
num_jobs=${num_jobs}

#### !!!!!!!!!!!!!!!!!!!!!!
#### (optional) change ppn for the number of processer per node based on needs
#### !!!!!!!!!!!!!!!!!!!!!!

STEP1_TRIMMING_JOB_ARR=$(qsub -q condo -N trim -l nodes=1:ppn=${ppn},walltime=8:00:00 -t 1-${num_jobs} \
                           -j oe -k oe \
                           -V -v ppn="${ppn}",software="${software}",dir_path="${dir_path}",bbduck_adapter="${bbduck_adapter}",sample_name_list="${sample_name_list}" \
                           ${code}/genotyping/step1_trimming.sh)
echo "step1_trimming: ${STEP1_TRIMMING_JOB_ARR}"
STEP1_TRIMMING_JOB_ARR_id=$(echo "${STEP1_TRIMMING_JOB_ARR}" | cut -d '.' -f 1 )
