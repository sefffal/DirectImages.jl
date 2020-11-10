"""
DirectImages.jl

A package of useful functions for interacting with FITS files.

# Available Functions

- `DirectImage(array)`
- `headers(img)`
- `axes(img)`
- `origin(img)`
- `size(img)`
- `copy(img)`
- `arraydata(img)` Gives underlying array

(All other Julia array functions as well)

- `readfits`
- `writefits`
- `readheader`  Only read headers. `readfits` gives both data and headers.

- `contrast`

"""
module DirectImages

include("Type.jl")
include("Time.jl")
include("Metrics.jl")
include("IO.jl")
include("Display.jl")
include("Utilities.jl")

include("precompile.jl")


end 
