google_settings_pal <- c(
  "Retail and Recreation"=rgb(255, 0, 41, maxColorValue = 255), 
  "Grocery and Pharmacy"=rgb(55, 126, 184, maxColorValue = 255), 
  "Parks"=rgb(102, 166, 30, maxColorValue = 255), 
  "Transit Stations"=rgb(152, 78, 163, maxColorValue = 255), 
  "Workplaces"=rgb(0, 210, 213, maxColorValue = 255), 
  "Residential"=rgb(255, 127, 0, maxColorValue = 255)
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
