suppressPackageStartupMessages({
  library(data.table)
})

if (interactive()) {
  .args <- c(
    "data/Global_Mobility_Report.csv",
    "data/google_mobility_lad_lookup_200903.csv",
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

# Name for 'Saint Helens District' in lookup
# is now 'Metropolitan Borough of St Helens' in Google data
google$sub_region_2 <- gsub("Metropolitan Borough of St Helens", "Saint Helens District", 
                            google$sub_region_2)

google[google_places_lu, 
       on = c("sub_region_1", "sub_region_2"), 
       c("la_name", "lad19cd") := .(la_name, lad19cd)]

google <- google[!is.na(la_name)]

google <- melt(google, id.vars = c("la_name", "lad19cd", "date"),
    measure.vars = colnames(google)[grep("_percent_change_from_baseline", colnames(google))])

google$variable <- gsub("_percent_change_from_baseline", "", google$variable)

fwrite(google, tail(.args, 1))


