setwd("/Users/sjs7465/Documents/GitHub/myrtle_geo_pressure")

library(GeoPressureR)
library(glue)
library(terra)

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

# Compute the light map
if ("light" %in% names(tag)) {
  tag <- twilight_create(tag, twl_offset = config::get("twl_offset", id)) |>
    twilight_label_read() |>
    geolight_map()
}

#Plot light map
plot(tag, type = "map_light", opacity=0.6, provider="Esri.WorldTopoMap")

# Check calibration
barW <- median(diff(tag$param$twl_calib$x)) / 2
plot(tag$param$twl_calib)
rect(xleft = tag$param$twl_calib$x - barW, ybottom = 0, xright = tag$param$twl_calib$x + barW, ytop = tag$param$twl_calib$y, col = gray(0.5))
lines(tag$param$twl_calib, col = "red")

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
write.csv(path_most_likely, paste0("/Users/sjs7465/Documents/GitHub/myrtle_geo_pressure/output/path_most_likely_all/", id, "_path_most_likely_presslight.csv"))

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
# Plotressurepath histograms
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
