suppressPackageStartupMessages({
  library(data.table)
  library(sf)
  library(ggplot2)
})

if (interactive()) {
  .args <- c(
    "data/forward_projection/forward_projection_google_mobility_lad.csv",
    "data/regression/models.rds",
    "data/geo/Local_Authority_Districts_December_2021_UK_BUC.geojson",
    "output/regression_forward_projection.png"
  )
} else {
  .args <- commandArgs(trailingOnly = T)
}

google <- fread(.args[1])
models <- readr::read_rds(.args[2])
lad21 <- st_read(.args[3], quiet = T)
census_date <- as.Date("2021-03-21")

google[, x := value]

N_DRAWS = 100

forward_predictions <- brms::posterior_predict(object=models[["Residential"]], 
                        newdata=google[, c("x")], 
                        ndraws = N_DRAWS)

forward_predictions <- as.data.table(t(forward_predictions))

forward_predictions$date <- google$date
forward_predictions$la_name <- google$la_name
forward_predictions$lad19cd <- google$lad19cd

forward_predictions <- melt(forward_predictions, id.vars=c("date", "la_name", "lad19cd"))

forward_predictions_mean <- forward_predictions[, .(mean_value = mean(value, na.rm=T)), by = c("date", "la_name", "lad19cd")]

forward_predictions_mean[, period := 3*round(as.numeric(difftime(as.Date(date), census_date, units = "days"))/90, 0)]
forward_predictions_mean[, period := factor(period, 
                                            levels = sort(unique(period)), 
                                            labels = paste0("+", sort(unique(period)), " months"))]

forward_predictions_mean <- ggutils::classify_intervals(forward_predictions_mean, "mean_value", c(-Inf, 0, 25, 75, 100, Inf))
forward_predictions_mean[, value := gsub("\\(-Inf to 0\\]", "<0", value)]
forward_predictions_mean[, value := gsub("\\(100 to Inf\\]", "100+", value)]
forward_predictions_mean[, value := factor(value, levels = c("<0", "(0 to 25]", "(25 to 75]", "(75 to 100]", "100+"))]

forward_predictions_mean_geom <- dplyr::left_join(
  forward_predictions_mean,
  dplyr::select(lad21, c("LAD21CD", "geometry")), 
  by=c("lad19cd"= "LAD21CD")) %>% st_as_sf

merge_conflict_districts <- subset(lad21, substr(LAD21CD, 1, 1) == "E")
merge_conflict_districts <- subset(merge_conflict_districts, LAD21CD %in% setdiff(merge_conflict_districts$LAD21CD, forward_predictions_mean_geom$lad19cd))

p <- ggplot() + 
  ggutils::plot_basemap("United Kingdom", country_size = 0, world_fill = "#EFEFEF") + 
  geom_sf(data = forward_predictions_mean_geom, 
          aes(fill = value), size=0.1, color="black") + 
  colorspace::scale_fill_discrete_sequential("Mint",
                                             name="Predicted\n% WFH",
                                             guide = guide_legend(order = 1)) + 
  ggnewscale::new_scale_fill() + 
  geom_sf(data = merge_conflict_districts, 
          aes(fill = "Missing data"), size=0.1, color="black") + 
  scale_fill_manual(values = c("Missing data"="#96AFB8"), 
                    name="",
                    guide = guide_legend(order = 2)) +
  theme(legend.title = NULL) + 
  facet_wrap(~period, nrow=1) + 
  theme_void() + 
  ggutils::geo_lims(forward_predictions_mean_geom) + 
  theme(legend.position = "bottom")

ggsave(tail(.args, 1),
       p,
       width=10,
       height=5.2, 
       units="in")
