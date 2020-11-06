


using Measures
using Statistics



using FITSIO

"""
    ds9show(images..., [lock=true])

Open one or more images in a SAO DS9 window.
By default, the scales and zooms of the images are locked.
Pass lock=false to disable.
"""
function ds9show(imgs...; lock=true)
    # http://ds9.si.edu/doc/ref/command.html#fits

    fnames = String[]
    for img in imgs
        tempfile = tempname()
        writefits(tempfile, img)
        push!(fnames, tempfile)
    end

    if Sys.iswindows()
        cmd = `C:\\SAOImageDS9\\ds9.exe $fnames`        
    elseif Sys.isapple() && isdir("/Applications/SAOImageDS9.app")
        cmd = `open -W /Applications/SAOImageDS9.app $fnames`
    elseif Sys.isapple() && isdir("/Applications/SAOImage DS9.app")
        cmd = `open -W /Applications/SAOImage\ DS9.app $fnames`
    else
        @warn "Untested system for ds9show. Assuming ds9 is in PATH." maxlog=1
        cmd = `ds9 $fnames`
    end

    if lock
        cmd = `$cmd -lock frame image -lock crosshair image -lock crop image -lock slice image -lock bin yes -lock axes yes -lock scale yes -lock scalelimits yes -lock colorbar yes -lock block yes -lock smooth yes `
    end

    task = @async begin
        try
            # Open DS9
            run(cmd)
        finally
            # Then delete files whenever it's done
            @info "cleaning up tmp. files from DS9" fnames
            rm.(fnames)
        end
        return nothing
    end

    return task
end
export ds9show

"""
imshow(img; τ=5, lims=1200)

^ displays an image with +5 std, -2.5std, xlims and ylims set to 1200 mas.

Display an image with convenient formatting.
Looks into the FITS headers for the platescale, if available.

!! NOTE: You must install the Plots package to use imshow.
Run `using Plots` before `using SpaceImages` to enable.

"""
function imshow end

function imshow(img; τ=nothing, lims=nothing, kwargs... )
    error("The Plots package is not active. Run `using Plots` before `using SpaceImages` to enable.")
end

# Optionally depend on Plots
using Requires
function __init__()
    @require Plots="91a5bcdd-55d7-5caf-9e0b-520d859cae80" begin
        @eval using Plots

        function imshow(img; τ=nothing, lims=nothing, kwargs...)
        
        
            clims = nothing
            if !isnothing(τ)
                σ = std(filter(isfinite, view(img,:,:,1,1,1)))
                clims = (-0.5τ*σ, +1τ*σ)
            end
        
            xlims=nothing
            ylims=nothing
            if !isnothing(lims)
                if length(lims) == 1
                    lims = (-lims, lims)
                end
                xlims = lims
                ylims = lims
            end
        
        
            unit = "px"
            platescale = 1.0
            if hasproperty(img, :PIXSCALE)
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
        
        
        return heatmap(
                UnitRange(axes(img,1)).*platescale,
                UnitRange(axes(img,2)).*platescale,
                collect(transpose(img[:,:,1,1,1]));
                xlabel = "X - $unit",
                ylabel = "Y - $unit",
                fontfamily = "Times",
                minorticks = true,
                label = "",
                # grid = false,
                foreground_color_grid = "#000",
                gridalpha = 0.1,
                gridlinewidth = 1,
                framestyle = :box,
                # legend = false,
                # background_color_outside = "#000000",
                # background_color_inside = "#000000",
                # foreground_color = "#eee",
                aspect_ratio = 1,
                right_margin = 10Measures.mm,
                left_margin = 10Measures.mm,
                titlelocation = :left,
                clims,
                xlims,
                ylims,
                colorbar_title,
                kwargs...
        )
        end
    end

end
export imshow

