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

fwrite(apple, tail(.args, 1))
