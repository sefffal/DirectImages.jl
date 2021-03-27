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
export contrast


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