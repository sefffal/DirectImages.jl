
# The order here is designed to avoid an ambiguity warning in convert,
# see the top of ImageAxes
using ImageAxes
using ImageCore
using Images
import Images
using Printf
import AxisArrays
using OffsetArrays

import Base: +, -, *, /
import Base: permutedims



const ViewIndex = Union{Base.ViewIndex, Colon}

export
    # types
    DirectImage,

    # functions
    copyheaders,
    arraydata,
    headers,
    shareheaders,
    spatialheaders

#### types and constructors ####

using OrderedCollections

# Valid types for FITS headers. Restrict to only creating these values
# instead of erroring when trying to write them out.
ValTypes = Union{String, Bool, Integer, AbstractFloat, Nothing}

const FLEN_COMMENT = 73  # max length of a keyword comment string

struct CommentedValue
    value::ValTypes
    comment::String
    function CommentedValue(value, comment)
        if sizeof(comment) > FLEN_COMMENT
                @warn "Truncating comment to 73 bytes"
                comment = comment[begin:begin+FLEN_COMMENT]
        end
        new(value,comment)
    end
end

# Concrete types
"""
`DirectImage` is an AbstractArray that can have metadata, stored in a dictionary.
Construct an image with `DirectImage(A, props)` (for a headers dictionary
`props`), or with `DirectImage(A, prop1=val1, prop2=val2, ...)`.
"""
struct DirectImage{T,N,A<:AbstractArray} <: AbstractArray{T,N}
    data::A
    headers::OrderedDict{Symbol,CommentedValue}
end

# TODO: friendly constructors


function DirectImage(data::AbstractArray{T,N}) where {T,N}
    return DirectImage{T,N,typeof(data)}(data, OrderedDict{Symbol,CommentedValue}())
end

function DirectImage(data::AbstractArray{T,N}, headers::OrderedDict{Symbol,CommentedValue}) where {T,N}
    return DirectImage{T,N,typeof(data)}(data, headers)
end

function DirectImage(data::AbstractArray{T,N}, headers::OrderedDict{Symbol,CommentedValue}, axes::AbstractRange...) where {T,N}
    data_offset = OffsetArray(data, axes...)
    return DirectImage{T,N,typeof(data_offset)}(data_offset, headers)
end


const DirectImageArray{T,N,A<:Array} = DirectImage{T,N,A}
const DirectImageAxis{T,N,A<:AxisArray} = DirectImage{T,N,A}

Base.size(A::DirectImage) = size(arraydata(A))
Base.size(A::DirectImageAxis, Ax::Axis) = size(arraydata(A), Ax)
Base.size(A::DirectImageAxis, ::Type{Ax}) where {Ax<:Axis} = size(arraydata(A), Ax)
Base.axes(A::DirectImage) = axes(arraydata(A))
Base.axes(A::DirectImageAxis, Ax::Axis) = axes(arraydata(A), Ax)
Base.axes(A::DirectImageAxis, ::Type{Ax}) where {Ax<:Axis} = axes(arraydata(A), Ax)

"""
    origin(image_or_array)

Return the index corresponding to the "origin" of the data. If a regular array
or DirectImage, this is the same as `Images.center`. 

This function diverges from `Images.center` if the data has offset indices. In that
case, it returns the index closest to zero.

Example:
julia> rand(3,3) |> origin

"""
function origin(A::AbstractArray)
    Ifirst = first(CartesianIndices(A))
    if Ifirst == CartesianIndex((1 for _ in 1:length(Ifirst))...)
        return Images.center(A)
    else
        # We should be able to find this without iterating through all indices

        # How to find the index closest to zero?
        # CartesianIndex(Images.center.(axes(A))...)
        indices = Int[]
        for ax in 1:length(size(A))
            push!(indices, argmin(abs.(UnitRange(axes(A,ax)))))
        end
        return indices

        # closest_to_zero = firstindex(CartesianIndices(a))
        # closest_dist = zero(eltype(closest_to_zero))
        # for I in CartesianIndices(a)
        #     squares = zero(eltype(I))
        #     for i in eachindex(I)
        #         squares += i^2
        #     end

            
    end
