#!/usr/bin/env Rscript

# Check args
args = commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
  stop("At least one argument must be supplied {species}.csv", call.=FALSE)
}

# Load dependencies
packrat::on()
library(raster)
library(rgdal)
library(dismo)
library(XML)
library(maps)
packrat::off()

#Global flags
countryPerspective = TRUE # If TRUE, will show the entire country of New Zealand. Else will just show frame of presence
plotOccurrence = FALSE # If TRUE, will plot the occurrence of the species over the predicted distribution. Else will ommit occurrences
binValues = FALSE # If true, values will be binned: 0 to 0.05 -> 0.25, 0.051 to 0.1 -> 0.5, 0.11 to 0.4 -> 1

# Load species data specified in args
print("Loading species data...")
speciesPresenceData <- read.csv(args[1])

# Load raster data for all BIOCLIM variables
print("Loading BIOCLIM data..." )
rasters<-list.files(
    path="../data/BIOCLIM",
    full.names=TRUE,
    pattern=".bil")
stackrasters<-raster(rasters[1])
for(rst in rasters){
    stackrasters<-stack(stackrasters,raster(rst))
}

if(countryPerspective){
    xLower <- 166
    xUpper <- 179
    yLower <- -48
    yUpper <- -34
}else{
    xLower <- min(speciesPresenceData$long, na.rm = TRUE) - .1
    xUpper <- max(speciesPresenceData$long, na.rm = TRUE) + .1
    yLower <- min(speciesPresenceData$lat,  na.rm = TRUE) - .1
    yUpper <- max(speciesPresenceData$lat,  na.rm = TRUE) + .1
}

print("Creating model..." )
croppedRasters<-crop(stackrasters,extent(xLower,xUpper,yLower,yUpper)) # Crop our rasters to our perspective
occurrenceFrame<-data.frame(speciesPresenceData$long,speciesPresenceData$lat) # Define frame where species occurs
speciesModel<-dismo::bioclim(croppedRasters,occurrenceFrame) # Generate BIOCLIM model for areas where this species occurs
speciesDistribution<-dismo::predict(speciesModel, croppedRasters) # Predict, based on the model, where this species is likely to occur
if(binValues){
    speciesDistribution<-reclassify(speciesDistribution,
        c(0.000, 0.050, 0.250, 
          0.051, 0.100, 0.500, 
          0.110, 0.400, 1.000)
    ) # Bin values for easier visualization
}


print("Plotting distribution..." )
# Plot results
png('rplot.png',
    width=800,
    height=600)# All graphical operations below this command will show on the rplot.png file

plot(speciesDistribution, 
    xlab="Longitude", 
    ylab="Latitude") # Plot the species distribution

if(plotOccurrence){
    points(speciesPresenceData$long,
    speciesPresenceData$lat,
    col="red",
    pch=20) # Plot species occurrence points 
}

map(add=T) # Add a world map to the plot

# Output the distribution raster to csv
print("Writing distribution data to CSV..." )
speciesDistributionNA <- reclassify(speciesDistribution, cbind(NA, 0)) #This ensures that ALL values within our square are included in the points! This keeps our raster outputs consistent! 
speciesPoints <- as.data.frame( rasterToPoints(speciesDistributionNA) ) # Convert raster into points
write.table(speciesPoints, file="raster.csv", sep=",", eol="\r\n", row.names=FALSE, col.names=FALSE) # Write those points to a file... they are not sorted in any intuitive way!
system("./rasterToProbCsv.py raster.csv > ../out/bioclim.csv") # Sort the points and only keep the probabilities! This is the format expected by our model output comparator
system("rm raster.csv") # Clean up

print('Done!')