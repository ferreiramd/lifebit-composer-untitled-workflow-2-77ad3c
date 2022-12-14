#!/usr/bin/env nextflow
/*
========================================================================================
                         bi-traits-nf
========================================================================================
 bi-traits-nf Analysis Pipeline.
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl=2

/*---------------------------------------
  Define and show help message if needed
-----------------------------------------*/

def helpMessage() {

    log.info"""
    
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run main.nf --analysis_mode heritability --input_gwas_statistics GWAS123.vcf
    Essential parameters:
    --analysis_mode                  Type of analysis desired. Options are 'heritability' or 'genetic_correlation'.
    --input_gwas_statistics          Path to GWAS summary statistics file in GWAS VCF format.
    
    Optional parameters:
    --method                         Software used to perform the analysis. Default = LDSC. Currently available input options: LDSC, LDAK, GCTA_GREML.
    --other_gwas_statistics          Path to second set of GWAS summary statistics to be used for genetic correlation.                    
    --hapmap3_snplist                Path to SNP list from Hapmap needed for seleting SNPs considered for analysis
    --ld_scores_tar_bz2              Path to tar.bz2 files with precomputed LD scores. Alternatively, population can be specified via --pop parameter to use population-specific 1000Genomes LD scores. 
                                     If both --ld_scores_tar_bz2 and --pop are specified, LD scores provided via --ld_scores_tar_bz2 will be used.
    --pop                            Population (determines population-specific 1000Genomes LD scores used). Can be specified 
                                     instead of --ld_scores_tar_bz2 parameter. Default = EUR. Current available input options: EUR (European), EAS (East Asian), GBR (British).
                                     If both --ld_scores_tar_bz2 and --pop are specified, LD scores provided via --ld_scores_tar_bz2 will be used.
    --thin_ldak_tagging_file         Path to thin tagging model file used exclusively in the LDAK mode.
    --bld_ldak_tagging_file          Path to bld tagging model file used exclusively in the LDAK mode.
    --outdir                         Path to output directory
    --output_tag                     String containing output tag
    --gwas_sample_size               Number of samples in the input GWAS VCF (int)
                                     (Default: $params.traits_ldsc_gc_1.gwas_sample_size)
    --other_gwas_sample_size      Number of samples in the external GWAS VCF (int)
                                     (Default: $params.traits_ldsc_gc_1.other_gwas_sample_size)
    """.stripIndent()
}

// Show help message

if (params.help) {
    helpMessage()
    exit 0
}



/*---------------------------------------------------
  Define and show header with all params information 
-----------------------------------------------------*/

// Header log info

def summary = [:]

if (workflow.revision) summary['Pipeline Release'] = workflow.revision
summary['Output dir']                     = params.traits_ldsc_gc_1.outdir
summary['Launch dir']                     = workflow.launchDir
summary['Working dir']                    = workflow.workDir
summary['Script dir']                     = workflow.projectDir
summary['User']                           = workflow.userName

summary['input_gwas_statistics']          = params.input_gwas_statistics
summary['other_gwas_statistics']          = params.other_gwas_statistics
summary['hapmap3_snplist']                = params.hapmap3_snplist
summary['ld_scores_tar_bz2']              = params.ld_scores_tar_bz2
summary['output_tag']                     = params.traits_ldsc_gc_1.output_tag
summary['outdir']                         = params.traits_ldsc_gc_1.outdir
summary['gwas_sample_size']               = params.traits_ldsc_gc_1.gwas_sample_size
summary['other_gwas_sample_size']         = params.traits_ldsc_gc_1.other_gwas_sample_size

log.info summary.collect { k,v -> "${k.padRight(18)}: $v" }.join("\n")
log.info "-\033[2m--------------------------------------------------\033[0m-"

/*--------------------------------------------------
  LDSC - Genetic correlation and heritability
---------------------------------------------------*/
process prepare_vcf_files_ldsc {
    tag "preparation_files"
    label 'bcftools'
    publishDir "${params.traits_ldsc_gc_1.outdir}/ldsc_inputs/", mode: 'copy'

    input:
    file(gwas_vcf)

    output:
    path("${params.traits_ldsc_gc_1.output_tag}_transformed_gwas_stats.txt"), emit: ldsc_input

    script:

    """
    echo "CHR POS SNPID Allele1 Allele2 BETA SE p.value" > base.data.pre
    bcftools query -f'%CHROM %POS [%SNP] %REF %ALT [%BETA] [%SE] [%P]\n' $gwas_vcf >> base.data.pre
    # Generating the N column
    echo "N" > n_col.txt
    for i in \$(seq 2 `wc -l < base.data.pre`); do
      echo $params.traits_ldsc_gc_1.gwas_sample_size >> n_col.txt
    done
    # Generating the imputationInfo column
    echo "imputationInfo" > info_col.txt
    for i in \$(seq 2 `wc -l < base.data.pre`); do
      echo "1" >> info_col.txt
    done
    paste -d " " base.data.pre n_col.txt info_col.txt > "${params.traits_ldsc_gc_1.output_tag}_transformed_gwas_stats.txt"
    """
}

    
process reformat_for_ldsc {
      tag "reformat_for_ldsc"
      publishDir "${params.traits_ldsc_gc_1.outdir}/ldsc_inputs/", mode: 'copy'
      stageInMode 'copy'

      input:
      file(ldsc_summary_stats)
      file(hapmap3_snplist)

      output:
      path("${params.traits_ldsc_gc_1.output_tag}_ldsc.sumstats.gz"), emit: saige_ldsc

      script:

      """
      munge_sumstats.py --sumstats $ldsc_summary_stats \
                        --out "${params.traits_ldsc_gc_1.output_tag}_ldsc" \
                        --merge-alleles $hapmap3_snplist \
                        --a1 Allele1 \
                        --chunksize ${params.traits_ldsc_gc_1.munge_sumstats_chunksize} \
                        --a2 Allele2 \
                        --signed-sumstats BETA,0 \
                        --p p.value \
                        --snp SNPID \
                        --info imputationInfo
      """
}

