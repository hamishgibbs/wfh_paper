suppressPackageStartupMessages({
  library(data.table)
})

if (interactive()) {
  .args <- c(
    "data/geo/quadkey_to_lad19.csv",
    list.files("../../fb_population_archive/BritainMovementBetweenTiles/raw", pattern = ".csv", full.names = T),    
    "data/mobility/fb_mobility.csv"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

qk2lad <- fread(.args[1], colClasses = c("quadkey"="character"))

read_fb <- function(fn){
  print(fn)
  fb_mob <- fread(fn, 
        select=c("date_time", "n_crisis", "n_baseline", "start_quadkey", "end_quadkey"),
        colClasses = c("start_quadkey"="character", "end_quadkey"="character"))
  fb_mob[complete.cases(fb_mob[, 'n_crisis'])]
}

fns <- sort(.args[2:(length(.args)-1)])

fns_20_21_1600 <- fns[(stringr::str_detect(fns, "_2020-") | stringr::str_detect(fns, "_2021-")) & stringr::str_detect(fns, "1600")]

fb_mob <- lapply(fns_20_21_1600, read_fb)
fb_mob <- do.call(rbind, fb_mob)

fwrite(fb_mob, tail(.args, 1))


