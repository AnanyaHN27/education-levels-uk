library(sf)
library(ggplot2)
library(dplyr)
library(ggmap)
library(rnaturalearth)
library(rnaturalearthdata)
library(tidyr)
library(purrr)
library(tidyverse)
library(readr)
library(viridis)
library(patchwork)

education_levels <- read_csv("english_education.csv")

education_levels <- education_levels %>%
  filter(!is.na(population_2011))

education_levels <- education_levels %>%
  mutate(
    population_category = cut(
      population_2011, 
      breaks = c(0, 10000, 50000, 100000, Inf),
      labels = c("Small", "Medium", "Large", "Very Large"),
      include.lowest = TRUE
    )
  )

avg_attainment <- education_levels %>%
  group_by(population_category, coastal) %>%
  summarise(
    avg_ks2 = mean(key_stage_2_attainment_school_year_2007_to_2008, na.rm = TRUE),
    avg_ks4 = mean(key_stage_4_attainment_school_year_2012_to_2013, na.rm = TRUE),
    .groups = "drop"
  )

df_long <- education_levels %>%
  select(
    town11nm, size_flag, income_flag, 
    key_stage_2_attainment_school_year_2007_to_2008,
    key_stage_4_attainment_school_year_2012_to_2013, 
    level_3_at_age_18
  ) %>%
  pivot_longer(
    cols = c(key_stage_2_attainment_school_year_2007_to_2008,
             key_stage_4_attainment_school_year_2012_to_2013,
             level_3_at_age_18),
    names_to = "education_stage", 
    values_to = "attainment_level"
  ) %>%
  mutate(
    age = case_when(
      education_stage == "key_stage_2_attainment_school_year_2007_to_2008" ~ 13,
      education_stage == "key_stage_4_attainment_school_year_2012_to_2013" ~ 16,
      education_stage == "level_3_at_age_18" ~ 18
    )
  )

df_summary_money <- df_long %>%
  group_by(income_flag, age) %>%
  summarise(
    mean_attainment = mean(attainment_level, na.rm = TRUE),
    .groups = "drop"
  )

df_summary_size <- df_long %>%
  group_by(size_flag, age) %>%
  summarise(
    mean_attainment = mean(attainment_level, na.rm = TRUE),
    .groups = "drop"
  )

register_google(key = GOOGLE_API_KEY)

uk <- ne_countries(
  scale = "medium", 
  returnclass = "sf", 
  country = "united kingdom"
)

geocoded_towns <- education_levels %>%
  mutate(town11nm = sub(" BUA$| BUASD$", ", UK", town11nm)) %>%
  mutate_geocode(town11nm)

common_scale <- scale_color_viridis(
  option = "plasma", 
  discrete = FALSE, 
  name = "Educational Score", 
  guide = "none"
)

line_graph <- ggplot(df_summary_money,
                     aes(x = age, y = mean_attainment, color = income_flag, group = income_flag)) +
  geom_line(size = 1, alpha = 0.7) +
  geom_point(size = 3, alpha = 0.7) +
  theme_bw() +
  labs(
    title = "Educational Attainment Progression by Income Band",
    subtitle = "Proportion of Students Per City With Passing Grades",
    x = "Age of students",
    y = "Proportion passing",
    color = "Town Size"
  ) +
  scale_x_continuous(breaks = c(13, 16, 18)) +
  scale_y_continuous(labels = scales::percent_format(scale = 1)) +
  theme(legend.position = "right")

education_levels <- education_levels %>%
  mutate(rgn11nm = ifelse(rgn11nm == "Yorkshire and The Humber", "Yorkshire", rgn11nm))

heatmap <- ggplot(education_levels, 
                  aes(x = reorder(rgn11nm, education_score), 
                      y = population_category, 
                      fill = education_score)) +
  geom_tile() +
  scale_fill_viridis(option = "plasma", discrete = FALSE, name = "Educational Score") +
  labs(x = "Region", y = "Population Category", fill = "Educational Score") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  ggtitle("Heat Map of Towns by Population Size \n and Educational Scores")

england <- ne_countries(geounit = "england", type = "map_units")["geometry"]

geocoded_towns <- geocoded_towns %>%
  filter(!is.na(lon) | !is.na(lat))

geocoded_towns_sf <- st_as_sf(geocoded_towns, coords = c("lon", "lat"), crs = 4326)
uk_bounds <- st_bbox(uk)
geocoded_towns_sf_bounded <- st_intersection(geocoded_towns_sf, st_as_sfc(england))

geocoded_towns_sf_in_uk <- geocoded_towns_sf_bounded %>%
  mutate(
    lon = st_coordinates(geometry)[, 1],
    lat = st_coordinates(geometry)[, 2]
  )

map_plot <- ggplot() +
  geom_sf(data = england, fill = "white", color = "black", size = 8) +
  geom_point(data = geocoded_towns_sf_in_uk, 
             aes(x = lon, y = lat, color = education_score, size = population_2011), 
             alpha = 0.5, stroke = NA) +
  common_scale +
  theme_minimal() +
  labs(
    title = "Education Scores Across UK Towns",
    x = "Longitude",
    y = "Latitude",
    fill = "Educational Score",
    size = "Population"
  ) +
  theme_bw() +
  coord_sf()

map_plot + (heatmap / line_graph) +
  plot_layout(guides = "collect") +
  plot_annotation(
    title = "The Postcode Lottery: Why English Children Don't Pass English Exams", 
    subtitle = "Location and Income Shape Student Success More Than Town Size",
    caption = "Data Source: The UK Office for National Statistics"
  )

ggsave("final.png", width = 15, height = 15)