end
function origin(A::AbstractArray, axis)
    return origin(A)[axis]
end
export origin

datatype(::Type{DirectImage{T,N,A}}) where {T,N,A<:AbstractArray} = A

Base.IndexStyle(::Type{M}) where {M<:DirectImage} = IndexStyle(datatype(M))

AxisArrays.HasAxes(A::DirectImageAxis) = AxisArrays.HasAxes{true}()

# getindex and setindex!
for AType in (DirectImage, DirectImageAxis)
    @eval begin
        @inline function Base.getindex(img::$AType{T,1}, i::Int) where T
            @boundscheck checkbounds(arraydata(img), i)
            @inbounds ret = arraydata(img)[i]
            ret
        end
        @inline function Base.getindex(img::$AType, i::Int)
            @boundscheck checkbounds(arraydata(img), i)
            @inbounds ret = arraydata(img)[i]
            ret
        end
        @inline function Base.getindex(img::$AType{T,N}, I::Vararg{Int,N}) where {T,N}
            @boundscheck checkbounds(arraydata(img), I...)
            @inbounds ret = arraydata(img)[I...]
            ret
        end

        @inline function Base.setindex!(img::$AType{T,1}, val, i::Int) where T
            @boundscheck checkbounds(arraydata(img), i)
            @inbounds arraydata(img)[i] = val
            val
        end
        @inline function Base.setindex!(img::$AType, val, i::Int)
            @boundscheck checkbounds(arraydata(img), i)
            @inbounds arraydata(img)[i] = val
            val
        end
        @inline function Base.setindex!(img::$AType{T,N}, val, I::Vararg{Int,N}) where {T,N}
            @boundscheck checkbounds(arraydata(img), I...)
            @inbounds arraydata(img)[I...] = val
            val
        end
    end
end

@inline function Base.getindex(img::DirectImageAxis, ax::Axis, I...)
    result = arraydata(img)[ax, I...]
    maybe_wrap(img, result)
end
@inline function Base.getindex(img::DirectImageAxis, i::Union{Integer,AbstractVector,Colon}, I...)
    result = arraydata(img)[i, I...]
    maybe_wrap(img, result)
end
maybe_wrap(img::DirectImage{T}, result::T) where T = result
maybe_wrap(img::DirectImage{T}, result::AbstractArray{T}) where T = copyheaders(img, result)


@inline function Base.setindex!(img::DirectImageAxis, val, ax::Axis, I...)
    setindex!(arraydata(img), val, ax, I...)
end
@inline function Base.setindex!(img::DirectImageAxis, val, i::Union{Integer,AbstractVector,Colon}, I...)
    setindex!(arraydata(img), val, i, I...)
end

Base.view(img::DirectImage, ax::Axis, I...) = shareheaders(img, view(arraydata(img), ax, I...))
Base.view(img::DirectImage{T,N}, I::Vararg{ViewIndex,N}) where {T,N} = shareheaders(img, view(arraydata(img), I...))
Base.view(img::DirectImage, i::ViewIndex) = shareheaders(img, view(arraydata(img), i))
Base.view(img::DirectImage, I::Vararg{ViewIndex,N}) where {N} = shareheaders(img, view(arraydata(img), I...))

@inline function Base.getproperty(img::DirectImage, propname::Symbol)::ValTypes
    if !haskey(headers(img), propname)
        propname = Symbol(uppercase(string(propname)))
    end
    return headers(img)[propname].value
end
@inline function Base.getindex(img::DirectImage, propname::Union{Symbol,String})::ValTypes
    if !haskey(headers(img), propname)
        propname = Symbol(uppercase(string(propname)))
    end
    return headers(img)[propname].value
end
@inline function Base.getindex(img::DirectImage, propname::Union{Symbol,String}, ::typeof(/))::String
    if !haskey(headers(img), propname)
        propname = Symbol(uppercase(string(propname)))
    end
    return headers(img)[propname].comment
