process Hifiasm {
    publishDir 'assembly', mode: 'copy'
    container 'quay.io/biocontainers/hifiasm:0.19.9--h43eeafb_0'
    cpus 8
    memory { 32.GB * task.attempt }
    errorStrategy { task.exitStatus == 137 ? 'retry' : 'finish' }
    queue 'medium'
    input:
    path reads
    output:
    path 'hifiasm.fa'
    script:
    """
    hifiasm -o hifiasm -t 8 ${reads}
    awk '/^S/{print ">"\$2;print \$3}' hifiasm.p_ctg.gfa > hifiasm.fa
    """
}

process Flye {
    publishDir 'assembly', mode: 'copy'
    container 'quay.io/biocontainers/flye:2.9.4--py38he0f268d_0'
    cpus 8
    memory { 32.GB * task.attempt }
    errorStrategy { task.exitStatus == 137 ? 'retry' : 'finish' }
    queue 'medium'
    input:
    path reads
    output:
    path 'flye/assembly.fasta'
    script:
    """
    flye --pacbio-hifi ${reads} --out-dir flye
    """
}

process Canu {
    publishDir 'assembly', mode: 'copy'
    container 'quay.io/biocontainers/canu:2.2--ha47f30e_0'
    cpus 8
    memory { 32.GB * task.attempt }
    errorStrategy { task.exitStatus == 137 ? 'retry' : 'finish' }
    queue 'medium'
    input:
    path reads
    output:
    path 'canu/canu.contigs.fasta'
    script:
    """
    canu -p canu -d canu genomeSize=100m useGrid=false maxInputCoverage=20000 batMemory=32g -pacbio-hifi ${reads}
    """
}

process Coverm {
    container 'quay.io/biocontainers/coverm:0.7.0--h07ea13f_1'
    cpus 4
    memory { 8.GB * task.attempt }
    errorStrategy { task.exitStatus == 137 ? 'retry' : 'finish' }
    queue 'short'
    input:
    path assembly
    path reads
    output:
    path '${assembly.baseName}.coverage.tsv'
    script:
    """
    coverm contig --single ${reads} -r ${assembly} -m mean length -p minimap2-hifi -o ${assembly.baseName}.coverage.tsv
    """
}

process Getorf {
    container 'quay.io/biocontainers/emboss:5.0.0--ha6fa2df_5'
    cpus 4
    memory { 8.GB * task.attempt }
    errorStrategy { task.exitStatus == 137 ? 'retry' : 'finish' }
    queue 'short'
    input:
    path assembly
    output:
    path '${assembly.baseName}.orf.fa'
    script:
    """
    getorf -sequence ${assembly} -outseq ${assembly.baseName}.orf.fa
    """
}

//process GetBed {
//    container 'quay.io/biocontainers/biopython:1.73'
//    cpus 1
//    memory { 1.GB * task.attempt }
//    errorStrategy { task.exitStatus == 137 ? 'retry' : 'finish' }
//    queue 'short'
//    input:
//    path orfs
//    output:
//    path '${orfs.baseName}.bed'
//    script:
//    """
//    #!/usr/bin/env python
//    from Bio import SeqIO
//    with open("${orfs.baseName}.bed", "w") as f:
//        for record in SeqIO.parse("${orfs}", "fasta"):
//            # Header format is >seqid_\d+ [start - end] {optionally (REVERSE SENSE)} ...
//            match = re.match(r"^(.*?)_(\d+) \[(\d+) - (\d+)\]", record.description)
//            sense = re.search(r".*REVERSE SENSE.*", record.description)
//            if sense:
//                f.write(f"{match.group(1)}\t{match.group(4)}\t{match.group(3)}\t{match.group(1)}_{match.group(2)}\t0\t-\n")
//            else:
//                f.write(f"{match.group(1)}\t{match.group(3)}\t{match.group(4)}\t{match.group(1)}_{match.group(2)}\t0\t+\n")
//    """
//
//}

process Hmmsearch {
    container 'quay.io/biocontainers/hmmer:3.4--hdbdd923_1'
    cpus 4
    memory { 4.GB * task.attempt }
    errorStrategy { task.exitStatus == 137 ? 'retry' : 'finish' }
    queue 'short'
    input:
    path orfs
    path nbarc
    output:
    path '${orfs.baseName}.hmmsearch.tsv'
    path '${orfs.baseName}.hmmsearch.fa'
    script:
    """
    hmmsearch -A ${orfs.baseName}.hmmsearch.fa --tblout ${orfs.baseName}.hmmsearch.tsv PF00931.hmm ${orfs}
    """

process GetFasta {
    container 'quay.io/biocontainers/hmmer:3.4--hdbdd923_1'
    cpus 1
    memory { 1.GB * task.attempt }
    errorStrategy { task.exitStatus == 137 ? 'retry' : 'finish' }
    queue 'short'
    input:
    path hmmsearch
    output:
    path '${hmmsearch.baseName}.hmmsearch.seq.fa'
    script:
    """
    esl-reformat fasta ${hmmsearch} > ${hmmsearch.baseName}.hmmsearch.seq.fa
    """
}

}

workflow {
    hifiReads = file("p557.fastq.gz")

    hifiasmAssembly = Hifiasm(hifiReads)
    flyeAssembly = Flye(hifiReads)
    canuAssembly = Canu(hifiReads)
}