process prepare_vcf_gwas_summary_ldsc {
    tag "preparation_files"
    label 'bcftools'
    publishDir "${params.traits_ldsc_gc_1.outdir}/ldsc_inputs/", mode: 'copy'

    input:
    file(gwas_vcf)

    output:
    path("${params.traits_ldsc_gc_1.output_tag}_transformed_gwas_stats.txt"), emit: gwas_summary_ldsc

    script:

    """
    echo "CHR POS SNPID Allele1 Allele2 BETA SE p.value" > base.data.pre
    bcftools query -f'%CHROM %POS [%SNP] %REF %ALT [%BETA] [%SE] [%P]\n' $gwas_vcf >> base.data.pre
    # Generating the N column
    echo "N" > n_col.txt
    for i in \$(seq 2 `wc -l < base.data.pre`); do
      echo $params.traits_ldsc_gc_1.other_gwas_sample_size >> n_col.txt
    done
    # Generating the imputationInfo column
    echo "imputationInfo" > info_col.txt
    for i in \$(seq 2 `wc -l < base.data.pre`); do
      echo "1" >> info_col.txt
    done
    paste -d " " base.data.pre n_col.txt info_col.txt > "${params.traits_ldsc_gc_1.output_tag}_transformed_gwas_stats.txt"
    """
}

process munge_other_sumstats {
    tag "munge_gwas_summary"
    publishDir "${params.traits_ldsc_gc_1.outdir}/ldsc_inputs/", mode: 'copy'

    input:
    file(summary_stats)
    file(hapmap3_snplist)

    output:
    path("${summary_stats.simpleName}_gwas_summary.sumstats.gz"), emit: gwas_summary_ldsc2

    script:

    """
    munge_sumstats.py \
          --sumstats "$summary_stats" \
          --out "${summary_stats.simpleName}_gwas_summary" \
          --merge-alleles $hapmap3_snplist
    """
}

process genetic_correlation_ldsc {
    tag "genetic_correlation"
    publishDir "${params.traits_ldsc_gc_1.outdir}/genetic_correlation/", mode: 'copy'

    input:
    file(gwas_summary_ldsc)
    file(saige_ldsc)
    file(ld_scores_tar_bz2)

    output:
    path("${params.traits_ldsc_gc_1.output_tag}_genetic_correlation.log"), emit: ldsc_report_input

    script:

    """
    tar -xvjf ${ld_scores_tar_bz2}
    ldsc.py \
          --rg $saige_ldsc,$gwas_summary_ldsc \
          --ref-ld-chr ${ld_scores_tar_bz2.simpleName}/ \
          --w-ld-chr ${ld_scores_tar_bz2.simpleName}/ \
          --out ${params.traits_ldsc_gc_1.output_tag}_genetic_correlation \
          --no-intercept
    """
}

workflow traits_ldsc_gc_1{
  take:
    ch_gwas_statistics
    ch_hapmap3_snplist
    ch_gwas_summary
    ch_ld_scores_tar_bz2

  main:
    prepare_vcf_files_ldsc(ch_gwas_statistics)
    reformat_for_ldsc(prepare_vcf_files_ldsc.out.ldsc_input, 
                        ch_hapmap3_snplist)

    prepare_vcf_gwas_summary_ldsc(ch_gwas_summary)
    munge_other_sumstats(prepare_vcf_gwas_summary_ldsc.out.gwas_summary_ldsc,
                            ch_hapmap3_snplist)
    genetic_correlation_ldsc(munge_other_sumstats.out.gwas_summary_ldsc2,
                                reformat_for_ldsc.out.saige_ldsc, 
                                ch_ld_scores_tar_bz2)
    ldsc_out =  genetic_correlation_ldsc.out.ldsc_report_input
  
  emit:
    ldsc_out

}

workflow {
  if (params.method == 'LDSC') {
    if (params.analysis_mode == 'genetic_correlation'){
      ch_gwas_statistics   =  Channel
                              .fromPath(params.input_gwas_statistics)
                              .ifEmpty { exit 1, "Cannot find GWAS stats file : ${params.input_gwas_statistics}" }
      
      ch_hapmap3_snplist   =  Channel
                              .fromPath(params.hapmap3_snplist)
                              .ifEmpty { exit 1, "Cannot find HapMap3 snplist file : ${params.hapmap3_snplist}" }
      
      ch_gwas_summary      =  Channel
                              .fromPath(params.other_gwas_statistics)
                              .ifEmpty { exit 1, "Cannot find the other GWAS stats file : ${params.other_gwas_statistics}" }
      
      ch_ld_scores_tar_bz2 = Channel
                              .fromPath(params.ld_scores_tar_bz2)
                              .ifEmpty { exit 1, "Cannot find LD scores file : ${params.ld_scores_tar_bz2}" }
      
      lifebitai_traits_gcta_greml(ch_gwas_statistics,
                                  ch_hapmap3_snplist,
                                  ch_gwas_summary,
                                  ch_ld_scores_tar_bz2)

    }
  }
}