suppressPackageStartupMessages({
    library(sf)
    library(dplyr)
})

.args <- commandArgs(trailingOnly = T)

x <- st_read(.args[1], quiet=T)
y <- st_read(.args[2], quiet=T)

x <- st_transform(x, st_crs(y))

intersection <- st_intersection(x, y)

lookup <- intersection %>%
    group_by(quadkey) %>%
    top_n(n=1, wt = st_areasha) %>%
    select(c("quadkey", "lad19cd", "lad19nm"))

st_write(lookup,
    tail(.args, 1))