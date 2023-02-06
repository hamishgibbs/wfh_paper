import time
import glob

TIMESTAMP = int(time.time())

rule all:
    input: 
        f"metadata/rulegraph/rulegraph_{TIMESTAMP}.dot",
        f"metadata/dag/dag_{TIMESTAMP}.dot",
        "output/mobility_overview_national.png",
        "output/wfh_distribution_log.png"

rule rulegraph:
    output: "metadata/rulegraph/rulegraph_{TIMESTAMP}.dot"
    shell:
        "snakemake --rulegraph > {output}"

rule dag:
    output: "metadata/dag/dag_{TIMESTAMP}.dot"
    shell:
        "snakemake --dag > {output}"

rule clean_apple: 
    input:
        "src/clean_apple_mobility.R",
        "data/mobility/apple_mobility_report.csv"
    output:
        "data/mobility/clean/apple_mobility.csv"
    shell:
        "Rscript {input} {output}"

rule clean_google_national: 
    input:
        "src/clean_google_mobility_national.R",
        "data/mobility/Global_Mobility_Report.csv"
    output:
        "data/mobility/clean/google_mobility_national.csv"
    shell:
        "Rscript {input} {output}"

rule clean_google:
    input:
        "src/clean_google_mobility.R",
        "data/mobility/Global_Mobility_Report.csv",
        "data/mobility/google_mobility_lad_lookup_200903.csv"
    output:
        "data/mobility/clean/google_mobility_lad.csv"
    shell:
        "Rscript {input} {output}"

# possible FB here... if time

rule plot_mobility_national:
    input:
        "src/plot_mobility_overview.R",
        "data/mobility/clean/google_mobility_national.csv",
        "data/mobility/clean/apple_mobility.csv",
    output:
        "output/mobility_overview_national.png"
    shell:
        "Rscript {input} {output}"
        
rule plot_wfh_exploratory: 
  input: 
      "src/wfh_exploratory.R",
      "data/census/Census-WFH.csv"
  output:
      "output/wfh_distribution_log.png"
  shell:
      "Rscript {input} {output}"
