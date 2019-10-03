# Load packages and imports
using SeisIO, BenchmarkTools, Printf, Statistics
import SeisIO: safe_isdir, safe_isfile
include("run_benchmarks.jl")
include("nice_disp.jl")
include("declarations.jl")

# ===========================================================================
# Script
R = run_benchmarks()
nice_disp(R)
out = open("benchmarks_julia.csv", "w")
n = size(R,1)
for i = 1:n
  @printf(out, "%s;%s;%f;%f;%f;%f\n", test0[i,2], test0[i,1], R[i,1], R[i,2], R[i,3], R[i,5])
end
close(out)
