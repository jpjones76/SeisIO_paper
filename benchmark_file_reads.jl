using SeisIO, BenchmarkTools, Printf, Statistics
include("nice_disp.jl")

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 60
BenchmarkTools.DEFAULT_PARAMETERS.samples = 100
BenchmarkTools.DEFAULT_PARAMETERS.gcsample = true
BenchmarkTools.DEFAULT_PARAMETERS.evals = 1

const nx_add = 1400000
const nx_new = 36000
const pref  = pwd() * "/../test/SampleFiles/"
cfile = pref * "Restricted/03_02_27_20140927.sjis.ch"
test0 = String[
                "20050904.PA01.E.sac.ah"      "ah1"           " "
                "2019_07_07_00_00_00.h5"      "asdf"          " "
                "FDSNWS.IRIS.geocsv"          "geocsv"        " "
                "geocsv_slist.csv"            "geocsv.slist"  " "
                "one_day.mseed"               "mseed"         " "
                "Restricted/SHW.UW.mseed"     "mseed"         "lo-mem"
                "test_PASSCAL.segy"           "passcal"       "full"
                "one_day.sac"                 "sac"           "full"
                "SUDS/10081701.WVP"           "suds"          " "
                "99011116541W"                "uw"            " "
                "Restricted/2014092709*.cnt"  "win32"         "win"
              ]
const opts_guide = ["Options Info",
                    "String   Options Passed",
                    "full     full = true",
                    "lo-mem   nx_new=36000, nx_add=1400000",
                    "win      cfile=\"Restricted/03_02_27_20140927.sjis.ch\""
                    ]
const tests = hcat(pref.*test0[:,1], test0[:,2:3])

function run_benchmarks(n_0::Int64=1, n_1::Int64=0)
  N = size(tests,1)
  if n_1 == 0
    n_1 = N
  end

  R = Array{Union{Int64,Float64},2}(undef, N, 7)
  fill!(R, 0.0)
  for n = n_0:n_1
    fname = tests[n,1]
    f_call = tests[n,2]
    opt = tests[n,3]
    println( SeisIO.timestamp(), ": test ", n, "/", n_1, ", benchmark: ", f_call, ", file = ", fname, ", opts = ", opt)
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

R = run_benchmarks()
nice_disp(R)
