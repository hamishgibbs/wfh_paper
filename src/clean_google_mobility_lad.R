suppressPackageStartupMessages({
  library(data.table)
})

if (interactive()) {
  .args <- c(
    "data/mobility/Global_Mobility_Report.csv",
    "data/mobility/google_mobility_lad_lookup_200903.csv",
    "data/geo/lad19_to_lad_21_lookup.csv",
    ""
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

google <- fread(.args[1])

google <- subset(google, country_region == "United Kingdom")

# Missing values in the input are "", not NA...
google <- google[, lapply(.SD, function(x) replace(x, which(x==""), NA))]

google_places_lu <- fread(.args[2])
lad19_to_lad21 <- fread(.args[3])

# Name for 'Saint Helens District' in the lookup
# is now 'Metropolitan Borough of St Helens' in Google data
google$sub_region_2 <- gsub("Metropolitan Borough of St Helens", "Saint Helens District", 
                            google$sub_region_2)

google[google_places_lu, 
       on = c("sub_region_1", "sub_region_2"), 
       c("la_name", "lad19cd") := .(la_name, lad19cd)]

google <- google[!is.na(la_name)]

google <- melt(google, id.vars = c("la_name", "lad19cd", "date"),
    measure.vars = colnames(google)[grep("_percent_change_from_baseline", colnames(google))])

google <- google[substr(google$lad19cd, 1, 1) == "E"]

google[, variable := gsub("_percent_change_from_baseline", "", variable)]
google[, variable := stringr::str_to_title(gsub("_", " ", variable))]
google[, variable := gsub("And", "and", variable)]

# Drop Google districts with no corresponding WFH data (because of district changes)
google <- subset(google, !lad19cd %in% lad19_to_lad21$google_lad19cd)

fwrite(google, tail(.args, 1))


