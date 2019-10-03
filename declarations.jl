pref  = pwd() * "/Benchmarks/"
path  = dirname(pathof(SeisIO)) * "/../test/SampleFiles/"
cfile = path * "Restricted/03_02_27_20140927.sjis.ch"
const nx_add = 1400000
const nx_new = 36000
const tests = String[
                pref*"1day-1hz.ah"                    "ah1"           " "
                pref*"2days-40hz.h5"                  "asdf"          " "
                pref*"geo-tspair.csv"                 "geocsv"        " "
                pref*"1day-100hz.mseed"               "mseed"         " "
                pref*"1day-100hz.segy"                "passcal"       "full"
                pref*"1day-100hz.sac"                 "sac"           "full"
                pref*"1h-62.5hz.slist"                "slist"         " "
                pref*"99011116541W"                   "uw"            " "
                path*"Restricted/SHW.UW.mseed"        "mseed"         "lo-mem"
                path*"Restricted/10081701.WVP"        "suds"          " "
                path*"Restricted/2014092709*.cnt"     "win32"         "win"
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
