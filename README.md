# elan-ena

A Nextflow pipeline for smoothly transferring fresh consensus sequences to ENA via `webin-cli`.

## Parameters

### Required command line parameters

 | Name | Description |
 | ---- | ----------- |
 | `study` | ENA study identifier (`PRJEB`) |
 | `manifest` |  Assembly metadata manifest |
 | `webin_jar` | Path to `webin-cli` JAR ([releases](https://github.com/enasequence/webin-cli/releases) |

### Required environment variables

Additionally, you will need to set the following parameters in your environment:

 | Name | Description |
 | ---- | ----------- |
 | `WEBIN_USER` | EMBL-EBI Webin username |
 | `WEBIN_PASS` | EMBL-EBI Webin password |

### Optional command line parameters

| Name | Description |
| ---- | ----------- |
| `ascp` | Enable `ascp` transfer with `webin-cli` (`ascp` must be on your `PATH`) |


## Invocation

```
export WEBIN_USER='Webin-00000'
export WEBIN_PASS='hunter2'
nextflow run samstudio8/elan-ena-nextflow -r stable \
    --study PRJEB00000 \
    --manifest /path/to/manifest.tsv \
    --webin_jar /path/to/webin-cli.jar
```

To update a local copy:

```
nextflow pull samstudio8/elan-ena-nextflow
```
