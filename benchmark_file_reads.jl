# Load packages and imports
using HDF5, SeisIO, BenchmarkTools, Pkg, Printf, Statistics
import SeisIO: safe_isdir, safe_isfile
include("run_benchmarks.jl")
include("run_benchmarks_mmap.jl")
include("nice_disp.jl")
include("declarations.jl")

# adjust as needed
i0 = 1   # min 1
i1 = 11  # max 11

# ===========================================================================
# Script
h = syshash()
f = join(string.(["bench", VERSION, h]), "_") * ".csv"
if isfile(f)
  @warn(string(f, " exists; script may overwrite.\nPress CTRL+C to cancel within 10 seconds..."))
  sleep(10)
end
R = run_benchmarks(i0, i1)
nice_disp(R)
if (!isfile(f) || minimum(R[:,2]) > 0.0)
  out = open(f, "w")
  n = size(R,1)
  for i = 1:n
    @printf(out, "%s;%s;%f;%f;%f;%f\n", tests[i,2], tests[i,1], R[i,1], R[i,2], R[i,3], R[i,5])
  end
  close(out)
  save_bench(h, tests, R)
else
  @warn("Some tests were skipped; .csv file not overwritten.")
end
