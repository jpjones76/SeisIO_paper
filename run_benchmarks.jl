function run_benchmarks(n_0::Int64=1, n_1::Int64=0)
  N = size(tests,1)
  if n_1 == 0
    n_1 = N
  end
  has_restricted = safe_isdir(dirname(pathof(SeisIO)) * "/../test/SampleFiles/Restricted/")

  R = Array{Union{Int64,Float64},2}(undef, N, 7)
  fill!(R, 0.0)
  for n = n_0:n_1
    fname = tests[n,1]
    if occursin("Restricted", fname) && (has_restricted == false)
      printstyled( SeisIO.timestamp(), ": test ", n, "/", n_1, ", benchmark: SKIPPED (has_restricted = false)\n", color=:red)
      continue
    end
    f_call = tests[n,2]
    opt = tests[n,3]
    printstyled( SeisIO.timestamp(), ": test ", n, "/", n_1, ", benchmark: ", f_call, ", file = ", fname, ", opts = ", opt, "\n", color=:green)
    GC.gc()
    ov = BenchmarkTools.estimate_overhead()

    if opt == "win"
      S = read_data(f_call, fname, cf=cfile, nx_new=360000)
      B = @benchmarkable(read_data($f_call, $fname, cf=$cfile, nx_new=360000),  overhead=ov)
      b = run(B)
    elseif opt == "lo-mem"
      S = read_data(f_call, fname, nx_new=nx_new, nx_add=nx_add)
      B = @benchmarkable(read_data($f_call, $fname, nx_new=$nx_new, nx_add=$nx_add), overhead=ov)
      b = run(B)
    elseif opt == "full"
      S = read_data(f_call, fname, full=true)
      B = @benchmarkable(read_data($f_call, $fname, full=true),  overhead=ov)
      b = run(B)
    elseif f_call == "asdf"
      s = "2019-07-07T00:00:00"
      t = "2019-07-09T00:00:00"
      S = read_hdf5(fname, s, t)
      B = @benchmarkable(read_hdf5($fname, $s, $t), overhead=ov)
      b = run(B)
    else
      S = read_data(f_call, fname)
      B = @benchmarkable(read_data($f_call, $fname),  overhead=ov)
      b = run(B)
    end

    sz = sizeof(S)/1024^2
    mem = b.memory/1024^2
    R[n,1] = sz
    R[n,2] = mem
    R[n,3] = 100.0*(mem-sz)/sz
    R[n,4] = b.allocs
    R[n,5] = median(b.times)*1.0e-6
    R[n,6] = 100.0*median(b.gctimes./b.times)
    R[n,7] = length(b.times)
  end
  return R
end
