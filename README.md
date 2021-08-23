# DirectImages.jl

A toolbox for working with FITS images in the context of high contrast / direct imaging.

Built on top of FITSIO and the Images ecosystem, this package also bundles
convenient tools for loading and manipulating astronomical images and datacubes.

The main data type is a fork of Tim Holy's ImageMetadata adapted to work with the FITS format
common in astronomy. 

## Installation
This package is not in the General registery, but a personal registry for this and related packages.
You can add it as follows:

(`]` to enter Pkg mode)
```julia
 pkg> registry add https://github.com/sefffal/DirectRegistry
 pkg> add DirectImages
```


## Features
 - easily reading and writing FITS images/cubes/etc
 - easily access and set FITS headers and comments
 - keep track of physical coordinates using OffsetArrays behind the scenes
 - contrast measurements
 - send data to SAO DS9 for viewing and manipulation
 - display data using Plots with reasonable scale limits based +/- standard deviations
 - Plots.jl recipe
 - contrast measurements for High Contrast Imaging
## Roadmap

 - image registration
 - photometry
 - other image quality metrics, including estimating Strehl


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

writefits("out.fits", img)
```

## Measuring contrast
Measure the one-sigma contrast:
```julia
cont = contrast(centered(img))
```

As a linear interpolation function 
```julia
cont_itp = contrast_interp(centered(img))
```

## Showing Images
```julia
using Plots
plot(image) # Works if you have a DirectImage
imshow(image) # Works with any abstract array
title!("my image")
```

Or without using Plots:
```julia
imshow2(image)
imshow2(image, cmap=:magma)
imshow2(image, cmap=:magma, clims=(0,10))
```
This will display as a PNG which is less flexible than a Plots heatmap, but much quicker.

By default, `imshow` applies τ=7 (you can override with `nothing`) and `plot` uses
the full colorscale.

Pass `skyconvention=true` to preserve the image, but flip the horizontal axis
so that the coordinates match RA offset. Useful when combining with DirectOrbits.jl.


## Sending to SAO DS9
DS9 must be installed in the usual location on your system.
```julia
# Open a frame or cube
ds9show(image)

# Open multiple frames or cube
ds9show(image1, image2, lock=true) # Lock locks most frame properties (true by default)

# Same as above
ds9show(images_vector, lock=true)
```

Calling `ds9show` with multiple images opens them in the same window. Calling `ds9show` separate times will launch new windows for each. Currently, on MacOS frames are always sent to the open window, whereas on Windows and Linux, a new window is created for each call to `ds9show`.
