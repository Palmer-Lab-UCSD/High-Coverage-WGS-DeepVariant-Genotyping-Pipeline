#!/bin/bash

#### read in declared HPC environment variables
software=${software}
dir_path=${dir_path}
bbduck_adapter=${bbduck_adapter}
sample_name_list=${sample_name_list}
ppn=${ppn}

#### variables initialization
qc_before_trimming=${dir_path}/qc_before_trimming
trimmed_adapter_dir=${dir_path}/trimmed_adapter
trimmed_polyG_dir=${dir_path}/trimmed_polyG
qc_after_trimming=${dir_path}/qc_after_trimming
## !!!!!!!!!!!!!!!!!!!!
## each array job only process one sample
## !!!!!!!!!!!!!!!!!!!!
sample_fastqs=$(head -n ${PBS_ARRAYID} ${sample_name_list} | tail -n 1)
fastq_prefix=$(echo ${sample_fastqs} | cut -f 1 -d ' ')
fastqs=$(echo ${sample_fastqs} | cut -f 2 -d ' ' )
fastq1=$(echo ${fastqs} | cut -d ';' -f 1)
fastq2=$(echo ${fastqs} | cut -d ';' -f 2)

#### extract software locations from argument file
bbduk=$(awk 'BEGIN {count = 0} {if ($1 == "Bbduk") {print $3; exit 0;} else count += 1} END {if (count == NR) {print "ERROR"}}' ${software})
fastqc=$(awk 'BEGIN {count = 0} {if ($1 == "FastQC") {print $3; exit 0;} else count += 1} END {if (count == NR) {print "ERROR"}}' ${software})

if [ ${bbduk} = "ERROR" ] || [ ${fastqc} = "ERROR" ] || [ ! -f ${bbduk} ] || [ ! -f ${fastqc} ]; then
	echo "Error: software_location"
	exit 1
fi

cd ${HOME}

########### FastQC to check the quality of sequences after trimming ###########
echo "------   FastQC to check the quality of sequences after trimming   ------"
START=$(date +%s)

${fastqc} \
    ${fastq1} \
    --outdir=${qc_before_trimming}/FastQC/ &

${fastqc} \
    ${fastq2} \
    --outdir=${qc_before_trimming}/FastQC/ &

while [ "$(jobs -rp | wc -l)" -gt 0 ]; do
	sleep 60
done

END=$(date +%s)
echo "FastQC time elapsed: $(( $END - $START )) seconds"


###################### Bbduk to trim off the adapters ######################
echo "----------------     Bbduk to trim off the adapters     ----------------"
START=$(date +%s)

${bbduk} \
	ref=${bbduck_adapter} \
	in1=${fastq1} \
	in2=${fastq2} \
	out1=${trimmed_adapter_dir}/${fastq_prefix}_R1.fastq.gz \
	out2=${trimmed_adapter_dir}/${fastq_prefix}_R2.fastq.gz \
	ktrim=r k=23 mink=11 hdist=1 tpe tbo

${bbduk} \
    in1=${trimmed_adapter_dir}/${fastq_prefix}_R1.fastq.gz \
    in2=${trimmed_adapter_dir}/${fastq_prefix}_R2.fastq.gz \
    out1=${trimmed_polyG_dir}/${fastq_prefix}_R1.fastq.gz \
    out2=${trimmed_polyG_dir}/${fastq_prefix}_R2.fastq.gz \
    trimpolyg=50 tpe

while [ "$(jobs -rp | wc -l)" -gt 0 ]; do
	sleep 60
done
END=$(date +%s)
echo "BBduk trimming time elapsed: $(( $END - $START )) seconds"

########### FastQC to check the quality of sequences after trimming ###########
echo "------   FastQC to check the quality of sequences after trimming   ------"
START=$(date +%s)

${fastqc} \
    ${trimmed_polyG_dir}/${fastq_prefix}_R1.fastq.gz \
    --outdir=${qc_after_trimming}/FastQC/ &

${fastqc} \
    ${trimmed_polyG_dir}/${fastq_prefix}_R2.fastq.gz \
    --outdir=${qc_after_trimming}/FastQC/ &

while [ "$(jobs -rp | wc -l)" -gt 0 ]; do
	sleep 60
done

END=$(date +%s)
echo "FastQC time elapsed: $(( $END - $START )) seconds"
