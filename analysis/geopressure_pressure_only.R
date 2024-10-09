setwd("~/Documents/GitHub/myrtle_geo_pressure")

library(GeoPressureR)
library(glue)

id = "CG179"

# Create, label and set the map for a tag
tag <- tag_create(
  id = config::get("id", id),
  crop_start = config::get("crop_start", id),
  crop_end = config::get("crop_end", id)
) |>
  tag_label() |>
  tag_set_map(
    extent = config::get("extent", id),
    scale = config::get("scale", id),
    known = config::get("known", id)
  )

# Compute the pressure map
tag <- geopressure_map(tag)

# Plot pressure likelihood maps
plot(tag$map_pressure)

# Create the graph
graph <- graph_create(tag)

# Define movement model
if (config::get("movement_type", id) == "as") {
  # with windspeed
  graph <- graph_add_wind(
    graph,
    pressure = tag$pressure,
    thr_as = config::get("thr_as", id)
  )

  graph <- graph_set_movement(
    graph,
    bird = bird_create(config::get("scientific_name", id)),
    power2prob = config::get("movement_low_speed_fix", id),
    low_speed_fix = config::get("movement_low_speed_fix", id)
  )
} else {
  # without windspeed
  graph <- graph_set_movement(
    graph,
    method = config::get("method", id),
    shape = config::get("movement_shape", id),
    scale = config::get("movement_scale", id),
    location = config::get("movement_location", id),
    low_speed_fix = config::get("movement_low_speed_fix", id)
  )
}

# Compute products and view plots

#Create most likely path
path_most_likely <- graph_most_likely(graph)
#Plot most likely path
plot_path(path_most_likely, provider="Esri.WorldTopoMap")
#Plot most likely path on satellite map
plot_path(path_most_likely, provider="Esri.WorldImagery")
#Save most likely path
write.csv(path_most_likely, paste0("/Users/sjs7465/Documents/GitHub/myrtle_geo_pressure/output/path_most_likely_all/", id, "_path_most_likely_pressonly.csv"))


#Create marginal probability map 
marginal <- graph_marginal(graph)
#Plot most likely path with marginal distribution
plot(marginal, path = path_most_likely)

#Simulate paths (default 10)
path_simulation <- graph_simulation(graph)
#Plot simulated paths
plot_path(path_simulation, plot_leaflet = FALSE)

# Compute pressurepath on the most likely path
pressurepath_ml <- pressurepath_create(tag, path_most_likely)
plot_pressurepath(pressurepath_ml)
# Plot pressurepath histograms
plot_pressurepath(pressurepath_ml, type = "hist")

#Altitude of bird
plot_pressurepath(pressurepath_ml, type = "altitude")

# Save
save(
  tag,
  graph,
  path_most_likely,
  path_simulation,
  marginal,
  pressurepath_ml,
  file = glue("./data/interim/{id}.RData")
)
