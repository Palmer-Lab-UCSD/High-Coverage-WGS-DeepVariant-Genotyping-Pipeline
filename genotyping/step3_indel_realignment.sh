#!/bin/bash

#### read in declared HPC environment variables
software=${software}
dir_path=${dir_path}
reference_genome=${reference_genome}
sample_name_list=${sample_name_list}

#### variables initialization
bam_dir=${dir_path}/bams
indelRealign_dir=${dir_path}/indelRealign
## !!!!!!!!!!!!!!!!!!!!
## each array job only process one sample
## !!!!!!!!!!!!!!!!!!!!
sample_fastqs=$(head -n ${PBS_ARRAYID} ${sample_name_list} | tail -n 1)
sample_prefix=$(echo ${sample_fastqs} | cut -f 1 -d ' ')
bam_file=${bam_dir}/${sample_prefix}_mkDup.bam

#### extract software locations from argument file
java=$(awk 'BEGIN {count = 0} {if ($1 == "Java") {print $3; exit 0;} else count += 1} END {if (count == NR) {print "ERROR"}}' ${software})
GATK=$(awk 'BEGIN {count = 0} {if ($1 == "GATK") {print $3; exit 0;} else count += 1} END {if (count == NR) {print "ERROR"}}' ${software})

if [ ${java} = "ERROR" ] || [ ${GATK} = "ERROR" ] || [ ! -f ${java} ] || [ ! -f ${GATK} ]; then
	echo "Error: software_location"
	exit 1
fi

cd ${HOME}

################ GATK to realign indel ################
echo "-----------   GATK to realign indel   -----------"
START=$(date +%s)

echo -e "\n-----run RealignerTargetCreator file: ${bam_file} > ${indelRealign_dir}/${sample_prefix}_indel.intervals-----"
${java} -Xmx50G \
    -jar ${GATK} \
    -T RealignerTargetCreator \
    -R ${reference_genome} \
    -I ${bam_file} \
    -o ${indelRealign_dir}/${sample_prefix}_indel.intervals

echo -e "\n-----run IndelRealigner file: ${basm_file} > ${indelRealign_dir}/${sample_prefix}_indelrealigned.bam-----"
${java} -Xmx50G \
    -jar ${GATK} \
    -T IndelRealigner \
    -R ${reference_genome} \
    -targetIntervals ${indelRealign_dir}/${sample_prefix}_indel.intervals \
    -I ${bam_file} \
    -o ${indelRealign_dir}/${sample_prefix}_indelrealigned.bam

while [ "$(jobs -rp | wc -l)" -gt 0 ]; do
   sleep 60
done
END=$(date +%s)
echo "IndelRealigner GATK time elapsed: $(( $END - $START )) seconds"
