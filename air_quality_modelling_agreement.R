rm(list=ls())

library(ggplot2)
library(jsonlite)
library(rgeos)
library(rgdal)
library(sf)

source('../aq_api_key.R')

latlong = "+init=epsg:4326"
ukgrid  = "+init=epsg:27700"
google  = "+init=epsg:3857"

locations               <- read.csv('site_locations.csv')

coordinates(locations)  <- ~easting + northing
proj4string(locations)  <- CRS(ukgrid)
locations               <- spTransform(locations, latlong)
locations               <- data.frame(locations)
names(locations)        <- c('sitecode', 'sitename', 'sitetype', 'longitude', 'latitude', 'optional')
locations$optional      <- NULL

base_url      <- 'https://api.breezometer.com/baqi/?'

for (i in 1:nrow(locations)) {
  
  url         <- paste0(base_url,
                        'lat=', locations[i,]$latitude, '&',
                        'lon=', locations[i,]$longitude, '&',
                        'key=', aq_api_key)
  
  raw_result  <- fromJSON(url)
  
  result      <- data.frame(
                    datetime = as.POSIXct(raw_result$`datetime`, format='%Y-%m-%dT%H:%M:%S'),
                    sitecode = as.character(locations[i,]$sitecode),
                    lat      = locations[i,]$latitude,
                    lon      = locations[i,]$longitude,
                    co       = raw_result$pollutants$`co`$concentration,
                    no2      = raw_result$pollutants$no2$concentration,
                    o3       = raw_result$pollutants$o3$concentration,
                    pm10     = raw_result$pollutants$pm10$concentration,
                    pm25     = raw_result$pollutants$pm25$concentration,
                    so2      = raw_result$pollutants$so2$concentration,
                    stringsAsFactors = F
                          )
  
  write.table(result, "result.csv", sep = ",", row.names = F, col.names = F, append = T)
  
  Sys.sleep(sample(1:2,1))
}