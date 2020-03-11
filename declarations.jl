pref  = pwd() * "/Benchmarks/"
path  = dirname(pathof(SeisIO)) * "/../test/SampleFiles/"
cfile = realpath(path * "Restricted/03_02_27_20140927.sjis.ch")
const nx_add = 1400000
const nx_new = 36000
const mdb = "mach.h5"
const tests = String[
    realpath(pref*"1day-1hz.ah")                "ah1"       " "
    realpath(pref*"2days-40hz.h5")              "asdf"      " "
    realpath(pref*"geo-tspair.csv")             "geocsv"    " "
    realpath(pref*"1day-100hz.mseed")           "mseed"     " "
    realpath(pref*"1day-100hz.segy")            "passcal"   "full"
    realpath(pref*"1day-100hz.sac")             "sac"       "full"
    realpath(pref*"1h-62.5hz.slist")            "slist"     " "
    realpath(pref*"99011116541W")               "uw"        " "
    path*"Restricted/SHW.UW.mseed"              "mseed"     "lo-mem"
    path*"Restricted/10081701.WVP"              "suds"      " "
    path*"Restricted/2014092709*.cnt"           "win32"     "win"
  ]
const opts_guide = ["Options Info",
                    "String   Options Passed",
                    "full     full = true",
                    "lo-mem   nx_new=36000, nx_add=1400000",
                    "win      cfile=\"Restricted/03_02_27_20140927.sjis.ch\""
                    ]
BenchmarkTools.DEFAULT_PARAMETERS.seconds   = 60
BenchmarkTools.DEFAULT_PARAMETERS.samples   = 100
BenchmarkTools.DEFAULT_PARAMETERS.gcsample  = true
BenchmarkTools.DEFAULT_PARAMETERS.evals     = 1

# Generate a unique hash for the test machine's hardware
function syshash()
  ram = string(repr(Sys.total_memory()/1024^3, context=:compact=>true), " GB")
  cpu = [getfield(i, :model) for i in Sys.cpu_info()]
  arch = String(Sys.ARCH)
  h = hash(ram, zero(UInt64))
  h = hash(cpu, h)
  h = hash(arch, h)
  h = hash(Sys.MACHINE, h)
  h = hash(Sys.CPU_NAME, h)
  h = hash(Sys.CPU_THREADS, h)
  h = hash(Sys.JIT, h)
  h = hash(Pkg.installed()["HDF5"], h)
  sh = repr(h)

  # Store this info to a machine "database", i.e., an HDF5 file
  f = h5open(mdb, "cw")
  hkey =  string(VERSION) * "_" * sh
  if has(f, hkey) == false
    @warn(string("Creating entry for current machine in ", mdb))
    mach = g_create(f, hkey)
    mach["RAM"] = ram
    mach["CPU"] = cpu
    mach["ARCH"] = arch
    mach["MACHINE"] = Sys.MACHINE
    mach["CPU_NAME"] = Sys.CPU_NAME
    mach["CPU_THREADS"] = Sys.CPU_THREADS
    mach["JIT"] = Sys.JIT
    mach["HDF5"] = string(Pkg.installed()["HDF5"])
    close(f)
  else
    @info(string("An entry for the current machine exists in ", mdb))
  end
  return sh
end

function print_syshash(sh::String)
  f = h5open(mdb, "cw")
  hkey =  string(VERSION) * "_" * sh
  if has(f, hkey) == false
    @error(string("No entry for current machine in ", mdb, "!"))
  else
    println("Current machine data in ", mdb, ":")
    println("Key = ", hkey)
    mach = f[hkey]
    D = read(mach)
    w = min(64, displaysize(stdout)[2]-24)
    for k in sort(collect(keys(D)))
      val = string(D[k])

      # These don't affect the hash value
      if !(k in ("TESTS", "RESULTS"))
        if length(val) > w
          val = val[1:w] * " ... "
        end
        println(lpad(k, 13), ": ", val)
      end
    end
  end
  return nothing
end

function save_bench(sh::String, tmat::Array{String,2}, R::Array{Union{Int64,Float64},2})
  f = h5open(mdb, "cw")
  tests = hcat([splitdir(i)[2] for i in tmat[:,1]], tmat[:,2:3])
  test_fnames = tests[:,1]

  # Check for machine key
  hkey =  string(VERSION) * "_" * sh
  if has(f, hkey) == false
    @error(string("No entry for current machine in ", mdb, "!"))

  # Machine key exists
  else
    mach = f[hkey]

    # Check for tests
    if has(mach, "TESTS") || has(mach, "RESULTS")
      @info(string("Overwriting key ", hkey, " in ", mdb))

      # Get old results
      results = mach["RESULTS"]
      file_tests = mach["TESTS"]

      # Get list of file names in old tests; check each current test against it
      fnames = file_tests[:,1]
      for j in 1:length(test_fnames)
        (R[j,2] == 0.0) && continue
        r = Float64.(R[j, :])
        i = findfirst(fnames .== test_fnames[j])

        # File hasn't been tested on this machine before
        if i == nothing
          println("found new test: ", test_fnames[j])
          append!(file_tests, tests[j, :])
          results = vcat(results, Float64.(R[j, :]))

        # File has been tested and was part of current test set
        else
          println("overwriting test: ", test_fnames[j])
          file_tests[i, :] .= tests[j, :]
          results[i, :] .= Float64.(R[j, :])
        end
      end
      o_delete(mach["TESTS"])
      o_delete(mach["RESULTS"])
      mach["TESTS"] = file_tests
      mach["RESULTS"] = results
    else
      @info(string("Storing new test set for machine key ", hkey, " in ", mdb))
      results = R
      mach["TESTS"] = tests
      mach["RESULTS"] = Float64.(R)
    end
  end
end
