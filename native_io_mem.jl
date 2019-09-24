using SeisIO, SeisIO.RandSeis, Test, Random
import SeisIO.RandSeis: randResp, randPhaseCat, randLoc, rand_t
import Statistics:median
include(dirname(pathof(SeisIO))*"/../test/test_helpers.jl")

savfile1 = "test_seis.dat"
savfile2 = "test_hdr.dat"
savfile3 = "test_evt.dat"
const std_notes = [  string(SeisIO.timestamp(), ": I hear dueling banjos"),
                    string(SeisIO.timestamp(), ": Canoeing here was a bad idea") ]
const std_dict = Dict{String, Any}( "a" => randn(16, 4),
                                    "b" => NOOF,
                                    "c" => '🌑',
                                    "d" => rand(UInt8, 240800)
                                  )

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

# Check that I didn't break it
# Data
S = breaking_seis_bench()
wseis(savfile1, S)
S_r = rseis(savfile1)[1]
@test S == S_r

# Hdr
H = randSeisHdr()
wseis(savfile2, H)
H_r = rseis(savfile2)[1]
@test H == H_r

# Event
V = randSeisEvent(24, nx=20000)
V.hdr.notes = std_notes
V.hdr.misc = breaking_dict
for i = 1:24
  standardize!(V.data[i])
end
wseis(savfile3, V)
V_r = rseis(savfile3)[1]
@test V == V_r
nothing
