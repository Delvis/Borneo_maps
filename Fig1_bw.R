# Run Fig1.R before this running file.

# -----------------------------
# Figure 1, black and white
# -----------------------------

library(ggspatial)

main_map_bw <- ggplot() +
  # Ocean = light grey background
  geom_sf(data = crop_rect, color = NA, fill = "gray70") +
  # Island silhouette
  geom_sf(data = kalimantan_adm4_cropped, color = NA, fill = "white") +
  # Only forest polygons
  geom_sf(data = land_cropped %>% filter(fclass == "forest"),
          fill = "gray30", color = NA, alpha = 0.8) +
  # Rivers and streams
  geom_sf(data = waterways_cropped %>% filter(fclass %in% c("river","stream")),
          color = "gray70") +
  # Canals
  geom_sf(data = waterways_cropped %>% filter(fclass == "canal"),
          color = "gray70", linetype = "dashed", alpha = 0.6) +
  # LAHG polygon outline
  geom_sf(data = lahg_proj, fill = NA, color = "black", size = 0.5) +
  # Study area point as black square
  geom_sf(data = study_area_proj, shape = 22, color = "black", fill = "black", size = 3) +
  # Crop rectangle boundary
  geom_sf(data = crop_rect, fill = NA, color = "black", size = 0.5) +
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
# Inset map (full Borneo)
# -----------------------------
crop_inset <- st_transform(crop_rect, st_crs(borneo_full))
inset_map <- ggplot() +
  geom_sf(data = indonesia_kalimantan, fill = "gray80", color = "black", size = 0.3) +
  geom_sf(data = malaysia_borneo, fill = "gray80", color = "black", size = 0.3) +
  geom_sf(data = brunei_borneo, fill = "gray80", color = "black", size = 0.3) +
  geom_sf(data = crop_inset, fill = NA, color = "black", size = 0.5) +
  theme_void()

# -----------------------------
# Combine main map + inset
# -----------------------------
combined_map_bw <- ggdraw() +
  draw_plot(main_map_bw, x = 0, y = 0, width = 0.7, height = 1) +  # main map on left
  draw_plot(inset_map, x = 0.72, y = 0.55, width = 0.28, height = 0.4)  # inset on right, slightly bigger

# Display
combined_map

# -----------------------------
# Save publication-ready
# -----------------------------
ggsave(
  filename = "Borneo_Forest_Map_bw.png",  # output file
  plot = combined_map_bw,                 # your final map object
  width = 12,                          # width in inches
  height = 10,                         # height in inches
  dpi = 360,                           # high resolution
  bg = "white",                        # ensure white background
  scale = .7
)
