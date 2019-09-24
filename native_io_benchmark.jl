using SeisIO, SeisIO.RandSeis, Test, BenchmarkTools, Random
import SeisIO.RandSeis: randResp, randPhaseCat, randLoc, rand_t
import Statistics:median
include(dirname(pathof(SeisIO))*"/../test/test_helpers.jl")

# save to disk/read from disk
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 30
BenchmarkTools.DEFAULT_PARAMETERS.samples = 100
BenchmarkTools.DEFAULT_PARAMETERS.gcsample = true
BenchmarkTools.DEFAULT_PARAMETERS.evals = 1

const std_notes = [  string(SeisIO.timestamp(), ": I hear dueling banjos"),
                    string(SeisIO.timestamp(), ": Canoeing here was a bad idea") ]
const std_dict = Dict{String, Any}( "a" => randn(16, 4),
                                    "b" => NOOF,
                                    "c" => '🌑',
                                    "d" => rand(UInt8, 240800)
                                  )
const tests = [ "SeisData write",
                "SeisData read",
                "SeisHdr write",
                "SeisHdr read",
                "SeisEvent write",
                "SeisEvent read",
                "SeisChannel write",
                "SeisChannel read"]

function breaking_seis_bench()
  S = SeisData(randSeisData(5, nx=500000, s=1.0)[1:4], randSeisEvent(8, nx=10000), randSeisData(2, c=1.0, s=0.0, nx=50000)[2])

  # Misc
  S.misc[1] = breaking_dict
  S.misc[2] = breaking_dict
  S.misc[3] = breaking_dict

  # Name
  S.name[1] = "The quick brown fox jumped over the lazy dog"
  S.name[2] = "♅_Moominpaskanäköinen_🌝"
  S.name[3] = "The quick brown fox jumped over the lazy dog"

  # Loc
  S.loc[1] = GenLoc()
  S.loc[2] = UTMLoc()
  S.loc[3] = XYLoc()

  # Resp
  S.resp[1] = GenResp()
  S.resp[2] = PZResp()
  S.resp[3] = PZResp64()

  # X, T
  S.x[1] = rand(Float64,4)
  S.t[1] = vcat(S.t[4][1:1,:], [4 0])
  S.t[2] = rand_t(8)
  S.t[3] = rand_t(101)

  # IDs that I can search for
  S.id[1] = "UW.VLL..EHZ"
  S.id[2] = "CC.VALT..BHE"
  S.id[3] = "UW.TDH..EHZ"

  #= Here we test true, full Unicode support;
    only one valid separator in S.notes[1] =#
  notes       = Array{String,1}(undef,6)
  notes[1]    = string(String(Char.(0x00:0x7e)), String(Char.(0x80:0xff)))
  for i = 2:6
    notes[i]  = join(unicode_chars[randperm(div(n_unicode,2))])
  end
  setindex!(getfield(S, :notes), notes, 1)
  S.notes[2]  = std_notes
  S.notes[3]  = std_notes

  for i = 3:S.n
    nx          = lastindex(S.x[i])
    S.name[i]   = randstring(20)
    S.resp[i]   = randResp(4)
    S.loc[i]    = randLoc(false)
    S.notes[i]  = std_notes
    S.misc[i]   = std_dict
    S.units[i]  = "m/s"
    S.t[i]      = Array{Int64,2}([1 1556668800000000; nx 0])
  end

  return S
end

function standardize!(C::T, yx::Type=Float32) where T<:GphysChannel
  nx = 20000
  C.name  = randstring(20)
  C.resp  = randResp(4)
  C.loc   = randLoc(false)
  C.misc  = Dict{String, Any}("a" => randn(16, 4),
                              "b" => NOOF,
                              "c" => '🌑',
                              "d" => rand(UInt8, 240800))
  C.notes = std_notes
  C.t     = Array{Int64,2}([1 1556668800000000; nx 0])
  C.units = "m/s"
  if T == EventChannel
    C.pha = randPhaseCat(6)
  end
  C.x     = randn(yx, nx)
  return nothing
end

function nice_disp(R::Array{Union{Int64,Float64},2})
  N = size(R,1)
  Rs = Array{String,1}(undef, N+1)
  Rs[1] = @sprintf("%20s %9s %9s %9s%% %7s %7s %6s%% %6s",
    "Test", "Sz [MB]", "Mem [MB]", "Ovh", "Allocs", "T [ms]", "GC", "N")
  for n = 1:N
    filename = splitdir(tests[n,1])[2]
    Rs[n+1] = @sprintf( "%20s %9.2f %9.2f %9.2f%% %7i %7.2f %6.2f%% %6i",
      tests[n], R[n,1], R[n,2], R[n,3], R[n,4], R[n,5], R[n,6], R[n,7] )
  end
  printstyled(Rs[1]*"\n", bold=true, color=:green)
  for i = 2:size(Rs,1)
    println(Rs[i])
  end
  return nothing
