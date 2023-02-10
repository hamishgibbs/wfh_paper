import time
import glob

rule all:
    input: 
        "rulegraph.svg",
        "output/mobility_overview_national.png",
        "output/mobility_overview_lad.png",
        "output/coefficient_values.png",
        "output/regression_forward_projection.png"

rule current_rulegraph: 
  input: 
      "Snakefile"
  output:
      "rulegraph.svg"
  shell:
      "snakemake --rulegraph | dot -Tsvg > {output}"

rule clean_google_national: 
    input:
        "src/clean_google_mobility_national.R",
        "data/mobility/Global_Mobility_Report.csv"
    output:
        "data/mobility/clean/google_mobility_national.csv"
    shell:
        "Rscript {input} {output}"

rule clean_google_lad:
    input:
        "src/clean_google_mobility_lad.R",
        "data/mobility/Global_Mobility_Report.csv",
        "data/mobility/google_mobility_lad_lookup_200903.csv",
        "data/geo/lad19_to_lad_21_lookup.csv"
    output:
        "data/mobility/clean/google_mobility_lad.csv"
    shell:
        "Rscript {input} {output}"

rule plot_mobility_lad:
    input:
        "src/plot_google_mobility_lad.R",
        "src/utils.R",
        "data/mobility/clean/google_mobility_lad.csv"
    output:
        "output/mobility_overview_lad.png"
    shell:
        "Rscript {input} {output}"

rule plot_mobility_national:
    input:
        "src/plot_google_mobility_national.R",
        "src/utils.R",
        "data/mobility/clean/google_mobility_national.csv",
        "data/interventions/key_interventions.csv"
    output:
        "output/mobility_overview_national.png"
    shell:
        "Rscript {input} {output}"
    
rule prep_regression_data: 
  input: 
      "src/prep_regression_data.R",
      "data/mobility/clean/google_mobility_lad.csv",
      "data/census/Census-WFH.csv",
      "data/geo/lad19_to_lad_21_lookup.csv"
  output:
      "data/regression/regression_data.csv"
  shell:
      "Rscript {input} {output}"
      
      
rule regression: 
  input: 
      "src/regression.R",
      "src/utils.R",
      "data/regression/regression_data.csv"
  output:
      "output/cor_plot.png",
      "output/cor_matrix.csv",
      "output/regression_predictions.png",
      "output/coefficient_values.png",
      "data/regression/models.rds",
      "output/model_fit_summary.csv"
  shell:
      "Rscript {input} {output}"

rule prep_regression_forward_projection: 
    input: 
      "src/prep_forward_projection_data.R",
      "data/mobility/clean/google_mobility_lad.csv",
      "data/regression/models.rds"
    output:
      "output/mobility_census_date_comparison.csv",
      "data/forward_projection/forward_projection_google_mobility_lad.csv"
    shell:
      "Rscript {input} {output}"

rule regression_forward_projection: 
  input: 
      "src/forward_projection.R",
      "data/forward_projection/forward_projection_google_mobility_lad.csv",
      "data/regression/models.rds",
      "data/geo/Local_Authority_Districts_December_2021_UK_BUC.geojson",
  output:
      "output/regression_forward_projection.png"
  shell:
      "Rscript {input} {output}"

