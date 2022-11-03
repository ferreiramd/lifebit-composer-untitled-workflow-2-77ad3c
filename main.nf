nextflow.enable.dsl=2

include { traits_ldsc_gc_1 } from './modules/traits_ldsc_gc_1/module.nf'

workflow {
input1 = Channel.fromPath(params.traits_ldsc_gc_1.gwas_statistics_file)
input2 = Channel.fromPath(params.traits_ldsc_gc_1.hapmap3_snplist)
input3 = Channel.fromPath(params.traits_ldsc_gc_1.gwas_summary_file)
input4 = Channel.fromPath(params.traits_ldsc_gc_1.ld_scores_tar_bz2)
traits_ldsc_gc_1(input1, input2, input3, input4)
}
