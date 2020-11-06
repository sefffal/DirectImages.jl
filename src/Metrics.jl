using Statistics

"""
Measure the contrast of an image, in the sense of high contrast imaging.
That is, divide the image into annuli moving outwards from the centre
(index 0,0 if offset image) and calculate the standard deviation in 
each.

Returns a vector of annulus locations in pixels and a vector of standard
deviations.

*NOTE* This is the 1σ contrast. Multiply by five to get the usual confidence
value.
"""
function contrast(image)
    I = origin(image)
    dx = I[1] .- axes(image,1)
    dy = I[2] .- axes(image,2)
    dr = sqrt.(
        dx.^2 .+ (dy').^2
    )
    
    step = 20
    bins = 0:step:maximum(dr)
    # bins = 30:step:100
    contrast = zeros(size(bins))
    mask = falses(size(image))
    mask2 = isfinite.(image)
    for i in eachindex(bins)
        bin = bins[i]
        mask .= (bin.-step/2) .< dr .< (bin.+step/2) 
        mask .&= mask2
        c = std(view(image, mask))
        contrast[i] = c
    end

    return (;separation=bins, contrast)
end
export contrast

function profile(image)
end