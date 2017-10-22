update_decision_surface= function (ds, powerlines, grid_buffersize,grid_impact)
{
  #update decision surface with new powerlines
  #parameters:
  #ds : decision surface raster data set
  #powerlines: shapefile with new powerlines (artification network) which shall be considered for "phase1"
  #grid_buffersize
  #grid_impact: should be 0
  
  #example:
  #path="C:\\Users\\Catherina\\Documents\\Grid_extension\\01_Grextool\\intermediate\\Ogun #folder with decision layer
  #dc_filename=file.path(path,'dc.tif')
  #dc=raster(dc_filename)
  #powerlines_filename=file.path(path,'grid.shp')
  #powerlines=readOGR(powerlines_filename,'grid',driver='ESRI Shapefile')
  #new_dc=update_decision_surface(dc, powerlines, 90,0)
  
  # define projection (in metric projection)
   proj_nigeria <- CRS("+proj=utm +zone=32 +datum=WGS84 +units=m +no_defs")
  
  
  #load
  grid<- spTransform(powerlines, proj_nigeria)
  
  #create empty Raster with ds as extent
  emptyRaster<-setValues(ds,NA)
  
  rg<-rasterize(grid,emptyRaster,update=TRUE)
  bg<-buffer(rg,width=grid_buffersize)
  bg[!is.na(bg)] <- grid_impact
  bg[is.na(bg)] <- 1
 
  #update decision surface
  dc_phase1 <- ds*bg
  
  return(dc_phase1)
  
}