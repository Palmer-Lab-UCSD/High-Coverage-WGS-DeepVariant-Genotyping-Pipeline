#!/bin/bash

#### read in declared HPC environment variables
software=${software}
dir_path=${dir_path}
reference_genome=${reference_genome}
sample_name_list=${sample_name_list}
ppn=${ppn}

#### variables initialization
sam_dir=${dir_path}/sams
temp_dir=${dir_path}/temp
bam_dir=${dir_path}/bams
trimmed_polyG_dir=${dir_path}/trimmed_polyG
## !!!!!!!!!!!!!!!!!!!!
## each array job only process one sample
## !!!!!!!!!!!!!!!!!!!!
sample_fastqs=$(head -n ${PBS_ARRAYID} ${sample_name_list} | tail -n 1)
sample_prefix=$(echo ${sample_fastqs} | cut -f 1 -d ' ')

#### extract software locations from argument file
bwa=$(awk 'BEGIN {count = 0} {if ($1 == "BWA") {print $3; exit 0;} else count += 1} END {if (count == NR) {print "ERROR"}}' ${software})
samtools=$(awk 'BEGIN {count = 0} {if ($1 == "Samtools") {print $3; exit 0;} else count += 1} END {if (count == NR) {print "ERROR"}}' ${software})

if [ ${bwa} = "ERROR" ] || [ ${samtools} = "ERROR" ] || [ ! -f ${bwa} ] || [ ! -f ${samtools} ]; then
	echo "Error: software_location"
	exit 1
fi

cd ${HOME}

################ BWA to map sequences to reference genome ################
echo "-----------   BWA to map sequences to reference genome   -----------"
START=$(date +%s)

#### construct the register group for bwa
platform=ILLUMINA
flowcell_id=NULL
flowcell_lane=NULL
library_id=NULL

echo -e "\n-----run ${PBS_ARRAYID}-th file: ${fastq1} > ${sam_dir}/${sam_prefix}.sam-----"
${bwa} mem -Y -K 100000000 -t 3\
	-R "@RG\tID:${flowcell_id}.${flowcell_lane}\tLB:${library_id}\tPL:${platform}\tSM:${sample}" \
	${reference_genome} \
	${trimmed_polyG_dir}/${sample_prefix}_R1.fastq.gz \
	${trimmed_polyG_dir}/${sample_prefix}_R2.fastq.gz \
	> ${sam_dir}/${sample_prefix}.sam &

while [ "$(jobs -rp | wc -l)" -gt 0 ]; do
	sleep 60
done

END=$(date +%s)
echo "BWA alignment time elapsed: $(( $END - $START )) seconds"


################ Samtools to covert SAM to BAM ################
echo "-----------   Samtools to covert SAM to BAM   -----------"
START=$(date +%s)

echo -e "\n-----run file: ${sam_dir}/${sample_prefix}.sam > ${bam_dir}/${sample_prefix}.bam-----"
${samtools} view -h -b -@ 10 \
	-t ${reference_genome} -o ${bam_dir}/${sample_prefix}.bam ${sam_dir}/${sample_prefix}.sam

while [ "$(jobs -rp | wc -l)" -gt 0 ]; do
	sleep 60
done

END=$(date +%s)
echo "Samtools to covert SAM to BAM time elapsed: $(( $END - $START )) seconds"

################ Samtools to collate, fixmate, sort, markdup BAM ################
echo "----------   Samtools to collate, fixmate, sort, markdup BAM   ----------"
START=$(date +%s)

echo -e "\n-----run file: ${bam_dir}/${sample_prefix}.bam > ${bam_dir}/${sample_prefix}_mkDup.bam----"
${samtools} collate -@ ${ppn} -o - ${bam_dir}/${sample_prefix}.bam ${temp_dir} | \
${samtools} fixmate -@ ${ppn} -m - - | \
${samtools} sort -@ ${ppn} -T ${temp_dir} - | \
${samtools} markdup -@ ${ppn} -T ${temp_dir} - ${bam_dir}/${sample_prefix}_mkDup.bam

while [ "$(jobs -rp | wc -l)" -gt 0 ]; do
	sleep 60
done

END=$(date +%s)
echo "Samtools to collate, fixmate, sort, markdup BAM time elapsed: $(( $END - $START )) seconds"

################ Samtools to index BAM ################
echo "-----------   Samtools to index BAM   -----------"
START=$(date +%s)

echo -e "\n-----run file: ${bam_dir}/${sample_prefix}_mkDup.bam > ${bam_dir}/${sample_prefix}_mkDup.bai-----"
${samtools} index -@ ${ppn} ${bam_dir}/${sample_prefix}_mkDup.bam ${bam_dir}/${sample_prefix}_mkDup.bai
while [ "$(jobs -rp | wc -l)" -gt 0 ]; do
	sleep 60
done

END=$(date +%s)
echo "Samtools to index BAM time elapsed: $(( $END - $START )) seconds"
