create_decision_surface= function (roipath,grid_buffersize,grid_impact,road_buffersize,road_impact,pa_impact,forest_impact,water_impact)
{
  #create decision surface
  #parameters:
  #roipath: path to inputfiles for roi
  #(grid/road)_buffersize: size of buffer around grid/roads  
  #..
  
  #example:
  # path="C:\\Users\\Catherina\\Documents\\Grid_extension\\01_Grextool"
  # create_decision_surface(path,90,0,90,-0.75,0.5,c(0,11,0, 11,20,0.25, 21,41,0, 41,60,0.5, 61,101,0))
  
  
  # define projection (in metric projection)
   proj_nigeria <- CRS("+proj=utm +zone=32 +datum=WGS84 +units=m +no_defs")
  
  #load raster slope
  slopepath<-file.path(roipath, "slope.tif")
  slope<- raster(slopepath)
  
  #load land cover (lc)
  lcpath<-file.path(roipath, "lc.tif")
  lc<-raster(lcpath)
  
  #reclassify lc
  # lc <-reclassify(lc, lc_costs)
  fi=0.25
  wi=0.5
   lc <-reclassify(lc, c(0,19.5,0, 19.5,29.5,forest_impact, 29.5,49.5,0, 49.5,69.5,water_impact, 69.5,257,0)) #=1 oder 0?
  
  #project and resample
  slope<- projectRaster(slope, crs=proj_nigeria, res=90)
  lc<- projectRaster(lc, crs=proj_nigeria, res=90, method="ngb")
  
  # resample slope to lc
  slope <- resample(slope, lc)
  
  #load
  roadpath<-file.path(roipath, "roads_clipped.shp")
  roads<- readOGR(roadpath, "roads_clipped")
  papath<-file.path(roipath, "pa_clipped.shp")
  pa<- readOGR(papath, "pa_clipped")
  
  #create empty Raster with slope as extent
  emptyRaster<-setValues(slope,NA)
  
  #rasterize PA
  pa<-rasterize(pa,emptyRaster,update=TRUE)
  pa[!is.na(pa)] <- pa_impact
  pa[is.na(pa)] <- 0
  
  
  #rasterize roads
  rr<-rasterize(roads,emptyRaster,update=TRUE)
  
  # buffer road
  br<-buffer(rr,width=road_buffersize)
  br[!is.na(br)] <- road_impact
  br[is.na(br)] <- 0
  
  #load and buffer grid if exists 
  gridpath<-file.path(roipath, "pg_clipped.shp")
  if (file.exists(gridpath))
  {
    grid<-readOGR(gridpath,"pg_clipped")
    rg<-rasterize(grid,emptyRaster,update=TRUE)
    bg<-buffer(rg,width=grid_buffersize)
    bg[!is.na(bg)] <- grid_impact
    bg[is.na(bg)] <- 1
  }else{
    bg<-setValues(emptyRaster,1)
  }
  
  #calculate decision surface
  dc <- ((1+(slope/100))+lc+pa+br)*bg
  
  return(dc)
  
}