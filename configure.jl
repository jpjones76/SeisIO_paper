# Check for needed packages
using Pkg

function pkg_check(pkgs::Array{String,1})
  for p in pkgs
    if get(Pkg.installed(), p, nothing) == nothing
      Pkg.add(p)
    else
      println(p * " found, not installing.")
    end
  end
  return nothing
end

pkg_check(["BenchmarkTools", "PyPlot", "SeisIO"])
sacfile = "SAC/benchmarks_sac.csv"
bench_dir = "Benchmarks"

if isfile(sacfile)
  println(sacfile * " found, not generating SAC benchmark stats.")
else
  include("run_sac_stats.jl")
end
