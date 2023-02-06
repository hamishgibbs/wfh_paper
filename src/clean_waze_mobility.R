suppressPackageStartupMessages({
  library(data.table)
})

if (interactive()) {
  .args <- c(
    "data/mobility/Waze_Country-Level_Data.csv",
    ""
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

waze <- fread(.args[1])

waze <- subset(waze, Country == "United Kingdom")
waze$date <- as.Date(strptime(waze$Date, format = "%b %d, %Y", tz="GMT"))

waze <- melt(waze, id.vars = c("date"),
            measure.vars = c("% Change In Waze Driven Miles/KMs"))

fwrite(waze, tail(.args, 1))
