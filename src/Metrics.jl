using Statistics
using Interpolations
"""
    contrast(image; step=2)

Measure the contrast of an image, in the sense of high contrast imaging.
That is, divide the image into annuli moving outwards from the centre
(index 0,0 if offset image) and calculate the standard deviation in 
each.

Returns a vector of annulus locations in pixels and a vector of standard
deviations.

*NOTE* This is the 1σ contrast. Multiply by five to get the usual confidence
value.
"""
function contrast(image; step=2)
    I = origin(image)
    if I[1] == I[2] == 1
        image = centered(image)
    end
    dx = UnitRange(axes(image,1)) 
    dy = UnitRange(axes(image,2)) 
    dr = sqrt.(
        dx.^2 .+ (dy').^2
    )

    c_img = collect(image)
    
    bins = 0:step:maximum(dr)
    # bins = 30:step:100
    contrast = zeros(size(bins))
    mask = falses(size(image))
    mask2 = isfinite.(c_img)
    for i in eachindex(bins)
        bin = bins[i]
        mask .= (bin.-step/2) .< dr .< (bin.+step/2) 
        mask .&= mask2
        c = std(view(c_img, mask))
        contrast[i] = c
    end

    return (;separation=bins, contrast)
end

"""
    out,prep = contrast!_prep(image, bins)
    contrast!(out,prep)

A fast non-allocating routine for calculating
contrast. Calculates the 1σ contrast of image
moving outwards from the centre accoring to `bins`.

After calling the `prep` function, you can alter
`image` with new data and calling `contrast!`
will still be very fast and non-allocating.
"""
function contrast!_prep(image,bins,spatialmask=trues(size(image)))
    cont = zeros(size(bins))
    # masks = falses(length(bins),size(image,1),size(image,2))
    # masks = BitMatrix[]
    # We want matrices of bool, not bitmatrix for non-allocating masking view performance
    masks = [
        fill(false, size(image))
        for _ in bins
    ]
    dx = axes(image,1) .- mean(axes(image,1))
    dy = axes(image,2) .- mean(axes(image,2))
    dr = sqrt.(
        dx.^2 .+ (dy').^2
    )
    s = step(bins)/2
    for i in eachindex(bins)
        bin = bins[i]
        masks[i] .= (bin.-s) .< dr .< (bin.+s) 
        masks[i] .&= spatialmask[i]
        # push!(masks,(bin.-s) .< dr .< (bin.+s) )
    end
    views = [view(image, mask) for mask in masks]
    return cont, views
end
function contrast!(out,views)
    for (i,v) in pairs(views)
        out[i] = std(v)
    end
end

export contrast
export contrast!_prep
export contrast!


"""
    contrast_interp(image; step=2)

Returns a linear interpolation on top of the results from `contrast`.
Extrapolated results return Inf.
"""
function contrast_interp(image; step=2)
    cont = contrast(image; step)
    return LinearInterpolation(cont.separation, cont.contrast, extrapolation_bc=Inf)
end
export contrast_interp

function profile(image; step=2)
    I = origin(image)
    if I[1] == I[2] == 1
        image = centered(image)
    end
    dx = UnitRange(axes(image,1)) 
    dy = UnitRange(axes(image,2)) 
    dr = sqrt.(
        dx.^2 .+ (dy').^2
    )

    c_img = collect(image)
    
    bins = 0:step:maximum(dr)
    # bins = 30:step:100
    profile = zeros(size(bins))
    mask = falses(size(image))
    mask2 = isfinite.(c_img)
    for i in eachindex(bins)
        bin = bins[i]
        mask .= (bin.-step/2) .< dr .< (bin.+step/2) 
        mask .&= mask2
        c = mean(view(c_img, mask))
        profile[i] = c
    end

    return (;separation=bins, profile)
end


function snrmap(image, contrast=nothing)
    I = origin(image)
    if I[1] == I[2] == 1
        image = centered(image)
    end
    dx = UnitRange(axes(image,1)) 
    dy = UnitRange(axes(image,2)) 
    dr = sqrt.(
        dx.^2 .+ (dy').^2
    )

    if isnothing(contrast)
        contrast = contrast_interp(image)
    end
    snr = profile2image(contrast, image)

    out = similar(image)
    out .= image ./ snr
    return out
end
export snrmap