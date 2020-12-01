using FITSIO


"""
    readfits("abc.fits", [hdu=:], [slices...=:])

Load a FITS file from the given file name or in-memory Byte array (Vector{UInt8}).

By default, this will return a vector of DirectImage for each data extension in the file.
You can also specify `hdu=1` for example, to only load the first image.

```julia
images = readfits("multiextension.fits", :)
one_img = readfits("multiextension.fits", 1)
```

By default, this will load all the data from each extension. You can also specify a subset
of data to load:

```julia
readfits("image.fits", 1, 200:300, 400:900, ...)
```
"""
function readfits(
    fname::Union{String,Vector{UInt8}},
    hdu::Union{Integer,AbstractRange,typeof(:)}=1,
    slices...
)

    return FITS(fname, "r") do fits

        try

            if hdu == (:)
                hdu = 1:length(fits)
            end

            # Handle loading multiple hdus if specified
            map(hdu) do h_no
                data = read(fits[h_no], slices...)
                headers = read_header(fits[h_no])

                img = DirectImage(data)
                for key in eachindex(headers)
                    img[Symbol(key)] = headers[key]
                    img[Symbol(key),/] = get_comment(headers, key)
                end

                if !haskey(headers, "FNAME")
                    img[:FNAME] = basename(fname)
                    img[:FNAME,/] = "file name, as loaded into Julia"
                end
                return img
            end

        catch err
            if !(typeof(err) <: InterruptException)
                @error "Error reading FITS file" exception=err
            end
            rethrow(err)
        end
    end
end
export readfits



"""
Write an array to a FITS file. Works for any array. Does not add headers
"""
function writefits(fname, images::DirectImage...)
    return FITS(fname, "w") do file
        try
            for img in images
                props = propertynames(img)
                headers = FITSHeader(
                    [String(prop) for prop in props],
                    Any[img[prop] for prop in props],
                    String[img[prop,/] for prop in props],
                )
                write(file, collect(arraydata(img)), header=headers)
            end
        catch exp
            println(stderr,exp)
            Base.show_backtrace(stderr)
            rethrow(exp)
        end
    end
end
"""
Write an array to a FITS file. Works for any array. Does not add headers
"""
function writefits(fname, images::AbstractArray...)
    return FITS(fname, "w") do fits
        try
            for img in images
                write(fits, collect(img))
            end
        catch exp
            println(stderr,exp)
            Base.show_backtrace(stderr)
            rethrow(exp)
        end
    end
end
export writefits


"""
    readheader("info.fits")

Read only the headers from a FITS file.
Returns an empty DirectImage with the headers populated and accessible as properties.

Note: readfits returns data combined with headers. There is no need to run both functions.

```julia
headers = readheader("info.fits")
headers.DATE_OBS == "2020-01-01"
```
"""
function readheader(
    fname::Union{String,Vector{UInt8}},
)

    images = FITS(fname, "r") do fits

        data = Int[]
        headers = read_header(first(fits))

        # Handle loading multiple hdus if specified
        map(hdu) do h_no
            data = read(fits[h_no], slices...)
            headers = read_header(fits[h_no])

            img = DirectImage(data)
            for key in eachindex(headers)
                img[Symbol(key)] = headers[key]
                img[Symbol(key),/] = get_comment(headers, key)
            end

            return hdu
        end
    end

    if typeof(hdu) <: Integer
        return images[1]
    else
        return images
    end
end
export readheader