end

function fill_R!(R::Array{Union{Int64,Float64},2}, n::Int64, sz::Float64, b::BenchmarkTools.Trial)
  mem = b.memory/1024^2 + (occursin("write", tests[n]) ? sz : 0.0)
  R[n,1] = sz
  R[n,2] = mem
  R[n,3] = 100.0*(mem-sz)/sz
  R[n,4] = b.allocs
  R[n,5] = median(b.times)*1.0e-6
  R[n,6] = 100.0*median(b.gctimes./b.times)
  R[n,7] = length(b.times)
  return nothing
end

function run_benchmark()
  savfile1 = "test_seis.dat"
  savfile2 = "test_hdr.dat"
  savfile3 = "test_evt.dat"
  N = 8
  R = Array{Union{Int64,Float64},2}(undef, N, 7)
  ov = BenchmarkTools.estimate_overhead()

  # Check that I didn't break it
  println("Precompile and checking for faithful read/write...")

  println("SeisData...")
  S = breaking_seis_bench()
  wseis(savfile1, S)
  S_r = rseis(savfile1)[1]
  @test S_r == S

  println("SeisHdr...")
  H = randSeisHdr()
  wseis(savfile2, H)
  H_r = rseis(savfile2)[1]
  @test H_r == H

  println("SeisEvent...")
  V = randSeisEvent(24, nx=20000)
  V.hdr.notes = std_notes
  V.hdr.misc = breaking_dict
  for i = 1:24
    standardize!(V.data[i])
  end
  wseis(savfile3, V)
  V_r = rseis(savfile3)[1]
  @test V_r == V

  C = randSeisChannel(s=true, nx=20000)
  standardize!(C)
  wseis(savfile1, C)
  C_r = rseis(savfile1)[1]
  @test C_r == C

  # 1: SeisData write
  println("1/", N, ": ", tests[1])
  S = breaking_seis_bench()
  B = @benchmarkable(wseis($savfile1, $S), overhead=ov)
  b = run(B)
  fill_R!(R, 1, sizeof(S)/1024^2, b)

  # 2: SeisData read
  println("2/", N, ": ", tests[2])
  B = @benchmarkable((S_in = rseis($savfile1)[1]), overhead=ov)
  b = run(B)
  fill_R!(R, 2, sizeof(S)/1024^2, b)

  # 3: SeisHdr write
  println("3/", N, ": ", tests[3])
  H = randSeisHdr()
  B = @benchmarkable(wseis($savfile2, $H))
  b = run(B)
  fill_R!(R, 3, sizeof(H)/1024^2, b)

  # 4: SeisHdr read
  println("4/", N, ": ", tests[4])
  B = @benchmarkable((H2 =rseis($savfile2)[1]), overhead=ov)
  b = run(B)
  fill_R!(R, 4, sizeof(H)/1024^2, b)

  # 5: SeisEvent write
  println("5/", N, ": ", tests[5])
  V = randSeisEvent(24, nx=20000)
  V.hdr.notes = std_notes
  V.hdr.misc = breaking_dict
  for i = 1:24
    standardize!(V.data[i])
  end

  B = @benchmarkable(wseis($savfile3, $V), overhead=ov)
  b = run(B)
  fill_R!(R, 5, sizeof(V)/1024^2, b)

  # 6: SeisEvent read
  println("6/", N, ": ", tests[6])
  B = @benchmarkable((V2 =rseis($savfile3)[1]), overhead=ov)
  b = run(B)
  fill_R!(R, 6, sizeof(V)/1024^2, b)

  # 7: SeisChannel write
  println("7/", N, ": ", tests[7])
  C = randSeisChannel(s=true, nx=20000)
  standardize!(C)
  B = @benchmarkable(wseis($savfile1, $C), overhead=ov)
  b = run(B)
  fill_R!(R, 7, sizeof(C)/1024^2, b)

  # 8: SeisChannel read
  println("8/", N, ": ", tests[8])
  B = @benchmarkable(C2 = rseis($savfile1), overhead=ov)
  b = run(B)
  fill_R!(R, 8, sizeof(C)/1024^2, b)
  return R
end

R = run_benchmark()
nice_disp(R)
