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
    awk '/^S/{print ">"\$2;print \$3}' hifiasm.bp.p_ctg.gfa > hifiasm.fa
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
    path 'flye.fa'
    script:
    """
    flye --pacbio-hifi ${reads} --out-dir flye
    mv flye/assembly.fasta flye.fa
    """
}

process Canu {
    publishDir 'assembly', mode: 'copy'
    container 'quay.io/biocontainers/canu:2.2--ha47f30e_0'
    cpus 8
    memory { 36.GB * task.attempt }
    errorStrategy { task.exitStatus == 137 ? 'retry' : 'finish' }
    queue 'medium'
    input:
    path reads
    output:
    path 'canu.fa'
    script:
    """
    canu -p canu -d canu genomeSize=100m useGrid=false maxInputCoverage=20000 batMemory=32g -pacbio-hifi ${reads}
    mv canu/canu.contigs.fasta canu.fa
    """
}

process Coverm {
    container 'quay.io/biocontainers/coverm:0.7.0--h07ea13f_1'
    publishDir 'assembly', mode: 'copy'
    cpus 4
    memory { 8.GB * task.attempt }
    errorStrategy { task.exitStatus == 137 ? 'retry' : 'finish' }
    queue 'short'
    input:
    path assembly
    path reads
    output:
    path '${assembly.simpleName}.coverage.tsv'
    script:
    """
    coverm contig --single ${reads} -r ${assembly} -m mean length -p minimap2-hifi -o ${assembly.simpleName}.coverage.tsv
    """
}

process Getorf {
    container 'quay.io/biocontainers/emboss:6.5.7--2'
    publishDir 'assembly', mode: 'copy'
    cpus 4
    memory { 8.GB * task.attempt }
    errorStrategy { task.exitStatus == 137 ? 'retry' : 'finish' }
    queue 'short'
    input:
    path assembly
    output:
    path '${assembly.simpleName}.orf.fa'
    script:
    """
    getorf -sequence ${assembly} -outseq ${assembly.simpleName}.orf.fa
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
    container 'quay.io/biocontainers/hmmer:3.1b2--1'
    publishDir 'assembly', mode: 'copy'
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
    path '${nbarc.baseName}.hmmsearch.seq.fa'
    script:
    """
    hmmsearch -A ${orfs.simpleName}.hmmsearch.fa --tblout ${orfs.simpleName}.hmmsearch.tsv PF00931.hmm ${orfs}
    esl-reformat fasta ${orfs.simpleName}.hmmsearch.fa > ${orfs.simpleName}.hmmsearch.seq.fa
    """
}

workflow {
    hifiReads = file("p557.fastq.gz")

    hifiasmAssembly = Hifiasm(hifiReads)
    hifiasmOrfs = Getorf(hifiasmAssembly)
    hifiasmNbarcFasta = Hmmsearch(hifiasmOrfs, "PF00931.hmm")
    Coverm(hifiasmAssembly, hifiReads)

    flyeAssembly = Flye(hifiReads)
    flyeOrfs = Getorf(flyeAssembly)
    flyeNbarcFasta = Hmmsearch(flyeOrfs, "PF00931.hmm")
    Coverm(flyeAssembly, hifiReads)

    canuAssembly = Canu(hifiReads)
    canuOrfs = Getorf(canuAssembly)
    canuNbarcFasta = Hmmsearch(canuOrfs, "PF00931.hmm")
    Coverm(canuAssembly, hifiReads)
}