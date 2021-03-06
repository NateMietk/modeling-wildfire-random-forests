# Download and import CONUS states
# Download will only happen once as long as the file exists
if (!exists("states")){
  states <- load_data(url = "https://www2.census.gov/geo/tiger/GENZ2016/shp/cb_2016_us_state_20m.zip",
                       dir = raw_us,
                       layer = "cb_2016_us_state_20m",
                       outname = "usa") %>%
    sf::st_transform(p4string_ea) %>%
    dplyr::filter(!STUSPS %in% c("HI", "AK", "PR"))
  states$STUSPS <- droplevels(states$STUSPS)
}

# Download and import the Level 3 Ecoregions data
if (!exists("ecoregions_l3")) {
  if(!file.exists(file.path(bounds_dir, 'us_eco_l3.gpkg'))) {

      ecoregions_l3 <- load_data(url = "ftp://newftp.epa.gov/EPADataCommons/ORD/Ecoregions/us/us_eco_l3.zip",
                                 dir = raw_ecoregionl3,
                                 layer = "us_eco_l3",
                                 outname = "ecoregions_l3") %>%
        sf::st_transform(st_crs(states)) %>%
        dplyr::mutate(NA_L3NAME = as.character(NA_L3NAME),
                      NA_L3NAME = ifelse(NA_L3NAME == 'Chihuahuan Desert',
                                         'Chihuahuan Deserts',
                                         NA_L3NAME),
                      NA_L2NAME = case_when(
                        NA_L2NAME == 'UPPER GILA MOUNTAINS (?)' ~ 'UPPER GILA MOUNTAINS',
                        TRUE ~ as.character(NA_L2NAME)),
                      NA_L2NAME = as.factor(NA_L2NAME),
                      region = as.factor(if_else(NA_L1NAME %in% c("EASTERN TEMPERATE FORESTS",
                                                                  "TROPICAL WET FORESTS",
                                                                  "NORTHERN FORESTS"), "East",
                                                 if_else(NA_L1NAME %in% c("NORTH AMERICAN DESERTS",
                                                                          "SOUTHERN SEMI-ARID HIGHLANDS",
                                                                          "TEMPERATE SIERRAS",
                                                                          "MEDITERRANEAN CALIFORNIA",
                                                                          "NORTHWESTERN FORESTED MOUNTAINS",
                                                                          "MARINE WEST COAST FOREST"), "West", "Central")))) %>%
        mutate_if(is.factor, funs(tolower)) %>%
        mutate_if(is.character, funs(capitalize)) %>%
        mutate_if(is.character, funs(gsub('-', ' ', .))) %>%
        mutate_if(is.character, funs(gsub('/', ' ', .))) %>%
        mutate_if(is.character, as.factor) %>%
        rename_all(tolower) 
    
    st_write(ecoregions_l3, file.path(bounds_dir, 'us_eco_l3.gpkg'), delete_layer = TRUE)
  
} else {
  ecoregions_l3 <- st_read(file.path(bounds_dir, 'us_eco_l3.gpkg'))
  }
}


# Create raster mask
if (!exists("raster_mask")) {
  raster_mask <- raster::raster()
  crs(raster_mask) <- crs(p4string_ea)
  extent(raster_mask) <- c(-2032092, 2515908, -2116850, 731150)
  nrow(raster_mask) <- 2848
  ncol(raster_mask) <- 4548
  res(raster_mask) <- 1000
}

# Create raster mask
# 4k Fishnet
# if (!exists("fishnet_4k")) {
#   if (!file.exists(file.path(bounds_dir, "fishnet_4k.gpkg"))) {
#     fishnet_4k <- st_sf(geom=st_make_grid(states, cellsize = 4000, square = TRUE), crs=st_crs(states)) %>%
#       st_cast('MULTIPOLYGON') %>%
#       mutate(grid_4k = row_number())
#     
#     sf::st_write(fishnet_4k, file.path(bounds_dir, "fishnet_4k.gpkg"), driver = "GPKG")
#     
#     system(paste0("aws s3 sync ", bounds_dir, " ", s3_anc_prefix, "fishnet"))
#   } else {
#     fishnet_4k <- sf::st_read(file.path(bounds_dir, "fishnet_4k.gpkg"))
#   }
# }
