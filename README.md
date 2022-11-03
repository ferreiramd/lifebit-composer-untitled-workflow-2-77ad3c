# Untitled Workflow #2

## Description



## Components

The present workflow is composed by the following unique components (Note that some components may be repeated):

### lifebitai_traits_ldsc_gc

**Description**: Genetic Traits pipeline running LDSC on genetic correlation.\
**Inputs**: 4\
**Outputs**: 1\
**Parameters**: 5\
**Authors**: 

## Inputs

- `--traits_ldsc_gc_1.gwas_statistics_file`: 
- `--traits_ldsc_gc_1.hapmap3_snplist`: 
- `--traits_ldsc_gc_1.gwas_summary_file`: 
- `--traits_ldsc_gc_1.ld_scores_tar_bz2`: 
## Parameters

### Required

- `--traits_ldsc_gc_1.gwas_sample_size`: Number of samples in the input GWAS VCF
    - **Component**: traits_ldsc_gc_1 
    - Type: number

- `--traits_ldsc_gc_1.other_gwas_sample_size`: Number of samples in the external GWAS VCF
    - **Component**: traits_ldsc_gc_1 
    - Type: number

- `--traits_ldsc_gc_1.output_tag`: Tag string for the output
    - **Component**: traits_ldsc_gc_1 
    - Type: string



### Optional

- `--traits_ldsc_gc_1.outdir`: Output directory for the results
    - **Component**: traits_ldsc_gc_1 
    - Type: path
    - Default: `results/` 

- `--traits_ldsc_gc_1.munge_sumstats_chunksize`: Size of the chunks used my mungesumstats
    - **Component**: traits_ldsc_gc_1 
    - Type: number
    - Default: `500000` 

