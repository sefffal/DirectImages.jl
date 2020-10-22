# FITSImages

Built on top of FITSIO and the Images ecosystem, this package aims to provide
convenient tools for loading and manipulating astronomical images and datacubes.

Suppots:
 - reading and writing FITS cubes
 - read and set FITS comments
 - keeping track of physical coordinates

------ Core ^^ --------

 - image registration
 - photometry
 - measure Strehl?
 - basic tools for showing spectra
 - image quality metrics
 - contrast measurements for High Contrast Imaging
 - image masking: circles, annuli, etc.

 - Interface with JS9?

Can be combined with other packages to:
 - show images in a popup window, in VS Code, notebooks, or your terminal (ImageView, ImagesInTerminal)
 - overplot graphics for labelling features (Luxor?)
 - overplot lines etc. (Plots)


## Example

```julia

# Load an image
img = FITSImage("M32.fits.gz")

# Inspect or set headers
img.DATE_OBS = "2020-01-01"
img[:DATE_OBS] = "2020-01-01"
img[:DATE_OBS,/] = "The date the observations were taken"

# Use offset indices to keep track of image positions
img[-10,10] == 1.2

# Use physical indices
img[-10kpc:10kpc] == 2.0

```