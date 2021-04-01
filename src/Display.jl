


using Measures
using Statistics
import Images


using FITSIO

"""
    ds9show(images..., [lock=true], [pad=nothing])

Open one or more images in a SAO DS9 window.
By default, the scales and zooms of the images are locked.
Pass lock=false to disable.

If you pass `pad=true`, the images are padded with NaN
so that they have equal axes. By default (pad=nothing),
padding will be applied when all images are 2D and
locked.
"""
function ds9show(
    # Accept any number of images
    imgs...;
    # Flags
    lock=true,
    pad=nothing,
    setscale=nothing,
    setcmap=nothing,
    loadcmap=nothing,
    τ=nothing,
    regions=String[]
)
    # See this link for DS9 Command reference
    # http://ds9.si.edu/doc/ref/command.html#fits

    # If lock is true (deafult) and the images have different sizes (and are 2D), and
    # padding has not been disabled, turn padding on.
    if length(imgs) > 1 && isnothing(pad) && lock && all(==(2), length.(size.(imgs))) && !all(i -> size(i) == size(first(imgs)), imgs)
        @warn "Padding images so that locked axes work correctly. Disable with either `pad=false` or `lock=false`"
        pad = true
    else
        pad = false
    end

    # If pad is set, pad out the images with NaN to be the same size.
    if pad
        # Sort of an ungly line. paddedviews returns a tuple of views.
        # We need to convert to a vector of arrays.
        imgs = [collect.(Images.paddedviews(NaN, imgs...))...]
    end

    # Detect images with complex values, and just show the power
    imgs = map(imgs) do img
        if eltype(img) <: Complex
            return abs.(img)
        end
        if eltype(img) <: Bool
            return Int8.(img)
        end
        return img
    end

    # For each image, write a temporary file.
    # We clean these up after DS9 exits.
    fnames = String[]
    for img in imgs
        tempfile = tempname()
        writefits(tempfile, img)
        push!(fnames, tempfile)
    end

    # Decide where to look to open DS9 depending on the platform
    if Sys.iswindows()
        cmd = `C:\\SAOImageDS9\\ds9.exe $fnames`        
    elseif Sys.isapple() && isdir("/Applications/SAOImageDS9.app")
        cmd = `open -W /Applications/SAOImageDS9.app --args $fnames`
    elseif Sys.isapple() && isdir("/Applications/SAOImage DS9.app")
        cmd = `open -W /Applications/SAOImage\ DS9.app --args $fnames`
    else
        @warn "Untested system for ds9show. Assuming ds9 is in PATH." maxlog=1
        cmd = `ds9 $fnames`
    end

    if !isnothing(setscale) 
        cmd =  `$cmd -scale mode $setscale`
    end

    if !isnothing(loadcmap) 
        cmd =  `$cmd -cmap load $loadcmap`
    elseif !isnothing(setcmap) 
        cmd =  `$cmd -cmap $setcmap`
    end

    if !isnothing(τ)
        σ = std(filter(isfinite, view(last(imgs),:,:,1,1,1)))
        l1 = -0.5τ*σ
        l2 = +1τ*σ
        cmd = `$cmd -scale limits $l1 $l2`
    end

    # If lock=true, then add almost all possible lock flags to the command
    if lock
        cmd = `$cmd -lock frame image -lock crosshair image -lock crop image -lock slice image -lock bin yes -lock axes yes -lock scale yes -lock scalelimits yes -lock colorbar yes -lock block yes -lock smooth yes `
    end

    for region in regions
        cmd = `$cmd -regions command "$region"`
    end

    # Open DS9 asyncronously.
    # When it finishes or errors, delete the temporary FITS files.
    task = @async begin
        try
            # Open DS9
            run(cmd)
        finally
            # Then delete files whenever it's done
            println()
            @info "cleaning up tmp. files from DS9" fnames
            rm.(fnames)
        end
        return nothing
    end

    # Return the async task, in case the user wants to run something when they are done.
    return task
end

# If called with a vector of images, expand and call the function above
ds9show(imgs::AbstractArray{<:AbstractArray}; kwargs...) = ds9show(imgs...;kwargs...)
export ds9show


# This is a Plots recipe for how to display our image type.
# If the user runs `using Plots; plot(img)` this will be called.
using RecipesBase
@recipe function f(img::DirectImage)
    
    τ = get(plotattributes, :τ, nothing)
    lims = get(plotattributes, :lims, nothing)
    
    skyconvention = get(plotattributes, :skyconvention, false)

    clims = nothing
    if !(isnothing(τ) || ismissing(τ) || τ==:none)
        σ = std(filter(isfinite, view(img,:,:,1,1,1)))
        clims = (-0.5τ*σ, +1τ*σ)
    end

    delete!(plotattributes, :add_marker)

    if !isnothing(lims)
        if length(lims) == 1
            lims = (-lims, lims)
        end
        xlims := lims
        ylims := lims
    end


    unit = "px"
    platescale = 1.0
    if hasproperty(img, :PLATESCALE)
        platescale = img.PLATESCALE
        unit = "mas"
    elseif hasproperty(img, :PIXSCALE)
        platescale = img.PIXSCALE*3.6e6
        unit = "mas"
    elseif hasproperty(img, :PLATESC)
        platescale = img.PLATESC*1e3
        unit = "mas"
    elseif hasproperty(img, :CDELT1)
        platescale = img.CDELT1*1e3
        unit = "mas"
    end

    colorbar_title = ""
    if hasproperty(img, :UNIT)
        colorbar_title = img.UNIT
    end

    seriestype := :heatmap
    xguide --> "X - $unit"
    yguide --> "Y - $unit"
    label --> ""
    # grid --> false
    # legend --> false
    # background_color_outside --> "#000000"
    # background_color_inside --> "#000000"
    # foreground_color --> "#eee"
    aspect_ratio --> 1
    clims --> clims
    colorbar_title --> colorbar_title

    if skyconvention
        xflip --> true
        return (
            UnitRange(axes(img,1)).*platescale,
            UnitRange(axes(img,2)).*platescale,
            reverse(collect(transpose(img[:,:,1,1,1])), dims=2)
        )
    else
        return (
                UnitRange(axes(img,1)).*platescale,
                UnitRange(axes(img,2)).*platescale,
                collect(transpose(img[:,:,1,1,1])) 
        )
    end
end


"""
imshow(img; τ=5, lims=1200)

^ displays an image with +5 std, -2.5std, xlims and ylims set to 1200 mas.

Display an image with convenient formatting.
Looks into the FITS headers for the platescale, if available.

!! NOTE: You must install the Plots package to use imshow.
Run `using Plots` before `using DirectImages` to enable.
"""
function imshow end

function imshow(img; τ=5, lims=nothing, kwargs... )
    error("The Plots package is not active. Run `using Plots` before `using DirectImages` to enable.")
end

# Optionally depend on Plots. If the user imports it, this code will be run to set up
# our `imshow` function.
using Requires
function __init__()
    @require Plots="91a5bcdd-55d7-5caf-9e0b-520d859cae80" begin

        # Imshow just ensures that the argument is a DirectImage and then 
        # dispatches to the Plots recipe above with a default value for τ.
        function imshow(img::DirectImage; τ=5, lims=nothing, kwargs...)
            Plots.plot(img; τ, lims, kwargs...)
        end    
        function imshow(img; τ=5, lims=nothing, kwargs...)
            Plots.plot(DirectImage(img); τ, lims, kwargs...)
        end
    end

end
export imshow

