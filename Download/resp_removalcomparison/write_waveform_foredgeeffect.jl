# """
# Evaluate computational time of pure instrumental response removal.
# Original script by Tim Clements
# Modified by Kurama Okubo
# 2019.10.2
# """

using PyCall, SeisIO, Printf, Dates, Plots, BenchmarkTools, Statistics
using PlotlyJS

obspy = pyimport("obspy")
utcdate = pyimport_conda("obspy", "UTCDateTime")


"""
  remove_response!(S, stationXML, freqmin, freqmax)

Loads instrument response from stationXML and removes response from `S`.

# Arguments
- `S::SeisData`: SeisData structure.
- `stationXML::String`: Path to stationXML file, e.g. "/path/to/file.xml"
- `freqmin::Float64`: minimum frequency for pre-filtering.
- `freqmax::Float64`: maximum frequency for pre-filtering.
"""
function remove_response!(S::SeisData, stationXML::String, freqmin::Float64,
                          freqmax::Float64;np::Int=2, t_max::Float64=20.,
                          wl::Float32=eps(Float32),  α::Float64=0.05)

    # read response file
    if !isfile(stationXML)
        error("$stationXML does not exist. Instrument response not removed.")
    end

    R = read_sxml(stationXML)
    # loop through responses
    Rid = R.id
    Sid = S.id

    # remove trend, taper and prefilter
    #SeisIO.detrend!(S)
    SeisIO.taper!(S,t_max=t_max, α=α)
    filtfilt!(S,fl=freqmin,fh=freqmax,np=np,rt="Bandpass")

    # remove instrument response for each channel in S
    @inbounds for ii = 1:S.n
        id = S[ii].id
        ind = findfirst(x -> x == id,Rid)
        LOC = R[ind].loc
        GAIN = R[ind].gain
        RESP = R[ind].resp
        UNITS = R[ind].units
        setindex!(S.loc,LOC,ii)
        setindex!(S.gain,GAIN,ii)
        setindex!(S.units,UNITS,ii)
        translate_resp!(S,RESP,chans=ii,wl=wl)
        unscale!(S)

        # note instrument response removal
        notestr = string("translate_resp!, wl = ", wl,
                         ", stationXML = ", stationXML)
        note!(S,ii,notestr)
    end
    return nothing
end


#--- parameters----------------#
starttime   = "2018-03-01T00:00:00.000"
duration = 86400*1 # [s]

net = "TA"
sta = "121A"
loc = "--"
cha = "HHZ"

mfile = join([net, sta, loc, cha], ".") *".mseed"
xmlfile =join([net, sta],".")*".xml"

IsRemoveresp = true

taper_α = 0.002

#ntrials = 20
seconds = 120
samples = 100
#------------------------------#

Obspy_cputime_dl = Float64[]
Obspy_cputime_resp = Float64[]
Obspy_cputime_tot = Float64[]
SeisIO_cputime_dl = Float64[]
SeisIO_cputime_resp = Float64[]
SeisIO_cputime_tot = Float64[]

#-----------------#
#---Obspy test----#
# NOTE: It looks Julia is powerfully optimizing the obspy.remove_response() function itself as well when using BenchmarkTools.
# Thus, the benchmark result is much better than the one with python script.
# However, this is unfair for the comparison between python-based obspy vs. Julia-based SeisIO.
# Therefore, the python script for this benchmark is also provided and we use that result instead of the following result
# associated with obspy.
#-----------------#
# warm up
# read waveform
st = obspy.read(mfile)
# save inventory

if IsRemoveresp
    inv = obspy.read_inventory(xmlfile)
    st.attach_response(inv)
    pre_filt = (0.01, 0.05, 19.9, 20.0)
    st.remove_response(pre_filt=pre_filt,taper=true, taper_fraction= taper_α * 2, zero_mean=false) # NOTE: taper fraction of obspy is 2 * α in SeisIO.taper!()
end

st.write("./"* join([net, sta, loc, cha],".")*"_$(IsRemoveresp)_Obspy_wtaper.mseed", format="MSEED")


#-----------------#
#---SeisIO test---#
#-----------------#
# warmup
# read waveform

S = read_data("mseed", mfile)

if IsRemoveresp
    remove_response!(S,xmlfile,0.05,19.9, t_max = 3600., α = taper_α, np=2)
end

#wseis("./"* join([net, sta, loc, cha],".")*"_$IsRemoveresp_SeisIO.mseed", S)
# csv output for the time being.

tvec = collect(0:1.0/S[1].fs:duration-1)

# write it to csv
foname = "./"* join([net, sta, loc, cha],".")*"_$(IsRemoveresp)_SeisIO_wtaper.csv"

open(foname,"w") do fid
    println(fid, "t, x")
    for i in 1:length(tvec)
        println(fid, @sprintf("%12.8f, %e", tvec[i], S[1].x[i]))
    end
end

# plot difference between Julia and Python
S[1].x ./= maximum(abs.(S[1].x))
newarr = get(st,0).data ./ maximum(abs.(get(st,0).data))
starttime = u2d(S[1].t[1,2]*1e-6)
t = collect(starttime:Millisecond(1 / S[1].fs * 1000):starttime+Second(duration))[1:end-1]
#plotly()
span = 100
trace1 = PlotlyJS.scatter(;x= t[1:span:end], y=newarr[1:span:end-1],label="obspy")
trace2 = PlotlyJS.scatter(;x= t[1:span:end], y=S[1].x[1:span:end-1],label="SeisIO")
p = PlotlyJS.plot([trace1, trace2])
display(p)
readline()
#title!("Instrument response removal")
