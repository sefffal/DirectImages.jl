using StatsBase

function stack(
    method,
    images::AbstractArray{<:AbstractArray},
    contrasts;
    pad=nothing
)

    # If lock is true (deafult) and the images have different sizes (and are 2D), and
    # padding has not been disabled, turn padding on.
    if length(images) > 1 && isnothing(pad)  && all(==(2), length.(size.(images))) && !all(Ref(size.(images)) .== size(first(images)))
        @warn "Padding images to a common size"
        pad = true
    else
        pad = false
    end

    # If pad is set, pad out the images with NaN to be the same size.
    if pad
        # Sort of an ungly line. paddedviews returns a tuple of views.
        # We need to convert to a vector of arrays.
        images = centered.([collect.(Images.paddedviews(NaN, images...))...])
    end

    contrast_maps = map(zip(images, contrasts)) do (img, cont)
        (1 ./ profile2image(cont, img)).^2
    end
   
    pixels = zeros(eltype(first(images)), length(images))
    weights= zeros(eltype(first(contrast_maps)), length(contrast_maps))
    mask= falses(length(contrast_maps))

    out = similar(first(images))
    for I in eachindex(first(images))
        for i in eachindex(images)
            pixels[i] = images[i][I]
            weights[i] = contrast_maps[i][I]
        end
        mask .= isfinite.(pixels) .& isfinite.(weights)
        if any(mask) && sum(view(weights,mask)) > 0
            out[I] = method(view(pixels,mask), aweights(view(weights,mask)))
        else
            out[I] = eltype(out)(NaN)
        end
    end
    return out
end

function stack(
    method,
    images::AbstractArray{<:AbstractArray};
    pad=nothing
)

    # If lock is true (deafult) and the images have different sizes (and are 2D), and
    # padding has not been disabled, turn padding on.
    if length(images) > 1 && isnothing(pad)  && all(==(2), length.(size.(images))) && !all(Ref(size.(images)) .== size(first(images)))
        @warn "Padding images to a common size."
        pad = true
    else
        pad = false
    end

    # If pad is set, pad out the images with NaN to be the same size.
    if pad
        # Sort of an ungly line. paddedviews returns a tuple of views.
        # We need to convert to a vector of arrays.
        images = centered.([collect.(Images.paddedviews(NaN, images...))...])
    end

    pixels = zeros(eltype(first(images)), length(images))
    mask= falses(length(images))

    out = similar(first(images))
    for I in eachindex(first(images))
        for i in eachindex(images)
            pixels[i] = images[i][I]
        end
        mask .= isfinite.(pixels)
        if any(mask)
            out[I] = method(view(pixels,mask))
        else
            out[I] = eltype(out)(NaN)
        end
    end
    return out
end
export stack