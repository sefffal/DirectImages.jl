# SpaceImages

This is a fork of Tim Holy's ImageMetadata adapted to work with the FITS format
common in astronomy. 

Built on top of FITSIO and the Images ecosystem, this package also bundles
convenient tools for loading and manipulating astronomical images and datacubes.


# Featuers
 - reading and writing FITS cubes
 - read and set FITS comments
 - keeping track of physical coordinates

# Roadmap

 - image registration
 - photometry
 - measure Strehl?
 - basic tools for showing spectra
 - image quality metrics
 - contrast measurements for High Contrast Imaging
 - image masking: circles, annuli, etc.

 - Interface with DS9 & JS9


## Example

```julia

# Load an image
img = Spimage("M32.fits.gz")

# Inspect or set headers
img.DATE_OBS = "2020-01-01"
img[:DATE_OBS] = "2020-01-01"
img[:DATE_OBS,/] = "The date the observations were taken"

# Use offset indices to keep track of image positions
img[-10,10] == 1.2


```