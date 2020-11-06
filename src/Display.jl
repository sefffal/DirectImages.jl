


# imview(image::AbstractArray) = Gray.(image)

using Plots
using RecipesBase
using Measures
using Statistics
# using ColorSchemes



export imshow

function imshow(img; τ=nothing, lims=nothing   )


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
        colorbar_title
   )
end



# @userplot ImPlot

# @recipe function f(h::ImPlot; τ=nothing, lims=nothing)

#     img = first(h.args)

#     fontfamily --> "Times"
#     minorticks --> true
#     # grid --> false
#     foreground_color_grid --> "#fff"
#     gridalpha --> 0.4
#     gridlinewidth --> 3
#     framestyle --> :box
#     # legend --> false
#     background_color_outside --> "#000000"
#     background_color_inside --> "#000000"
#     foreground_color --> "#eee"
#     aspect_ratio --> 1
#     right_margin --> 10Measures.mm
#     left_margin --> 10Measures.mm
#     titlelocation --> :left

#     if !isnothing(τ)
#         σ = std(filter(isfinite, view(img,:,:,1,1,1)))
#         clims --> (-0.5τ*σ, +1τ*σ)
#     end

#     if !isnothing(lims)
#         if length(lims) == 1
#             lims = (-lims, lims)
#         end
#         xlims --> lims
#         ylims --> lims
#     end


#     # Need to map xticks, etc.
    
#     @series begin
#         seriestype := :heatmap
#         # seriescolor --> ColorSchemes.grays
#         # (
#         #     axes(img,1),
#         #     axes(img,2)
#         #     1:size(img,2) .- origin(img,2),
#             collect(transpose(img[:,:,1,1,1]))
#         # )
#     end
#     label := ""

#     # This is a series recipe, and we return an empty arguments list to signal
#     # that this recipe is finished.  Most series recipes will return an empty tuple.
#     ()
# end


# @recipe function f(::Type{Val{:histogram}}, x, y, z)
#     edges, counts = my_hist(y, plotattributes[:bins],
#                                normed = plotattributes[:normalize],
#                                weights = plotattributes[:weights])
#     x := edges
#     y := counts
#     seriestype := :bar
#     ()
# end