![alt text](https://secureservercdn.net/198.71.233.106/h9j.d46.myftpupload.com/wp-content/uploads/2019/09/palmerlab-logo.png)
# Genotyping
## Source code for genotyping section of the genotyping pipeline
:information_source: :information_source: :information_source:  **INFOMATION** :information_source: :information_source: :information_source:  

## Contents

**[step1_trimming.sh](step1_trimming.sh)**  
[FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) to do quality control on sequences, and [Bbduk](https://jgi.doe.gov/data-and-tools/software-tools/bbtools/bb-tools-user-guide/bbduk-guide/) to trim adapters and polyG.

**[step2_alignment.sh](step2_alignment.sh)**  
Map the sequencing reads to reference genome ([BWA](http://bio-bwa.sourceforge.net/index.shtml)), convert SAM files to BAM files ([Samtools](http://www.htslib.org/)), sort BAM files ([Samtools](http://www.htslib.org/)), mark PCR duplicates on BAM files ([Samtools](https://broadinstitute.github.io/picard/)) and index the marked-duplicates BAM files ([Samtools](http://www.htslib.org/)).  

**[step3_indel_realignment.sh](step3_indel_realignment.sh)**  
Indel realignment with GATK 3.8.1.0 ([GATK 3.8.1.0](https://github.com/broadinstitute/gatk-docs/blob/master/blog-2012-to-2019/2016-06-21-Changing_workflows_around_calling_SNPs_and_indels.md?id=7847)).  

**[step4_BQSR.sh](step4_BQSR.sh)**  
BQSR with GATK ([GATK](https://gatk.broadinstitute.org/hc/en-us/articles/360035890531-Base-Quality-Score-Recalibration-BQSR-)).  

**[step5_variantCalling.sh](step5_variantCalling.sh)**  
Variant calling with GATK ([GATK](https://gatk.broadinstitute.org/hc/en-us/articles/360035535932-Germline-short-variant-discovery-SNPs-Indels-)).  

**[step6_filter_plots_per_chr.sh](step6_filter_plots_per_chr.sh)**  
Variants filtering with GATK ([GATK](https://gatk.broadinstitute.org/hc/en-us/articles/360035531112--How-to-Filter-variants-either-with-VQSR-or-by-hard-filtering#2)).