end
@inline function Base.setproperty!(img::DirectImage, propname::Symbol, val)
    if !haskey(headers(img), propname)
        propname = Symbol(uppercase(string(propname)))
    end
    if haskey(headers(img), propname)
        headers(img)[propname] = CommentedValue(val, headers(img)[propname].comment)
    else
        headers(img)[propname] = CommentedValue(val, "")
    end
    return img
end
@inline function Base.setindex!(img::DirectImage, val, propname::Union{Symbol,String})
    if !haskey(headers(img), propname)
        propname = Symbol(uppercase(string(propname)))
    end
    if haskey(headers(img), propname)
        headers(img)[propname] = CommentedValue(val, headers(img)[propname].comment)
    else
        headers(img)[propname] = CommentedValue(val, "")
    end
    return img
end
@inline function Base.setindex!(img::DirectImage, comment, propname::Union{Symbol,String}, ::typeof(/))
    propname = Symbol(uppercase(string(propname)))
    if haskey(headers(img), propname)
        headers(img)[propname] = CommentedValue(img[propname], string(comment))
    else
        headers(img)[propname] = CommentedValue(nothing, string(comment))
    end
    comment
end


Base.propertynames(img::DirectImage) = (keys(headers(img))...,)

Base.copy(img::DirectImage) = DirectImage(copy(arraydata(img)), deepcopy(headers(img)))

Base.convert(::Type{DirectImage}, A::DirectImage) = A
Base.convert(::Type{DirectImage}, A::AbstractArray) = DirectImage(A)
Base.convert(::Type{DirectImage{T}}, A::DirectImage{T}) where {T} = A
Base.convert(::Type{DirectImage{T}}, A::DirectImage) where {T} = shareheaders(A, convert(AbstractArray{T}, arraydata(A)))
Base.convert(::Type{DirectImage{T}}, A::AbstractArray{T}) where {T} = DirectImage(A)
Base.convert(::Type{DirectImage{T}}, A::AbstractArray) where {T} = DirectImage(convert(AbstractArray{T}, A))

# copy headers
function Base.copy!(imgdest::DirectImage, imgsrc::DirectImage, prop1::Symbol, props::Symbol...)
    setproperty!(imgdest, prop1, deepcopy(getproperty(imgsrc, prop1)))
    for p in props
        setproperty!(imgdest, p, deepcopy(getproperty(imgsrc, p)))
    end
    return imgdest
end

# similar
Base.similar(img::DirectImage, ::Type{T}, shape::Dims) where {T} = DirectImage(similar(arraydata(img), T, shape), copy(headers(img)))
Base.similar(img::DirectImageAxis, ::Type{T}) where {T} = DirectImage(similar(arraydata(img), T), copy(headers(img)))
Base.similar(img::DirectImage{T,N,<:OffsetArray}) where{T,N} = DirectImage(similar(arraydata(img), T), copy(headers(img)))


"""
    copyheaders(img::DirectImage, data) -> imgnew
Create a new "image," copying the headers dictionary of `img` but
using the data of the AbstractArray `data`. Note that changing the
headers of `imgnew` does not affect the headers of `img`.
See also: [`shareheaders`](@ref).
"""
copyheaders(img::DirectImage, data::AbstractArray) =
    DirectImage(data, copy(headers(img)))

"""
    shareheaders(img::DirectImage, data) -> imgnew
Create a new "image," reusing the headers dictionary of `img` but
using the data of the AbstractArray `data`. The two images have
synchronized headers; modifying one also affects the other.
See also: [`copyheaders`](@ref).
"""
shareheaders(img::DirectImage, data::AbstractArray) = DirectImage(data, headers(img))

# Delete a property!
Base.delete!(img::DirectImage, propname::Symbol) = delete!(headers(img), propname)


# Iteration
# Defer to the array object in case it has special iteration defined
Base.iterate(img::DirectImage) = Base.iterate(arraydata(img))
Base.iterate(img::DirectImage, s) = Base.iterate(arraydata(img), s)

# Show
const emptyset = Set()
function showim(io::IO, img::DirectImage)
    IT = typeof(img)
    print(io, eltype(img).name.name, " DirectImage with:\n  data: ", summary(arraydata(img)), "\n  headers")
    showdictlines(io, headers(img), get(img, :suppress, emptyset))
