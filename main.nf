#!/usr/bin/env nextflow

if( !params.study ) error "Missing ENA `study` param"
if( !params.manifest ) error "Missing ena.csv `manifest` param"
if( !params.webin_jar ) error "Missing `webin_jar` path param"
if( !params.out ) error "Missing `out` path param"

if( !System.getenv("WEBIN_USER") ) error '$WEBIN_USER unset'
if( !System.getenv("WEBIN_PASS") ) error '$WEBIN_PASS unset'

flag_ascp = ""
if( params.ascp ){
    flag_ascp = "-ascp"
}
flag_test = ""
if( params.test ){
    flag_test = "-test"
}
description_s = ""
if( params.description ){
    description_s = params.description
}

out_name = file(params.out).name
out_dir = file(params.out).parent


workflow_repo = "samstudio8/elan-ena-nextflow"
workflow_v = workflow.manifest.version
workflow_cid = ""
if( workflow.commitId ){
    workflow_repo = workflow.repository
    workflow_v = workflow.revision
    workflow_cid = workflow.commitId.substring(0, 7)
}

Channel
    .fromPath(params.manifest)
    .splitCsv(header:true, sep:'\t')
    .map{ it << [climb_fn: file(it.climb_fn), hoot:0] }
    .set{manifest_ch}

process prep_fasta {

    input:
    val row from manifest_ch

    output:
    tuple row, file("${row.climb_fn.baseName}.ena-a.fasta.gz") into chrlist_ch

    """
    elan_rehead.py ${row.climb_fn} '${row.published_name}' | gzip > ${row.climb_fn.baseName}.ena-a.fasta.gz
    """
}

process generate_chrlist {

    input:
    tuple row, file(ena_fasta) from chrlist_ch

    output:
    tuple row, file(ena_fasta), file("${row.climb_fn.baseName}.chr_list.txt.gz") into genmanifest_ch

    script:
    """
    echo "${row.published_name} 1 Monopartite" | gzip > ${row.climb_fn.baseName}.chr_list.txt.gz
    """
}

process generate_manifest {
    input:
    tuple row, file(ena_fasta), file(chr_list) from genmanifest_ch

    output:
    tuple row, file(ena_fasta), file(chr_list), file("${row.climb_fn.baseName}.manifest.txt") into webin_validate_ch

    script:
    def engine = new groovy.text.SimpleTemplateEngine()
    this_description = engine.createTemplate(description_s).make(['row':row]).toString()
    """
    echo "STUDY ${params.study}
SAMPLE ${row.ena_sample_id}
RUN_REF ${row.ena_run_id}
ASSEMBLYNAME ${row.assemblyname}
DESCRIPTION """ << this_description << """
ASSEMBLY_TYPE COVID-19 outbreak
MOLECULETYPE genomic RNA
COVERAGE ${row.mean_cov}
PROGRAM ${row.program}
PLATFORM ${row.platform}
CHROMOSOME_LIST ${chr_list}
FASTA ${ena_fasta}
AUTHORS ${row.authors}
ADDRESS ${row.address}
SUBMISSION_TOOL ${workflow_repo}
SUBMISSION_TOOL_VERSION ${workflow_v}@${workflow_cid}" > ${row.climb_fn.baseName}.manifest.txt
    """
}

process webin_validate {
    input:
    tuple row, file(ena_fasta), file(chr_list), file(ena_manifest) from webin_validate_ch

    errorStrategy 'ignore' //# Drop assemblies that fail to validate

    output:
    tuple row, file(ena_fasta), file(chr_list), file(ena_manifest) into webin_submit_ch

    script:
    """
    java -jar ${params.webin_jar} -context genome -userName \$WEBIN_USER -password \$WEBIN_PASS -manifest ${ena_manifest} -centerName '${row.center_name}' ${flag_ascp} -validate
    """
}

process webin_submit {
    errorStrategy 'ignore' //# Drop assemblies that fail to validate

    input:
    tuple row, file(ena_fasta), file(chr_list), file(ena_manifest) from webin_submit_ch

    output:
    tuple row, file(ena_fasta), file(chr_list), file(ena_manifest), file("genome/${row.assemblyname.replaceAll('#', '_')}/submit/receipt.xml") into webin_parse_ch

    script:
    """
    java -jar ${params.webin_jar} -context genome -userName \$WEBIN_USER -password \$WEBIN_PASS -manifest ${ena_manifest} -centerName '${row.center_name}' ${flag_ascp} -submit ${flag_test}
    """
}

process receipt_parser {
    conda "$baseDir/environments/receipt.yaml"

    input:
    tuple row, file(ena_fasta), file(chr_list), file(ena_manifest), file(ena_receipt) from webin_parse_ch

    output:
    file("${row.climb_fn.baseName}.accession.txt") into accession_report_ch

    script:
    """
    parse_receipt.py ${ena_manifest} ${ena_receipt} ${row.published_name} > ${row.climb_fn.baseName}.accession.txt
    """
}

accession_report_ch
    .collectFile(keepHeader: true, name: "${out_name}", storeDir: "${out_dir}")
