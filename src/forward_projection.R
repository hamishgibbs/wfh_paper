suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(purrr)
  library(dplyr)
  library(zoo)
})

if (interactive()) {
  .args <- c(
    "data/mobility/clean/google_mobility_lad.csv",
    "data/regression/models.rds",
    "output/google_mobility_focus_lads.png",
    "output/regression_forward_projection_focus_lads.png"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

# Remove weekends 
# Smooth with 30 day rolling MA

google <- fread(.args[1])
models <- readr::read_rds(.args[2])
census_date <- as.Date("2021-03-21")
.outputs <- tail(.args, 2)

google[, weekday := !lubridate::wday(date) %in% c(7, 1)]

google_subset <- subset(google, weekday & variable == "Residential" & date > census_date)

smooth_mobility <- function(x, K=20){
  x %>% 
    group_by(lad19cd, variable) %>% 
    mutate(value = rollmean(value, k=K, fill=NA, align='right'))
}
google_subset <- smooth_mobility(google_subset)

google_subset <- as.data.table(subset(google_subset, complete.cases(google_subset)))
google_subset[, x := value]

set.seed(100)
N_FOCUS_LADS = 6
focus_lads <- sample(unique(google_subset$lad19cd), N_FOCUS_LADS)

google_subset <- subset(google_subset, lad19cd %in% focus_lads)

N_DRAWS = 100

forward_predictions <- brms::posterior_predict(object=models[["Residential"]], 
                        newdata=google_subset[, c("x")], 
                        ndraws = N_DRAWS)

forward_predictions <- as.data.table(t(forward_predictions))

forward_predictions$date <- google_subset$date
forward_predictions$lad19cd <- google_subset$la_name

forward_predictions <- melt(forward_predictions, id.vars=c("date", "lad19cd"))

p <- ggplot(data = google_subset) + 
  geom_path(aes(x = date, y = value), size=1) + 
  facet_wrap(~lad19cd)

ggsave(.outputs[1],
       p,
       width=10,
       height=6, 
       units="in")

p <- ggplot(data = as.data.frame(forward_predictions) %>% group_by(date)) + 
  ggdist::stat_lineribbon(aes(x = date, y = value), size=0.1) + 
  geom_hline(yintercept=0, linetype="dashed", size=0.75) + 
  scale_fill_brewer() + 
  facet_wrap(~lad19cd) + 
  theme_classic()

ggsave(.outputs[2],
       p,
       width=10,
       height=6, 
       units="in")

# Maps of forward projection (less than 0 removed) - for 