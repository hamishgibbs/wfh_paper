google_settings_pal <- c(
  "Retail and Recreation"='#e41a1c', 
  "Grocery and Pharmacy"='#377eb8', 
  "Parks"='#4daf4a', 
  "Transit Stations"='#984ea3', 
  "Workplaces"='#ff7f00', 
  "Residential"='#f781bf'
)

data_sources <- list(
  google = "Google mobility reports",
  ONS = "ONS"
)

add_data_source_annotation <- function(p, annotation, position="bottom.right", size=10){
  return (
    cowplot::ggdraw(p) + cowplot::draw_figure_label(label = annotation, 
                                                    position = position, 
                                                    size = size)
  )
}
