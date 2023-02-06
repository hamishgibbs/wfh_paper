suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

if (interactive()) {
  .args <- c(
    "data/mobility/fb_mobility.csv",
    "data/geo/quadkey_to_lad19.csv",
    "output/fb_mobility_lad.csv"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

fb_mob <- fread(.args[1], colClasses = c("start_quadkey"="character", "end_quadkey"="character"))
qk2lad <- fread(.args[2], colClasses = c("quadkey"="character"))

# which time period? 16:00
#fb_mob <- fb_mob[lubridate::hour(fb_mob$date_time) == 16]

fb_mob[, date := as.Date(fasttime::fastPOSIXct(date_time))]
fb_mob[, date_time := NULL]
fb_mob[, within := start_quadkey == end_quadkey]
fb_mob[, n_baseline := NULL]

fb_mob_within <- dcast(fb_mob, date + start_quadkey + end_quadkey ~ within, 
      value.var = "n_crisis",
      fun.aggregate = sum)

fb_mob_within[qk2lad, on=c(start_quadkey = "quadkey"), lad19cd := lad19cd]
fb_mob_within[, start_quadkey := NULL]
fb_mob_within[, end_quadkey := NULL]

lad_within <- fb_mob_within[, lapply(.SD, sum, na.rm=TRUE), 
              by=c("date", "lad19cd") ]

lad_within <- lad_within[substr(lad_within$lad19cd, 1, 1) == "E"]

#lad_within[, value := `FALSE` / (`FALSE` + `TRUE`)]

fwrite(lad_within, tail(.args, 1))

p <- ggplot(data=lad_within) + 
  geom_vline(aes(xintercept=as.Date("2021-03-21")), color="blue", linetype="dashed") + 
  geom_line(aes(x = date, y = `TRUE`, group=lad19cd), size = 0.1) + 
  scale_y_continuous(labels = scales::percent) + 
  theme_classic()

p
plotly::ggplotly(p)

View(subset(fb_mob_within, lad19cd == "E08000003"))

# when there is a true - that there is no False, and vice versa

focus_area <- "E07000067"

focus_qks <- subset(qk2lad, lad19cd == focus_area)$quadkey

focus_fb_mob <- subset(fb_mob, start_quadkey %in% focus_qks | end_quadkey %in% focus_qks)

p <- ggplot(focus_fb_mob[, .(n_crisis_adj = sum(n_crisis_adj)), by = c("date", "within")]) + 
  geom_path(aes(x = date, y = n_crisis_adj, color=within)) + 
  geom_vline(aes(xintercept=as.Date("2021-03-21")), color="blue", linetype="dashed") + 
  labs(title = paste("LAD: ", focus_area), x=NULL, y = "Number of users", color="Travel\nwithin\ntile") + 
  theme_classic() + 
  scale_y_continuous(labels = scales::comma)

  
focus_qk2lad <- subset(qk2lad, lad19cd == focus_area)
  
focus_fb_mob_quadkeys <- subset(fb_mob, start_quadkey %in% focus_qk2lad$quadkey)

p <- ggplot(data=focus_fb_mob_quadkeys) + 
  geom_path(aes(x = date, y = n_crisis, group=paste(start_quadkey, end_quadkey),
                color=start_quadkey == end_quadkey), size=0.1) + 
  scale_y_continuous(trans="log10")

plotly::ggplotly(p)



# where are these tiles? 

focus_qk <- c("120202002310", "120202002132")

focus_qk

p <- ggplot(subset(fb_mob, start_quadkey == focus_qk[1] & end_quadkey == focus_qk[1])) + 
  scale_x_date(limits = c(min(fb_mob$date), max(fb_mob$date))) + 
  geom_path(aes(x = date, y = n_crisis))

p

View(data.frame(qk=unique(fb_mob$start_quadkey)))

fb_mob

# What could be causing certain tiles to appear and disappear in the dataset with a big spike - that shouldn't be happening
# Could select only those intra-cell journeys that have an entire dataset


n_days_tiles <- subset(fb_mob, within)[, .(n_days = length(unique(date))), by = c("start_quadkey")]

max_days_tiles <- n_days_tiles[n_days == max(n_days)]$start_quadkey

fb_mob_max_days <- subset(fb_mob, within & start_quadkey %in% max_days_tiles)


#ggsave("~/Downloads/both_metrics_seem_messed_up_fixed_possibly.png", p)
p
plotly::ggplotly(p)

subset(focus_fb_mob, date == as.Date("2021-03-08"))

subset(qk2lad, lad19cd=="E07000067")

# What is the number of quadkeys per day? 

# Ahh - this explains it - there are way more quadkeys later in the dataset than before. what is that about? 
# Are 

p <- ggplot(data=fb_mob[, .(n_start_quadkey = length(unique(start_quadkey))), by = c("date")]) + 
  geom_path(aes(x = date, y = n_start_quadkey)) + 
  labs(x = NULL, y = "Number of quadkeys", title = "Number of unique quadkeys per day") + 
  theme_classic()

p
ggsave("output/plot2.png", p)
plotly::ggplotly(p)

# How many records per day? 
p <- ggplot(data=fb_mob[, .(n_rows = .N), by = c("date")]) + 
  geom_path(aes(x = date, y = n_rows)) + 
  labs(x = NULL, y = "Number of rows", title = "Number of rows per day") + 
  theme_classic()

p

# Number of rows is the same but the number of unique quadkeys changes?? 

# Select dates from the different periods and see what the quadkeys look like

normal_period <- as.Date("2020-09-04")
low_qk_period <- as.Date("2021-03-26")
high_qk_period <- as.Date("2021-07-03")

fwrite(data.frame(unique(subset(fb_mob, date == normal_period)$start_quadkey)), "output/quadkey_challenge/normal_qk.csv", 
       col.names = F)
fwrite(data.frame(unique(subset(fb_mob, date == low_qk_period)$start_quadkey)), "output/quadkey_challenge/low_qk.csv", 
       col.names = F)
fwrite(data.frame(unique(subset(fb_mob, date == high_qk_period)$start_quadkey)), "output/quadkey_challenge/high_qk.csv", 
       col.names = F)

# are the quadkeys present in the low qk period also present in the high qk period? 

setdiff(subset(fb_mob, date == low_qk_period)$start_quadkey, subset(fb_mob, date == normal_period)$start_quadkey)

# some of them are - where are these tiles? 

# So - possibly - many tiles are being removed and their counts are being sent to other tiles? 
# So the overall count stays the same but the number of areas changes? 
# Why was this not a problem in my upgrade report? 

# Does the number of LADs change drastically over time? 
ggplot(lad_within[, .(n_lad = length(unique(lad19cd))), by = c("date")]) + 
  geom_path(aes(x = date, y = n_lad))
# Yes - it follows the same pattern as the quadkeys
# But counts doesn't?

p <- ggplot(data = fb_mob[, .(n_crisis = sum(n_crisis, na.rm = T)), by = c("date")]) + 
  geom_path(aes(x = date, y = n_crisis)) + 
  labs(y = "Number of users", x = NULL, title="Total number of users") + 
  theme_classic()

ggsave("output/plot3.png", p)


# Then does the average number of individuals per tile change drastically over time? 
p <- ggplot(data = fb_mob[, .(n_crisis = sum(n_crisis)), by = c("date", "start_quadkey")][, .(mean_n_crisis = mean(n_crisis)), by = c("date")]) + 
  geom_path(aes(x = date, y = mean_n_crisis)) + 
  labs(x = NULL, title = "Mean number of users per tile", y = "Mean number of users") + 
  theme_classic()

ggsave("output/plot5.png", p)

library(sf)
tiles <- lapply(c(
  "output/quadkey_challenge/normal_qk.geojson", 
  "output/quadkey_challenge/low_qk.geojson", 
  "output/quadkey_challenge/high_qk.geojson"), st_read)

tiles[[1]]$period <- "Period 1"
tiles[[2]]$period <- "Period 2"
tiles[[3]]$period <- "Period 3"

tiles <- do.call(rbind, tiles)

p <- ggplot(data = tiles) + 
  geom_sf() + 
  facet_wrap(~period, nrow=1) + 
  theme_classic()

ggsave("output/plot4.png", p)

p


# is it just duplicates? 
p <- ggplot(data = fb_mob[, .(n_times_tile_recorded = .N), by = c("date", "start_quadkey")][, .(mean_n_times_tile_recorded = mean(n_times_tile_recorded)), by = c("date")]) + 
    geom_path(aes(x = date, y = mean_n_times_tile_recorded)) + 
  labs(x = NULL, title = "Average number of times a tile is recorded per day", subtitle = "Many are duplicated much more than expected", y = "Average times tile is recorded") + 
  theme_classic()

ggsave("output/plot6.png", p)

# Yes - which means that - somehow - in the data archive that I collected - there are 2 
# periods (perfectly coinciding with the census)where the same number of individuals 
# were counted and assigned to a seemingly arbitrary collection of the wrong tiles.
# So the headline count stays the same but people are allocated to all the wrong areas
# So the movement data archive I downloaded is not usable (I think) and they have stopped releasing the dataset...



# Is this a problem with the input data? 
# Go back to the original?

#ggsave("output/both_metrics_seem_messed_up.png", p)

# Something seems messed up with population inside of areas ... 
# To handle this - try to measure travel outside of LADs pinned against first day values

# this is an important intermediate finding but it was uncovered in a specific context - how to retain this info with minimal effort? 

# Is it at all possible that by divding by some factor these will be corrected? 

# What are the periods? 
factor_periods <- list(
  period1=list(
    start=as.Date("2021-03-08"), 
    end=as.Date("2021-04-12"),
    factor=25),
  period2=list(
    start=as.Date("2021-05-01"), 
    end=as.Date("2021-12-31"),
    factor=4)
  )

factors <- data.table(date=seq.Date(from=min(fb_mob$date), max(fb_mob$date), by="day"), exfactor=1)

factors$exfactor[factors$date %in% seq.Date(from=factor_periods$period1$start, to=factor_periods$period1$end, by="day")] <- factor_periods$period1$factor
factors$exfactor[factors$date %in% seq.Date(from=factor_periods$period2$start, to=factor_periods$period2$end, by="day")] <- factor_periods$period2$factor

fb_mob[factors, on=c("date"), factor := exfactor]

fb_mob[, n_crisis_adj := n_crisis / factor]

# find the periods that overlap the period dates and apply the factor, then join on.


outside_fb_mob <- subset(fb_mob, !within)

outside_fb_mob[qk2lad, on=c(start_quadkey = "quadkey"), start_lad19cd := lad19cd]
outside_fb_mob[qk2lad, on=c(end_quadkey = "quadkey"), end_lad19cd := lad19cd]

outside_fb_mob[, within_lad := start_lad19cd == end_lad19cd]

outside_fb_mob <- subset(outside_fb_mob, !within_lad)

outside_fb_mob <- outside_fb_mob[, .(n_crisis = sum(n_crisis, na.rm = T)), by = c("start_lad19cd", "date")]
outside_fb_mob <- outside_fb_mob[substr(outside_fb_mob$start_lad19cd, 1, 1) == "E"]

# Measure against starting value
# Could replace this with baseline if time
benchmark_values <- subset(outside_fb_mob, date == min(date))
benchmark_values[, n_baseline := n_crisis]

outside_fb_mob[benchmark_values, on=c("start_lad19cd"), n_baseline := n_baseline]

outside_fb_mob[, n_crisis_adj := (n_crisis - n_baseline) / n_baseline]

p <- ggplot(data = outside_fb_mob) + 
  geom_path(aes(x = date, y = n_crisis_adj, group = start_lad19cd))

plotly::ggplotly(p)



ggplot(data = subset(fb_mob_within, lad19cd == "E08000003")) + 
  geom_path(aes(x = date, y = `FALSE`)) + 
  geom_path(aes(x = date, y = `TRUE`), color="red")



lad_within <- lad_within %>% 
  group_by(lad19cd) %>% 
  mutate(value = rollmean(value, k=K, fill=NA, align='right'))


fb_mob %>% 
  group_by(date) %>% 
  summarise(n_crisis = sum(n_crisis)) %>% 
  ggplot() + 
  geom_vline(aes(xintercept=as.Date("2021-03-21")), color="blue", linetype="dashed") + 
  geom_path(aes(x = date, y = n_crisis))

