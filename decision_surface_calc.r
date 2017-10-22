#### Calculation of grid extension pathways for Nigerian states

#required packages

library("sp")
library("raster")
library("gdistance")
library("rgdal")
library("rgeos")
library("grid")
library("fossil")

state="Sokoto"
#path="\\SRV02\RL-Institut\04_Projekte\145_Nigeria_Electrification\04-Projektinhalte\08_WSIV_Least-Cost-Analysis\Grid_extension\01_Grextool"
#path="C:\\Users\\Catherina\\Documents\\Grid_extension\\01_Grextool" #thinkpad
path="C:\\01_Grextool"  #pc38
#path <-"E:\\remote\\01_Grextool" #thunderpc
setwd(path)

#create folder for intermediate results
outpath=file.path(path,"intermediate",state)
dir.create(outpath,recursive = TRUE)

#create decision surface
#load function to calculate decision raster surface
source("create_decision_surface_v2.r")

#specify input parameter for function
roipath <-file.path(path,"prepared_input", state)
grid_buffersize <- 10
grid_impact <- 0
road_buffersize <- 10
road_impact <- -0.75
pa_impact <- 0.5
forest_impact <- 0.25
water_impact <- 0.5

dc <- create_decision_surface(roipath,grid_buffersize,grid_impact,road_buffersize,road_impact,pa_impact,forest_impact,water_impact)


writeRaster(dc, file.path(outpath,"dc.tif"))

#create MST - artificial grid between electrified cluster
#load funtion to create mst
source("create_mst.r")

#specifiy input for function
#cluster points defined as electrified
ptspath<-file.path(path,"prepared_input", state, "pts_non_electrified.shp")
pts<-readOGR(ptspath, "pts_non_electrified", p4s="+proj=utm +zone=32 +datum=WGS84 +units=m +no_defs")

#if dc is not already loaded
dcpath<-file.path(path, "intermediate", state, "dc.tif")
dc<-raster(dcpath)

mst_phase0 <- create_mst(pts, dc)

outpath=file.path(path,"results",state)
dir.create(outpath,recursive = TRUE)
writeOGR(mst_phase0, outpath, "mst_phase0", driver="ESRI Shapefile")

#update dc

source("update_decision_surface.r")

#if mst is not loaded yet
mstpath<- file.path(path, "results", state, "mst_phase0.shp")
mst_phase0<-readOGR(mstpath, "mst_phase0")

update_ds<- update_decision_surface(dc, mst_phase0, 90, 0)
outpath=file.path(path,"intermediate",state)
writeRaster(update_ds, file.path(outpath,"update_dc.tif"))

#phase1 create mst between all locations >=5000 people
#specify input
ptspath<-file.path(path,"prepared_input", state, "pts_nonelectrified5000.shp")
pts<-readOGR(ptspath, "pts_nonelectrified5000", p4s="+proj=utm +zone=32 +datum=WGS84 +units=m +no_defs")

mst_phase1 <- create_mst(pts, update_ds)

outpath=file.path(path,"results",state)
writeOGR(mst_phase1, outpath, "mst_phase1", driver="ESRI Shapefile")
