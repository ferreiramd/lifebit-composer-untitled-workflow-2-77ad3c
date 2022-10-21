process test_python_1 {

    input:
        tuple val(label), val(accession)
        
    script:
    """
#!/usr/bin/env python3

label='$label'
accession='$accession'

a = 5
print('The value of a is', a)

    """

}