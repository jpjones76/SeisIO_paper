using SeisIO, SeisIO.RandSeis, Test, BenchmarkTools
include(dirname(pathof(SeisIO))*"/../test/test_helpers.jl")

# save to disk/read from disk
savfile1 = "test.seis"
savfile2 = "test.hdr"
savfile3 = "test.evt"

function breaking_seis_bench()
  S = SeisData(randSeisData(5, nx=500000, s=1.0)[1:4], randSeisEvent(8, nx=10000), randSeisData(2, c=1.0, s=0.0, nx=50000)[2])

  # Test a channel with every possible dict type
  S.misc[1] = breaking_dict

  # Test a channel with no notes
  S.notes[1] = []

  # A channel with a very long name to test in show.jl
  S.name[1] = "The quick brown fox jumped over the lazy dog"

  # A channel with a non-ASCII filename
  S.name[2] = "♅_Moominpaskanäköinen_🌝"

  #= Here we test true, full Unicode support;
    only 0xff can be a separator in S.notes[2] =#
  notes = Array{String,1}(undef,6)
  notes[1] = string(String(Char.(0x00:0x7e)), String(Char.(0x80:0xff)))
  for i = 2:6
    uj = randperm(div(n_unicode,2))
    notes[i] = join(unicode_chars[uj])
  end
  setindex!(getfield(S, :notes), notes, 2)

  # Test short data, loc arrays
  S.loc[1] = GenLoc()
  S.loc[2] = GeoLoc()
  S.loc[3] = UTMLoc()
  S.loc[4] = XYLoc()

  # Responses
  S.resp[1] = GenResp()
  S.resp[2] = PZResp()

  S.x[4] = rand(Float64,4)
  S.t[4] = vcat(S.t[4][1:1,:], [4 0])

  # Some IDs that I can search for
  S.id[1] = "UW.VLL..EHZ"
  S.id[2] = "UW.VLM..EHZ"
  S.id[3] = "UW.TDH..EHZ"
  return S
end
