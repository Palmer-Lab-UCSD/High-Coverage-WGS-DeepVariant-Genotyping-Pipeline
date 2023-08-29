#!/bin/bash

#### read in declared HPC environment variables
dir_path=${dir_path}
software=${software}

#### variables initialization
deepvarant_dir=${dir_path}/deepvarant

#### extract software locations from argument file
bcftools=$(awk 'BEGIN {count = 0} {if ($1 == "bcftools") {print $3; exit 0;} else count += 1} END {if (count == NR) {print "ERROR"}}' ${software})

if [ ${bcftools} = "ERROR" ] || [ ! -f ${bcftools} ]; then
	echo "Error: software_location"
	exit 1
fi

cd ${HOME}

################ glnexus for joint calling ################
echo "-----------   glnexus for joint calling   -----------"
START=$(date +%s)

gvcf_dir=${deepvarant_dir}/gvcf
gvcfs=$(ls ${deepvarant_dir}/*.g.vcf.gz)


singularity pull docker://quay.io/mlin/glnexus:v1.2.7

singularity run \
  docker://quay.io/mlin/glnexus:v1.2.7 \
  /usr/local/bin/glnexus_cli \
  --config DeepVariantWGS \
  --bed ${chr_bed} \
  ${gvcfs} \
  > ${gvcf_dir}/deepvariant_${chr}.bcf

${bcftools} view  \
  -Oz -o ${gvcf_dir}/deepvariant_${chr}.vcf.gz \
  ${gvcf_dir}/deepvariant_${chr}.bcf

${bcftools} index -t ${gvcf_dir}/deepvariant_${chr}.vcf.gz


while [ "$(jobs -rp | wc -l)" -gt 0 ]; do
	sleep 60
done
END=$(date +%s)
echo "glnexus for joint calling Time elapsed: $(( $END - $START )) seconds"