create_mst=function(pts,ds)
{
#create minimum spanning trees

#required input: points to be connected, decision surface raster with same extent
#output: spatial lines of suggested mst


#transform projection of points
proj_nigeria <- CRS("+proj=utm +zone=32 +datum=WGS84 +units=m +no_defs")
pts<- spTransform(pts, proj_nigeria)

#create transition layer
T<-transition(ds, function(x) 1/mean(x), directions = 8)
T<-geoCorrection(T)

#calculate cost distance matrix between all points on the cost raster
cd<-costDistance(T,pts)
cdmat=as.matrix(cd)

#calculate the minimum spanning tree based on the assigned costs
mst_1=dino.mst(cd, random.start = TRUE, random.search = TRUE)

#create list for the resulting shortest path
pathlist=list()

#list for the associated costs for each connection
pathcostlist=c()

#loop over the mst-list to get the correct points on which to carry out the spatial shortest path analysis
for (i in 1:nrow(mst_1)) {
  for (j in 1:i) {
    if (mst_1[i, j] == 1) #points connected
    {
      pt1 <-
        SpatialPoints(
          coordinates(pts[i, ]),
          proj4string = proj_nigeria
        )
      pt2 <-
        SpatialPoints(
          coordinates(pts[j, ]),
          proj4string = proj_nigeria
        )
      #calculate path between those points and add to list
      pathlist = c(pathlist,
                   shortestPath(T, pt1, pt2, output = "SpatialLines"))
      #add cost to list
      pathcostlist=c(pathcostlist,cdmat[i,j])
    }
  }
}
spatln= do.call(function(...) rbind(...,makeUniqueIDs=TRUE),pathlist)

#make dataframe of costs
dat=data.frame(pathcostlist)
frame=SpatialLinesDataFrame(spatln, dat, match.ID = FALSE)
return(frame)
}

#writeOGR(frame, getwd(), "linesandcost", driver="ESRI Shapefile") #which wd