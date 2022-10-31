process download_reads_1 {

    input:
        tuple val(label), val(accession)
        
    output:
        path "*_1.fastq", emit: output1
        
    script:
    """
#!/usr/bin/env bash

label='$label'
accession='$accession'

fasterq-dump $accession

    """

}