import time

TIMESTAMP = int(time.time())

rule all:
    input: 
        f"metadata/rulegraph/rulegraph_{TIMESTAMP}.dot",
        f"metadata/dag/dag_{TIMESTAMP}.dot",
        "output/fb_mobility_lad.csv",
        "output/mobility_overview.png",
        "output/wfh_logged.png"

rule rulegraph:
    output: "metadata/rulegraph/rulegraph_{TIMESTAMP}.dot"
    shell:
        "snakemake --rulegraph > {output}"

rule dag:
    output: "metadata/dag/dag_{TIMESTAMP}.dot"
    shell:
        "snakemake --dag > {output}"

rule all_quadkeys:
    input: "data/mobility/fb_movement_filtered.csv"
    output: "data/tmp/all_quadkeys.txt"
    shell:
        """
        set +o pipefail;
        tail -n+2 {input} | cut -d',' -f4 > {output};
        tail -n+2 {input} | cut -d',' -f5 >> {output};
        """

rule unique_quadkeys:
    input: "data/tmp/all_quadkeys.txt"
    output: "data/tmp/quadkey_unique.txt"
    shell:
        "cat {input} | sort | uniq > {output}"

rule quadkey_to_geojson:
    input: 
        src="src/quadkey_to_geojson.py",
        qks="data/tmp/quadkey_unique.txt"
    output: "data/geo/quadkey.geojson"
    shell:
        "cat {input.qks} | {input.src} > {output}"

rule quadkey_to_lad:
    input: 
        "src/max_overlap_spatial_join.R",
        "data/geo/quadkey.geojson",
        "data/geo/Local_Authority_Districts_December_2019_Boundaries_UK_BFC/Local_Authority_Districts_December_2019_Boundaries_UK_BFC.shp"
    output: "data/geo/quadkey_to_lad19.csv"
    shell:
        "Rscript {input} {output}"

rule clean_facebook:
    input: 
        "src/clean_facebook.R",
        "data/mobility/fb_movement_filtered.csv",
        "data/geo/quadkey_to_lad19.csv",
    output: "output/fb_mobility_lad.csv"
    shell:
        "Rscript {input} {output}"

rule clean_google:
    input:
        "src/clean_google_mobility.R",
        "data/mobility/Global_Mobility_Report.csv",
        "data/mobility/google_mobility_lad_lookup_200903.csv"
    output:
        "output/google_mobility_lad.csv"
    shell:
        "Rscript {input} {output}"

rule plot_mobility:
    input:
        "src/plot_mobility_overview.R",
        "output/google_mobility_lad.csv",
        "data/mobility/apple_mobility_report.csv",
    output:
        "output/mobility_overview.png"
    shell:
        "Rscript {input} {output}"
        
rule plot_wfh_exploratory: 
  input: 
      "data/census/Census-WFH.csv"
  output:
      "output/wfh_logged.png"
  shell:
      "Rscript {input} {output}"