end
Base.show(io::IO, img::DirectImage) = showim(io, img)
Base.show(io::IO, ::MIME"text/plain", img::DirectImage) = showim(io, img)

function Base.reinterpret(::Type{T}, img::DirectImage) where {T}
    shareheaders(img, reinterpret(T, arraydata(img)))
end
if Base.VERSION >= v"1.6.0-DEV.1083"
    function Base.reinterpret(::typeof(reshape), ::Type{T}, img::DirectImage) where {T}
        shareheaders(img, reinterpret(reshape, T, arraydata(img)))
    end
end


"""
    arraydata(img::DirectImage) -> array
Extract the data from `img`, omitting the headers
dictionary. `array` shares storage with `img`, so changes to one
affect the other.
See also: [`headers`](@ref).
"""
ImageAxes.arraydata(img::DirectImage) = getfield(img, :data)

function Base.PermutedDimsArray(A::DirectImage, perm)
    ip = sortperm([perm...][[coords_spatial(A)...]])  # the inverse spatial permutation
    permutedims_props!(copyheaders(A, PermutedDimsArray(arraydata(A), perm)), ip)
end
ImageCore.channelview(A::DirectImage) = shareheaders(A, channelview(arraydata(A)))
ImageCore.rawview(A::DirectImage{T}) where {T<:Real} = shareheaders(A, rawview(arraydata(A)))
ImageCore.normedview(::Type{T}, A::DirectImage{S}) where {T<:FixedPoint,S<:Unsigned} = shareheaders(A, normedview(T, arraydata(A)))

# AxisArrays functions
AxisArrays.axes(img::DirectImageAxis) = AxisArrays.axes(arraydata(img))
AxisArrays.axes(img::DirectImageAxis, d::Int) = AxisArrays.axes(arraydata(img), d)
AxisArrays.axes(img::DirectImageAxis, Ax::Axis) = AxisArrays.axes(arraydata(img), Ax)
AxisArrays.axes(img::DirectImageAxis, ::Type{Ax}) where {Ax<:Axis} = AxisArrays.axes(arraydata(img), Ax)
AxisArrays.axisdim(img::DirectImageAxis, ax) = axisdim(arraydata(img), ax)
AxisArrays.axisnames(img::DirectImageAxis) = axisnames(arraydata(img))
AxisArrays.axisvalues(img::DirectImageAxis) = axisvalues(arraydata(img))

#### Properties ####

"""
    headers(img) -> props
Extract the headers dictionary `props` for `img`. `props`
shares storage with `img`, so changes to one affect the other.
See also: [`arraydata`](@ref).
"""
headers(img::DirectImage) = getfield(img, :headers)


import Base: hasproperty
hasproperty(img::DirectImage, k::Symbol) = haskey(headers(img), k)

Base.get(img::DirectImage, k::Symbol, default) = get(headers(img), k, default)

# So that defaults don't have to be evaluated unless they are needed,
# we also define a @get macro (thanks Toivo Hennington):
struct IMNothing end   # to avoid confusion in the case where dict[key] === nothing
macro get(img, k, default)
    quote
        img, k = $(esc(img)), $(esc(k))
        val = get(headers(img), k, IMNothing())
        return isa(val, IMNothing) ? $(esc(default)) : val
    end
end

ImageAxes.timeaxis(img::DirectImageAxis) = timeaxis(arraydata(img))
ImageAxes.timedim(img::DirectImageAxis) = timedim(arraydata(img))

ImageCore.pixelspacing(img::DirectImage) = pixelspacing(arraydata(img))

"""
    spacedirections(img)
Using DirectImagedata, you can set this property manually. For example, you
could indicate that a photograph was taken with the camera tilted
30-degree relative to vertical using
```
img["spacedirections"] = ((0.866025,-0.5),(0.5,0.866025))
```
If not specified, it will be computed from `pixelspacing(img)`, placing the
spacing along the "diagonal".  If desired, you can set this property in terms of
physical units, and each axis can have distinct units.
"""
ImageCore.spacedirections(img::DirectImage) = @get img :spacedirections spacedirections(arraydata(img))

