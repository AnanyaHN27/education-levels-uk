Given the [#Tidy Tuesday](https://github.com/rfordatascience/tidytuesday/blob/master/data/2024/2024-01-23/english_education.csv) dataset describing educational attainment levels in the UK, I created an infographic. It explores how location and socioeconomic factors influence educational outcomes across England. 

The project features three key visualizations:

- A geographic scatter plot mapping educational performance across UK towns and cities, highlighting regional disparities
- A heat map showing the relationship between population size and educational scores across different regions
- A longitudinal analysis demonstrating how educational attainment progresses differently across various income bands, tracking students from ages 13 to 18

The data reveals a clear "postcode lottery" effect where a student's educational success is significantly influenced by their location and local socioeconomic conditions, rather than just individual merit. The analysis shows that students from lower-deprivation towns consistently maintain higher passing rates compared to those in cities and higher-deprivation areas, with the gap widening as students age.

**The files include**:
- infographic.R
- keys.Renviron
- infographic.png

**To replicate**:
- Create keys.Renviron file, where you put your Google Maps API key
- Run infographic.R in RStudio
