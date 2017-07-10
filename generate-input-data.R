# Aim: download, filter and save OD data
pkgs = c("sf", "devtools", "dplyr", "tmap")
install.packages(pkgs)
lapply(X = pkgs, FUN = library, character.only = TRUE)
devtools::install_github("ropensci/stplanr")
library(stplanr)
# Go to http://wicid.ukdataservice.ac.uk/
# Download the file WF02EW_oa
unzip("wf02ew_oa_v1.zip")
f = readr::read_csv("wf02ew_oa_v1.csv", col_names = c("o", "d", "t"))
# Download WPZ centroids from (as spreadsheet):
# http://geoportal.statistics.gov.uk/datasets/176661b9403a4c84ae6aedf8bb4127cf_0
wpz = readr::read_csv("Workplace_Zones_December_2011_Population_Weighted_Centroids.csv")
wpz_sp = SpatialPointsDataFrame(coords = cbind(wpz$X, wpz$Y), data = wpz[-c(1:3)])
# Download output-areas from 
# http://geoportal.statistics.gov.uk/datasets/ba64f679c85f4563bfff7fad79ae57b1_0
oas = readr::read_csv("Output_Areas_December_2011_Population_Weighted_Centroids.csv")
oas_sp = SpatialPointsDataFrame(coords = cbind(oas$X, oas$Y), data = oas[-c(1:3)])
bbox(wpz_sp)
leeds_uni = geo_code("University of Leeds")
lds_sp = SpatialPoints(coords = matrix(leeds_uni, ncol = 2))
lds_buff = buff_geo(shp = lds_sp, width = 500)
proj4string(oas_sp) = proj4string(wpz_sp) = proj4string(lds_buff)
wpz_lds = wpz_sp[lds_buff,]
plot(wpz_lds)
f_lds = filter(f, d %in% wpz_lds$wz11cd & t > 10)
oas_lds = oas_sp[oas_sp$oa11cd %in% f_lds$o,]
f_sp = od2line(flow = f_lds, zones = oas_lds, destinations = wpz_lds)
tmap_mode("view")
qtm(oas_lds) +
  qtm(wpz_lds, symbols.col = "red", symbols.size = 2) +
  qtm(f_sp)

# save non-spatial data
readr::write_csv(f_lds, "input-data/f_lds.csv")

# save spatial dataset
dir.create("input-data")
write_sf(st_as_sf(oas_lds), "input-data/oas_lds.geojson")
write_sf(st_as_sf(wpz_lds), "input-data/wpz_lds.geojson")
write_sf(st_as_sf(f_sp), "input-data/f_sp.geojson")