ImageCore.sdims(img::DirectImageAxis) = sdims(arraydata(img))

ImageCore.coords_spatial(img::DirectImageAxis) = coords_spatial(arraydata(img))

ImageCore.spatialorder(img::DirectImageAxis) = spatialorder(arraydata(img))

ImageAxes.nimages(img::DirectImageAxis) = nimages(arraydata(img))

ImageCore.size_spatial(img::DirectImageAxis) = size_spatial(arraydata(img))

ImageCore.indices_spatial(img::DirectImageAxis) = indices_spatial(arraydata(img))

ImageCore.assert_timedim_last(img::DirectImageAxis) = assert_timedim_last(arraydata(img))

#### Permutations over dimensions ####

"""
    permutedims(img, perm, [spatialprops])
When permuting the dimensions of an DirectImage, you can optionally
specify that certain headers are spatial and they will also be
permuted. `spatialprops` defaults to `spatialproperties(img)`.
"""
permutedims

function permutedims_props!(ret::DirectImage, ip, spatialprops=spatialproperties(ret))
    if !isempty(spatialprops)
        for prop in spatialprops
            if hasproperty(ret, prop)
                a = getproperty(ret, prop)
                if isa(a, AbstractVector)
                    setproperty!(ret, prop, a[ip])
                elseif isa(a, Tuple)
                    setproperty!(ret, prop, a[ip])
                elseif isa(a, AbstractMatrix) && size(a,1) == size(a,2)
                    setproperty!(ret, prop, a[ip,ip])
                else
                    error("Do not know how to handle property ", prop)
                end
            end
        end
    end
    ret
end

function permutedims(img::DirectImageAxis, perm)
    p = AxisArrays.permutation(perm, axisnames(arraydata(img)))
    ip = sortperm([p...][[coords_spatial(img)...]])
    permutedims_props!(copyheaders(img, permutedims(arraydata(img), p)), ip)
end
function permutedims(img::DirectImage, perm)
    ip = sortperm([perm...][[coords_spatial(img)...]])
    permutedims_props!(copyheaders(img, permutedims(arraydata(img), perm)), ip)
end

# Note: `adjoint` does not recurse into DirectImage properties.
function Base.adjoint(img::DirectImage{T,2}) where {T<:Real}
    ip = sortperm([2,1][[coords_spatial(img)...]])
    permutedims_props!(copyheaders(img, adjoint(arraydata(img))), ip)
end

function Base.adjoint(img::DirectImage{T,1}) where T<:Real
    check_empty_spatialproperties(img)
    copyheaders(img, arraydata(img)')
end

"""
    spatialproperties(img)
Return a vector of strings, containing the names of properties that
have been declared "spatial" and hence should be permuted when calling
`permutedims`.  Declare such properties like this:
    img[:spatialproperties] = [:spacedirections]
"""
spatialproperties(img::DirectImage) = @get img :spatialproperties [:spacedirections]

function check_empty_spatialproperties(img)
    sp = spatialproperties(img)
    for prop in sp
        if hasproperty(img, prop)
            error("spatialproperties must be empty, have $prop")
        end
    end
    nothing
end


function Images.centered(A::DirectImage)
    new_ax =  map(i->axes(A,i).-floor(Int, origin(A,i)), eachindex(axes(A)))
    DirectImage(A, headers(A), new_ax...)
end
export centered


#### Low-level utilities ####
function showdictlines(io::IO, dict::AbstractDict, suppress::Set)
    i = 0
    for (k, v) in dict
        i += 1
        if k === :suppress
            continue
        end
        if !in(k, suppress)
            val = string(v.value)[1:min(20,end)]
            @printf(io, "\n    %-8s= %-20s / %s", k, val, v.comment)
        else
            print(io, "\n    ", k, ": <suppressed>")
        end
        if i > 10
            l = length(dict) - 10
            print(io, "\n    ...       $l additional headers redacted")
            break
        end
    end
end
showdictlines(io::IO, dict::AbstractDict, prop::Symbol) = showdictlines(io, dict, Set([prop]))



