import time
import glob

SENSITIVITY_WEEKS = [1, 3, 4, 5]

rule all:
    input: 
        "rulegraph.svg",
        "output/mobility_overview_national.png",
        "output/head_tail_residential_mobility_census_date.csv",
        [f"output/sensitivity/model_fit_summary_{n}_week.csv" for n in SENSITIVITY_WEEKS],
        "output/regression_forward_projection.png",
        "output/sensitivity_summary.csv"

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
        "output/mobility_overview_lad.png",
        "output/residential_mobility_dist_key_dates.csv",
        "output/head_tail_residential_mobility_census_date.csv"
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
      "data/regression/sensitivity/regression_data_{n}_week.csv"
  shell:
      "Rscript {input} {output}"
      
rule regression: 
  input: 
      "src/regression.R",
      "src/utils.R",
      "data/regression/sensitivity/regression_data_{n}_week.csv"
  output:
      "output/sensitivity/cor_plot_{n}_week.png",
      "output/sensitivity/cor_matrix_{n}_week.csv",
      "output/sensitivity/regression_predictions_{n}_week.png",
      "output/sensitivity/coefficient_values_{n}_week.png",
      "data/regression/senstivity/models_{n}_week.rds",
      "output/sensitivity/model_fit_summary_{n}_week.csv"
  shell:
      "Rscript {input} {output}"

rule prep_regression_forward_projection: 
    input: 
      "src/prep_forward_projection_data.R",
      "data/mobility/clean/google_mobility_lad.csv",
      "data/regression/senstivity/models_4_week.rds"
    output:
      "output/mobility_census_date_comparison.csv",
      "data/forward_projection/forward_projection_google_mobility_lad.csv"
    shell:
      "Rscript {input} {output}"

rule regression_forward_projection: 
  input: 
      "src/forward_projection.R",
      "src/utils.R",
      "data/forward_projection/forward_projection_google_mobility_lad.csv",
      "data/regression/senstivity/models_4_week.rds",
      "data/geo/Local_Authority_Districts_December_2021_UK_BUC.geojson",
  output:
      "output/regression_forward_projection.png"
  shell:
      "Rscript {input} {output}"

rule summarise_sensitivity: 
  input: 
      "src/summarise_sensitivity.R",
      expand("output/sensitivity/model_fit_summary_{n}_week.csv", n=SENSITIVITY_WEEKS)
  output:
      "output/sensitivity_summary.csv"
  shell:
      "Rscript {input} {output}"
    