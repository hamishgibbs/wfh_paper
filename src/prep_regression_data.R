suppressPackageStartupMessages({
  library(data.table)
})

if (interactive()) {
  .args <- c(
    "data/mobility/clean/google_mobility_lad.csv",
    "data/census/Census-WFH.csv",
    "data/geo/lad19_to_lad_21_lookup.csv",
    "data/regression/regression_data.csv"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

google <- fread(.args[1])
wfh <- fread(.args[2])
lad19_to_lad21 <- fread(.args[3])
census_date <- as.Date("2021-03-21")

wfh <- wfh[, c("LAD21CD", "LAD21NM", "TotPop21", "WFH21", "propWFH21")]
wfh <- wfh[substr(wfh$LAD21CD, 1, 1) == "E"]
wfh <- unique(wfh)

# Drop WFH districts with no corresponding google mobility data (because of district changes)
wfh <- subset(wfh, !LAD21CD %in% lad19_to_lad21$wfh_LAD21CD)

# Take average weekday mobility over the previous 4 weeks from the census date
# 7 = Saturday, 1 = Sunday
google[, weekday := !lubridate::wday(date) %in% c(7, 1)]
google[, week := lubridate::week(date)]
google[, year := lubridate::year(date)]
google_wday <- subset(google, weekday)

google_wday_census <- subset(google_wday, year == lubridate::year(census_date) & week %in% (lubridate::week(census_date)-3):lubridate::week(census_date))

if (nrow(subset(google_wday_census, la_name == unique(la_name)[1] & variable == unique(variable)[1])) != 20) {
  stop("Unexpected number of days of mobility data.")
}

regression_data <- google_wday_census[, .(value = mean(value, na.rm=T)), by = c("la_name", "lad19cd", "variable")]

regression_data[wfh, on=c("lad19cd" = "LAD21CD"), propWFH21 := propWFH21]

#regression_data[regression_data$variable == "Residential", "value"] <- -1 * regression_data[regression_data$variable == "Residential", "value"]
#regression_data$value <- -1 * regression_data$value

#regression_data[regression_data$variable != "Residential", "variable"] <- paste0(regression_data[regression_data$variable != "Residential"]$variable, " (Inverse)")

fwrite(regression_data, tail(.args, 1))
