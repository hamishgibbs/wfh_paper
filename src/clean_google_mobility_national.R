suppressPackageStartupMessages({
  library(data.table)
})

if (interactive()) {
  .args <- c(
    "data/mobility/Global_Mobility_Report.csv",
    ""
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

google <- fread(.args[1])

google <- subset(google, country_region == "United Kingdom")

google <- google[, lapply(.SD, function(x) replace(x, which(x==""), NA))]

google <- subset(google, is.na(sub_region_1) & is.na(sub_region_2) & is.na(metro_area))

google <- melt(google, id.vars = c("date"),
             measure.vars = colnames(google)[grep("_percent_change_from_baseline", colnames(google))])

google[, variable := gsub("_percent_change_from_baseline", "", variable)]
google[, variable := stringr::str_to_title(gsub("_", " ", variable))]
google[, variable := gsub("And", "and", variable)]
google[, variable := paste0(variable, " (Google)")]

fwrite(google, tail(.args, 1))
