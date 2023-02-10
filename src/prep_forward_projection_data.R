suppressPackageStartupMessages({
  library(data.table)
  library(purrr)
  library(dplyr)
  library(zoo)
})

if (interactive()) {
  .args <- c(
    "data/mobility/clean/google_mobility_lad.csv",
    "data/regression/models.rds",
    "output/mobility_census_date_comparison.csv",
    "data/forward_projection/forward_projection_google_mobility_lad.csv"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

google <- fread(.args[1])
comparison_dates <- c(as.Date("2020-03-22"), as.Date("2021-03-21"), as.Date("2022-03-20"))
forward_projection_dates <- c(as.Date("2021-06-20"), as.Date("2021-09-19"), as.Date("2021-12-19"))
.outputs <- tail(.args, 2)

google[, weekday := !lubridate::wday(date) %in% c(7, 1)]
google <- subset(google, weekday)

smooth_mobility <- function(x, K=20){
  x %>% 
    group_by(lad19cd, variable) %>% 
    mutate(value = rollmean(value, k=K, fill=NA, align='right'))
}

google <- smooth_mobility(google)

comparison_data <- data.table(subset(google, date %in% (comparison_dates - 2) & variable == "Residential"))
setnames(comparison_data, c("value", "variable"), c("value_weekday_MA20","setting"))
comparison_data[, weekday := NULL]

fwrite(comparison_data, .outputs[1])

forward_projection_data <- subset(google, date %in% (forward_projection_dates - 2))

fwrite(forward_projection_data, .outputs[2])
