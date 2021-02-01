# elan-ena

A Nextflow pipeline for smoothly transferring fresh consensus sequences to ENA via `webin-cli`.

 ## Parameters
 
 | Name | Description |
 | ---- | ----------- |
 | `study` | ENA study identifier (`PRJEB`) |
 | `manifest` |  Assembly metadata manifest |
 | `webin_user` | EMBL-EBI Webin username |
 | `webin_pass` | EMBL-EBI Webin password |
 | `webin_jar` | Path to `webin-cli` JAR ([releases](https://github.com/enasequence/webin-cli/releases) |
 
 ## Invocation
 
```
nextflow run samstudio8/elan-ena-nextflow -r stable \
    --study PRJEB00000 \
    --manifest /path/to/manifest.tsv \
    --webin_user Webin-00000 \
    --webin_pass hunter2 \
    --webin_jar /path/to/webin-cli.jar
```

To update a local copy:

```
nextflow pull samstudio8/elan-ena-nextflow
```
