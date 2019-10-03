# plot downloaded data to check if the waveform is identical
# Kurama Okubo

using SeisIO, Plots, Dates

starttime   = "2014-03-01T00:00:00"
endtime     = "2014-03-02T00:00:00"
# 1. load data with rover
fi_rover = "../output/4/rover/data/asdf.h5"
S = read_hdf5(fi_rover, starttime, endtime)

""""
ERROR AS FOLLOWS:
julia> S = read_hdf5(fi_rover, starttime, endtime)
ERROR: TypeError: in keyword argument x, expected Union{Array{Float32,1}, Array{Float64,1}}, got Array{Int32,1}
Stacktrace:
 [1] (::getfield(Core, Symbol("#kw#Type")))(::NamedTuple{(:id, :fs, :x),Tuple{String,Float64,Array{Int32,1}}}, ::Type{SeisChannel}) at ./none:0
 [2] read_asdf!(::SeisData, ::String, ::String, ::String, ::String, ::Bool, ::Int64) at /Users/kurama/.julia/dev/SeisIO/src/Submodules/SeisHDF/read_asdf.jl:66
 [3] read_asdf at /Users/kurama/.julia/dev/SeisIO/src/Submodules/SeisHDF/read_asdf.jl:120 [inlined]
 [4] #read_hdf5!#1(::String, ::String, ::Bool, ::Int64, ::typeof(read_hdf5!), ::SeisData, ::String, ::String, ::String) at /Users/kurama/.julia/dev/SeisIO/src/Submodules/SeisHDF/read_hdf5.jl:32
 [5] #read_hdf5! at ./none:0 [inlined]
 [6] #read_hdf5#2 at /Users/kurama/.julia/dev/SeisIO/src/Submodules/SeisHDF/read_hdf5.jl:56 [inlined]
 [7] read_hdf5(::String, ::String, ::String) at /Users/kurama/.julia/dev/SeisIO/src/Submodules/SeisHDF/read_hdf5.jl:55
 [8] top-level scope at REPL[29]:1
 """