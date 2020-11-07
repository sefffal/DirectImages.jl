# DirectImages.jl

A toolbox for working with FITS images in the context of high contrast / direct imaging.

The main data type is a fork of Tim Holy's ImageMetadata adapted to work with the FITS format
common in astronomy. 

Built on top of FITSIO and the Images ecosystem, this package also bundles
convenient tools for loading and manipulating astronomical images and datacubes.


# Features
 - reading and writing FITS images/cubes/etc
 - easily read and set FITS comments
 - keeping track of physical coordinates
 - contrast measurements
 - send data to SAO DS9 for viewing and manipulation
 - display data using Plots with reasonable scale limits based +/- standard deviations

# Roadmap

 - easy image registration
 - photometry
 - basic tools for showing spectra
 - other image quality metrics, including estimated Strehl
 - contrast measurements for High Contrast Imaging
 - image masking: circles, annuli, etc.
 - Interface with JS9 in addition to DS9


## Example

```julia

# Load an image
img = readfits("M32.fits.gz")

# Get or set headers as properties of the image.
img.DATE_OBS = "2020-01-01"

# Or use indexing
img[:DATE_OBS] = "2020-01-01"
img[:DATE_OBS,/] = "The date the observations were taken"

# Get list of headers
for key in propertnames(img)
    println(img[key])
end

# Use offset indices to keep track of image positions
img[-10,10] == 1.2


```
