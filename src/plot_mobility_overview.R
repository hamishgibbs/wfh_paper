suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(purrr)
  library(dplyr)
  library(zoo)
})

if (interactive()) {
  .args <- c(
    "data/mobility/clean/google_mobility_national.csv",
    "data/mobility/clean/apple_mobility.csv",
    "output/mobility_overview_national.png"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

goog_mob <- fread(.args[1])
apple_mob <- fread(.args[2])


smooth_mobility <- function(x, K=30){
  x %>% 
    group_by(variable) %>% 
    mutate(value = rollmean(value, k=K, fill=NA, align='right'))
}

goog_mob_smooth <- smooth_mobility(goog_mob)
apple_mob_smooth <- smooth_mobility(apple_mob)

p <- ggplot(data = rbind(goog_mob_smooth, apple_mob_smooth)) + 
  geom_path(aes(x = date, y = value, color=variable)) + 
  geom_vline(xintercept = as.Date("2021-03-21"), color="blue", linetype="dashed", size=0.3) + 
  theme_classic()

ggsave(tail(.args, 1), 
       p, 
       width=10, 
       height = 6, 
       units = "in")
