suppressPackageStartupMessages({
  library(data.table)
})

if (interactive()) {
  .args <- c(
    "data/mobility/clean/google_mobility_lad.csv",
    "data/census/Census-WFH.csv",
    "data/geo/lad19_to_lad_21_lookup.csv",
    "data/regression/sensitivity/regression_data_4_week.csv"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

google <- fread(.args[1])
wfh <- fread(.args[2])
lad19_to_lad21 <- fread(.args[3])
census_date <- as.Date("2021-03-21")
N_PRECEDING_WEEKS <- as.numeric(stringr::str_extract(tail(.args, 1), "[[:digit:]]+"))

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

# Vector of the N weeks before the census (defined by output fn)
week_interval <- (lubridate::week(census_date)-(N_PRECEDING_WEEKS-1)):lubridate::week(census_date)

google_wday_census <- subset(
  google_wday, year == lubridate::year(census_date) & 
    week %in% week_interval)

if (nrow(subset(google_wday_census, la_name == unique(la_name)[1] & variable == unique(variable)[1])) != N_PRECEDING_WEEKS*5) {
  stop("Unexpected number of days of mobility data.")
}

regression_data <- google_wday_census[, .(value = mean(value, na.rm=T)), by = c("la_name", "lad19cd", "variable")]

regression_data[wfh, on=c("lad19cd" = "LAD21CD"), propWFH21 := propWFH21]

fwrite(regression_data, tail(.args, 1))
