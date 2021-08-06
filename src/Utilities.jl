"""
    centre_of_gravity(img)

Given a matrix (i.e. an image) return the centre of gravity.
This is an index position (not rounded).
"""
function centre_of_gravity(img)
    tot = sum(img)
    cog_x = zero(eltype(img))
    for i in axes(img,1)
        cog_xi = zero(eltype(img))
        for j in axes(img,2)
            cog_xi += img[i,j]
        end
        cog_x += cog_xi * i
    end
    cog_x/=tot
    cog_y = zero(eltype(img))
    for i in axes(img,2)
        cog_yi = zero(eltype(img))
        for j in axes(img,1)
            cog_yi += img[j,i]
        end
        cog_y += cog_yi * i
    end
    cog_y/=tot 
    return (cog_x, cog_y)
end
export centre_of_gravity2


"""
    profile2image(profile, image)

Given an image and a vector profile (could be contrast, any
1D function), return a new image with the axes of `image`
and the values of `profile` interpolated radially from the
centre.
"""
function profile2image(profile, image)
    img_out = similar(image)

    I = origin(image)
    if I[1] == I[2] == 1
        image = centered(image)
    end
    dx = axes(image,1)
    dy = axes(image,2)
    dr = sqrt.(
        dx.^2 .+ (dy').^2
    )

    img_out .= profile.(dr)
    return img_out
end
export profile2image

"""
    lookup_coord(img, [125.24, -129.1], 12.43)

Given an image, a coordinate vector in milliarcseconds, and the platescale
in milliarcseconds, return the pixel at that coordinate using bilinear interpolation.
"""
## Function for looking up a single pixel in an image, with bi-linear interpolation
function lookup_coord(image::AbstractArray, x,y, platescale)
    return lookup_coord(image, (x,y), platescale)
end

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


using Statistics

"""
    imgsep(img)

Given an array, return the distance of each pixel
to the centre.
"""
function imgsep(
    img,
    centrex=mean(axes(img,1)),
    centrey=mean(axes(img,2)),
)
    xs = axes(img,1) .- centrex
    ys = axes(img,2) .- centrey
    r = sqrt.(xs.^2 .+ ys'.^2)
    return r
end
export imgsep

"""
    fakeimage((100,100), [1.2])

Given desired image dimensions and gaussian blur level, create
a random image with a noise distribution a bit like a real direct
image.
"""
function fakeimage(dims,gaus_size=1.2)
    image = zeros(dims)
    cont, views = contrast!_prep(image,1:2:ceil(Int,maximum(size(image))*√2))
    for (i,v) in pairs(views)
        v .=1/ i^2*randn(length(v))
    end
    blurred = imfilter(image, Kernel.gaussian(gaus_size),NA())
    return blurred
end
export fakeimage