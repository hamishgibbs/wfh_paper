suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(ggrepel)
  library(purrr)
  library(dplyr)
  library(zoo)
})

if (interactive()) {
  .args <- c(
    "data/mobility/clean/google_mobility_national.csv",
    "data/mobility/clean/apple_mobility.csv",
    "data/interventions/key_interventions.csv",
    "output/mobility_overview_national.png"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

goog_mob <- fread(.args[1])
apple_mob <- fread(.args[2])
interventions <- fread(.args[3])

interventions[, date := as.Date(date)]

smooth_mobility <- function(x, K=30){
  x %>% 
    group_by(variable) %>% 
    mutate(value = rollmean(value, k=K, fill=NA, align='right'))
}

goog_mob_smooth <- smooth_mobility(goog_mob)
apple_mob_smooth <- smooth_mobility(apple_mob)

category_levels <- c(
  "Driving (Apple)",
  "Transit (Apple)",
  "Walking (Apple)",
  "Residential (Google)", 
  "Workplaces (Google)", 
  "Retail and Recreation (Google)", 
  "Grocery and Pharmacy (Google)", 
  "Transit Stations (Google)", 
  "Parks (Google)"
)

mob_smooth <- data.table(rbind(goog_mob_smooth, apple_mob_smooth))

mob_smooth[, variable := factor(variable, level =category_levels)]

mob_smooth[, label_cap := date == max(date), by = c("variable")]

LABEL_NUDGE_X <- 40

label_coords <- mob_smooth[mob_smooth$label_cap]
label_coords[, label := variable]
#label_coords$date <- max(mob_smooth$date) + LABEL_NUDGE_X

interventions[mob_smooth[, .(value = max(value)), by = c("date")], on = "date", value := value]

census_date <- data.frame(date = as.Date("2021-03-21"), value = NA, label="Census Date")

census_date$value <- min(subset(mob_smooth, date == census_date$date)$value)

pal <- c('#e41a1c','#377eb8','#4daf4a','#984ea3','#ff7f00','#606060','#a65628','#f781bf','#999999')

p <- ggplot(data = mob_smooth) + 
  geom_hline(yintercept = 0, color="black", linetype="dashed", size=0.2) + 
  geom_path(aes(x = date, y = value/100, color=variable)) + 
  scale_color_manual(values = pal) + 
  geom_label_repel(data=label_coords, 
                   aes(label=label, x = date, y = value/100, color=variable),
                   xlim = c(max(mob_smooth$date) + LABEL_NUDGE_X, NA),
                   na.rm = TRUE,
                   min.segment.length = 0,
                   segment.linetype = 3) + 
  geom_label_repel(data=interventions, 
                   aes(x = date, y = value/100, label=label),
                   ylim = c(1, NA),
                   direction = "x",
                   nudge_y = 3,
                   na.rm = TRUE,
                   min.segment.length = 0,
                   segment.linetype = 4) + 
  geom_label_repel(data=census_date, 
                   aes(x = date, y = value/100, label=label),
                   ylim = c(NA, -0.85),
                   color="red",
                   fontface="bold",
                   direction = "x",
                   nudge_y = 3,
                   na.rm = TRUE,
                   min.segment.length = 0,
                   segment.linetype = 4) + 
  theme_classic() + 
  theme(legend.position = "none") + 
  scale_x_date(limits = c(min(mob_smooth$date), max(mob_smooth$date)+LABEL_NUDGE_X*10)) + 
  scale_y_continuous(labels = scales::percent, limits = c(-0.9, 1.1)) + 
  labs(x = NULL, y = "Percentage Change from Baseline")

ggsave(tail(.args, 1), 
       p, 
       width=9, 
       height = 6, 
       units = "in")

