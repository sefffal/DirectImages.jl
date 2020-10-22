module FITSImages

include("Type.jl")
include("IO.jl")
# using Images, ImageMetadata
# using OrderedCollections

# # Valid types for FITS headers. Restrict to only creating these values
# # instead of erroring when trying to write them out.
# ValTypes = Union{String, Bool, Integer, AbstractFloat, Nothing}

# const FLEN_COMMENT = 73  # max length of a keyword comment string

# struct CommentedValue
#     value::ValTypes
#     comment::String
#     function CommentedValue(value, comment)
#         if sizeof(comment) > FLEN_COMMENT
#                 @warn "Truncating comment to 73 bytes"
#                 comment = comment[begin:begin+FLEN_COMMENT]
#         end
#         new(value,comment)
#     end
# end
# CommentedValue(pair::Pair) = CommentedValue(pair[1], pair[2])

# function ai(data; properties...)
#     prop_dict = OrderedDict{Symbol,Any}()
#     for (key, val) in properties
#         if val isa Pair
#             prop_dict[key] = CommentedValue(val)
#         else
#             prop_dict[key] = CommentedValue(val, "")
#         end
#     end
#     ImageMeta(
#         data,
#         prop_dict
#     )
# end
# export ai


# # od = OrderedDict{Symbol,Any}(:abc=>(1=>nothing), :def=>(5=>nothing), :bef=>("abd"=>"comment1"))

# # img = ImageMeta(
# #     rand(100,100),
# #     od
# # )

end # module
