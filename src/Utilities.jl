
"""
    profile2image(profile, image)

Given an image and a vector profile (could be contrast, any
1D function), return a new image with the axes of `image`
and the values of `profile` interpolated radially from the
centre.
"""
function profile2image(profile, image)
    error("WIP")
end

"""
    lookup_coord(img, [125.24, -129.1], 12.43)

Given an image, a coordinate vector in milliarcseconds, and the platescale
in milliarcseconds, return the pixel at that coordinate using bilinear interpolation.
"""
## Function for looking up a single pixel in an image, with bi-linear interpolation
function lookup_coord(image::AbstractArray, vec, platescale)
    ix = vec[1] / platescale
    iy = vec[2] / platescale
    axx = axes(image, 1)
    axy = axes(image, 2)

    ix1 = floor(Int, ix)
    ix2 = ceil(Int, ix)
    iy1 = floor(Int, iy)
    iy2 = ceil(Int, iy)
    ix2 += (ix1 == ix2)
    iy2 += (iy1 == iy2)

    # Bi-linear interpolation, if in-bounds
    tot = zero(eltype(image))
    if (ix1 ∈ axx) & (ix2 ∈ axx) & (iy1 ∈ axy) & (iy2 ∈ axy)
        top_ave =
            image[ix1, iy2] * (ix2 - ix) +
            image[ix2, iy2] * (ix - ix1)
        bot_ave =
            image[ix1, iy1] * (ix2 - ix) +
            image[ix2, iy1] * (ix - ix1)
        tot += top_ave * (iy - iy1) + bot_ave * (iy2 - iy)
    end
    return tot
end
export lookup_coord