#!/bin/bash

#### read in declared HPC environment variables
dir_path=${dir_path}
reference_genome=${reference_genome}
sample_name_list=${sample_name_list}

#### variables initialization
bam_dir=${dir_path}/bams
indelRealign_dir=${dir_path}/indelRealign
deepvarant_dir=${dir_path}/deepvarant
tmp_dir=${dir_path}/tmp
## !!!!!!!!!!!!!!!!!!!!
## each array job only process one sample
## !!!!!!!!!!!!!!!!!!!!
sample_prefix=$(head -n ${PBS_ARRAYID} ${sample_name_list} | tail -n 1)
bam=${indelRealign_dir}/${sample_prefix}_indelrealigned.bam

cd ${HOME}

################ Deepvariant for variant calling ################
echo "-----------   Deepvariant for variant calling   -----------"
START=$(date +%s)

vcf_dir=${deepvarant_dir}/${sample_prefix}_vcf
gvcf_dir=${deepvarant_dir}/${sample_prefix}_gvcf

singularity pull docker://google/deepvariant:"1.4.0"

singularity run \
  docker://google/deepvariant:"1.4.0" \
  /opt/deepvariant/bin/run_deepvariant \
  --model_type=WGS \
  --ref=${reference_genome} \
  --reads=${bam} \
  --regions=${chr} \
  --output_vcf=${vcf_dir}/${sample}.vcf.gz \
  --output_gvcf=${gvcf_dir}/${sample}.g.vcf.gz \
  --intermediate_results_dir ${tmp_dir}

while [ "$(jobs -rp | wc -l)" -gt 0 ]; do
	sleep 60
done
END=$(date +%s)
echo "Deepvariant for variant calling Time elapsed: $(( $END - $START )) seconds"