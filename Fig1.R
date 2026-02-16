library(sf)
sf_use_s2(FALSE)  # turn off spherical geometry
library(dplyr)
library(ggplot2)
library(ggspatial)
library(rnaturalearth)
library(cowplot)

# -----------------------------
# 1. Build full Borneo polygon for inset
# -----------------------------
indonesia_admin1 <- ne_states(country = "Indonesia", returnclass = "sf")
kalimantan_provs <- c("Kalimantan Barat", "Kalimantan Tengah", "Kalimantan Selatan",
                      "Kalimantan Timur", "Kalimantan Utara")
indonesia_kalimantan <- indonesia_admin1 %>%
  filter(name %in% kalimantan_provs)

malaysia_admin1 <- ne_states(country = "Malaysia", returnclass = "sf")
malaysia_borneo <- malaysia_admin1 %>%
  filter(name %in% c("Sabah", "Sarawak"))

brunei_borneo <- ne_countries(country = "Brunei", scale = "large", returnclass = "sf")

borneo <- st_union(indonesia_kalimantan$geometry) %>%
  st_union(malaysia_borneo$geometry) %>%
  st_union(brunei_borneo$geometry)
borneo_full <- st_cast(borneo, "MULTIPOLYGON")

# -----------------------------
# 2. Load crop and OSM data
# -----------------------------
crop_area <- st_read("kml/crop.kml")
lahg <- st_read("kml/LAHG.kml")
study_area <- st_read("kml/StudyArea.kml")

waterways <- read_sf("kalimantan-260211-free.shp/gis_osm_waterways_free_1.shp")
land <- read_sf("kalimantan-260211-free.shp/gis_osm_landuse_a_free_1.shp")

# -----------------------------
# 3. Load ADM4 shapefiles for coastline
# -----------------------------
adm4_files <- list.files(
  "idn_adm_bps_adm4_20200401_shp/",
  pattern = "^idn_admbnda_adm4_.*\\.shp$", full.names = TRUE
)

# Read all into one sf object
indonesia_adm4 <- lapply(adm4_files, read_sf) %>% bind_rows()

# Filter for Kalimantan provinces 
kalimantan_adm4 <- indonesia_adm4 %>%
  filter(ADM1_EN %in% kalimantan_provs)


# Island polygon
kalimantan_island <- st_union(kalimantan_adm4$geometry)

# -----------------------------
# 4. Project everything to UTM 50S
# -----------------------------
proj_crs <- 32750
crop_rect <- st_as_sfc(st_bbox(crop_area)) %>% st_transform(proj_crs)
waterways_proj <- st_transform(waterways, proj_crs)
land_proj <- st_transform(land, proj_crs)
island_proj <- st_transform(kalimantan_island, proj_crs)
lahg_proj <- st_transform(lahg, st_crs(crop_rect))
study_area_proj <- st_transform(study_area, st_crs(crop_rect))


# -----------------------------
# 5. Crop OSM data to rectangle
# -----------------------------
waterways_cropped <- st_intersection(waterways_proj, crop_rect)
land_cropped <- st_intersection(land_proj, crop_rect)
kalimantan_adm4_cropped <- st_intersection(island_proj, crop_rect)
# Get bbox of crop rectangle
bbox <- st_bbox(crop_rect)

# -----------------------------
# 6. Main map
# -----------------------------

main_map <- ggplot() +
  # Ocean = background
  geom_sf(data = crop_rect, color = NA, fill = "#1f78b4") +
  # Island silhouette (coastline)
  geom_sf(data = kalimantan_adm4_cropped, color = NA, fill = "gray80") +
  # Only forest polygons
  geom_sf(data = land_cropped %>% filter(fclass == "forest"),
          fill = "#27ae60", color = NA, alpha = 0.8) +
  # Rivers and streams
  geom_sf(data = waterways_cropped %>% filter(fclass %in% c("river","stream")),
          color = "#1f78b4") +
  # Canals
  geom_sf(data = waterways_cropped %>% filter(fclass == "canal"),
          color = "#1f78b4", linetype = "dashed", alpha = 0.3) +
  # LAHG polygon outline
  geom_sf(data = lahg_proj, fill = NA, color = "black", size = 0.5) +
  # Study area point as black square
  geom_sf(data = study_area_proj, shape = 22, color = "black", fill = "black", size = 3) +
  # Crop rectangle boundary
  geom_sf(data = crop_rect, fill = NA, color = "#d35400", size = 0.5) +
  # Scale bar
  annotation_scale(
    location = "bl",
    bar_cols = c("black", "white"),
    pad_x = unit(.8, "cm"),
    pad_y = unit(1, "cm"),
    width_hint = 0.2,              # quarter width of map
    height = unit(2, units = "mm"),         # thick enough to see on print
    text_cex = 1                   # big labels
  ) +
  theme_minimal() +
  theme(legend.position = "none")

# -----------------------------
# 7. Inset map (full Borneo)
# -----------------------------
crop_inset <- st_transform(crop_rect, st_crs(borneo_full))
inset_map <- ggplot() +
  geom_sf(data = indonesia_kalimantan, fill = "gray80", color = "black", size = 0.3) +
  geom_sf(data = malaysia_borneo, fill = "gray80", color = "black", size = 0.3) +
  geom_sf(data = brunei_borneo, fill = "gray80", color = "black", size = 0.3) +
  geom_sf(data = crop_inset, fill = NA, color = "#d35400", size = 0.5) +
  theme_void()

# -----------------------------
# 8. Combine main map + inset
# -----------------------------
combined_map <- ggdraw() +
  draw_plot(main_map, x = 0, y = 0, width = 0.7, height = 1) +  # main map on left
  draw_plot(inset_map, x = 0.72, y = 0.55, width = 0.28, height = 0.4)  # inset on right, slightly bigger

# Display
combined_map

# -----------------------------
# 9. Save publication-ready
# -----------------------------
ggsave(
  filename = "Borneo_Forest_Map.png",  # output file
  plot = combined_map,                 # your final map object
  width = 12,                          # width in inches
  height = 10,                         # height in inches
  dpi = 360,                           # high resolution
  bg = "white",                        # ensure white background
  scale = .7
)

