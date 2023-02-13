suppressPackageStartupMessages({
  library(data.table)
})

if (interactive()) {
  .args <- c(
    "output/sensitivity/model_fit_summary_1_week.csv",
    "output/sensitivity/model_fit_summary_3_week.csv",
    "output/sensitivity/model_fit_summary_4_week.csv",
    "output/sensitivity/model_fit_summary_5_week.csv",
    "output/sensitivity_summary.csv"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

format_comparison_table <- function(x){
  n_preceding_weeks <-  as.numeric(stringr::str_extract(x, "[[:digit:]]+"))
  sensitivity_table <- fread(x)
  sensitivity_table <- subset(sensitivity_table, Coefficient == "x")
  sensitivity_table$n_weeks <- n_preceding_weeks
  return(sensitivity_table[, c("Setting", "Estimate", "l-95% CI", "u-95% CI", "n_weeks")])
}

comparison_table <- do.call(rbind, 
        lapply(.args[1:(length(.args)-1)], 
               format_comparison_table))

comparison_table_wide <- dcast(comparison_table, Setting ~ n_weeks, 
                               value.var = c("Estimate", "l-95% CI", "u-95% CI"))


fwrite(comparison_table_wide, tail(.args, 1))
