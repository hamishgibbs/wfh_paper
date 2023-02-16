google_settings_pal <- c(
  "Retail and Recreation"=rgb(181, 137, 0, maxColorValue = 255), 
  "Grocery and Pharmacy"=rgb(203, 75, 22, maxColorValue = 255), 
  "Parks"=rgb(211, 54, 130, maxColorValue = 255), 
  "Transit Stations"=rgb(108, 113, 196, maxColorValue = 255), 
  "Workplaces"=rgb(42, 161, 152, maxColorValue = 255), 
  "Residential"=rgb(133, 153, 0, maxColorValue = 255)
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
