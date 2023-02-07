suppressPackageStartupMessages({
  library(data.table)
})

if (interactive()) {
  .args <- c(
    "data/mobility/apple_mobility_report.csv",
    ""
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

apple <- fread(.args[1])

apple <- subset(apple, country == "United Kingdom" & geo_type == "country/region")

apple <- melt(apple, id.vars = c("date"),
               measure.vars = c("driving", "transit", "walking"))

apple[, variable := paste0(stringr::str_to_title(variable), " (Apple)")]

fwrite(apple, tail(.args, 1))
