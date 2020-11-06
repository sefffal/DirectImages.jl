
using Dates, AstroTime

export mjd
"""
    mjd("2020-01-01")

Get the modfied julian date of a date, or in general a UTC
timestamp.
"""
function mjd(timestamp::AbstractString)
    return timestamp |> 
        UTCEpoch |>
        modified_julian |>
        days |>
        value;
end
export mjd