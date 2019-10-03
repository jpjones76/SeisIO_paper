# """
# Evaluate computational time of waveform validation.
# Original script by Tim Clements
# Modified for download process by Kurama Okubo
# 2019.10.2
# """

using PyCall, SeisIO, Printf, Dates, Plots
obspy = pyimport("obspy")
cls = pyimport_conda("obspy.clients.fdsn", "Client")
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
                          wl::Float32=eps(Float32))

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
    #SeisIO.taper!(S,t_max=t_max)
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
starttime   = "2014-03-01T12:00:00.000"
duration =  3600*6# [s]

net = "TA"
sta = "121A"
loc = "--"
cha = "BHZ"
client = cls.Client("IRIS")

IsRemoveresp = true

ntrials = 1
#------------------------------#

Obspy_cputime_dl = Float64[]
Obspy_cputime_resp = Float64[]
Obspy_cputime_tot = Float64[]
SeisIO_cputime_dl = Float64[]
SeisIO_cputime_resp = Float64[]
SeisIO_cputime_tot = Float64[]

# save stationxml for following removal test with SeisIO
t = utcdate.UTCDateTime(starttime)
stationxmlfilename = join([net, sta],".")*".xml"
inventory = client.get_stations(starttime=t, endtime=t+duration, network=net, sta=sta, loc=loc, channel=cha, level="response")
inventory.write(stationxmlfilename, format="stationxml")

#-----------------#
#---Obspy test---#
#-----------------#
# warm up
# download waveform
st = client.get_waveforms(net, sta, loc, cha, t, t+duration)
inv = client.get_stations(starttime=t, endtime=t+duration, network=net, sta=sta, loc=loc, channel=cha, level="response")
st.attach_response(inv)

# save inventory
if IsRemoveresp
    #inv = obspy.read_inventory(stationxmlfilename)
    #inventory = client.get_stations(starttime=t, endtime=t+duration, network=net, sta=sta, loc=loc, channel=cha, level="response")
    #st.attach_response(inv)
    pre_filt = (0.001, 0.005, 19.0, 20.0)
    st.remove_response(pre_filt=pre_filt,taper=false, zero_mean=false)
end

st.write("./"* join([net, sta, loc, cha],".")*"_$(IsRemoveresp)_Obspy.mseed", format="MSEED")

println("start test: Obspy")
# timing
t1 = now()
for ii = 1:ntrials
    println(ii)
    t_temp = now()

    t = utcdate.UTCDateTime(starttime)

    # download waveform
    # for fair comparison, download station xml and attach it to stream as SeisIO.get_data
    st = client.get_waveforms(net, sta, loc, cha, t, t+duration)
    inv = client.get_stations(starttime=t, endtime=t+duration, network=net, sta=sta, loc=loc, channel=cha, level="response")
    st.attach_response(inv)

    push!(Obspy_cputime_dl, (now()-t_temp).value/1e3)

    # save inventory
    if IsRemoveresp
        println("remove resp")
        #t_temp_resp = now()
        #inv = obspy.read_inventory(stationxmlfilename)
        #inventory = client.get_stations(starttime=t, endtime=t+duration, network=net, sta=sta, loc=loc, channel=cha, level="response")
        #st.attach_response(inv)
        pre_filt = (0.001, 0.005, 19.0, 20.0)
        t_temp_resp = @elapsed st.remove_response(pre_filt=pre_filt,taper=false, zero_mean=false)
        push!(Obspy_cputime_resp, t_temp_resp)
    end

    push!(Obspy_cputime_tot, (now()-t_temp).value/1e3)

end

t2 = now()

#-----------------#
#---SeisIO test---#
#-----------------#

# warmup
# download waveform
S = get_data("FDSN", join([net, sta, loc, cha],"."), s=starttime, t=duration, v=0, src="IRIS",
 unscale=false, demean=false, detrend=false, taper=false, ungap=false, rr=false)

# need to reset resp information to remove with stationxml file
@inbounds for ii = 1:S.n
    S.resp[ii] = SeisIO.PZResp()
    S.gain[ii] = 1.0
end

if IsRemoveresp
    remove_response!(S,stationxmlfilename,0.005,19.9,np=2)
end

#wseis("./"* join([net, sta, loc, cha],".")*"_$IsRemoveresp_SeisIO.mseed", S)
# csv output for the time being.

tvec = collect(0:1.0/S[1].fs:duration-1)

# write it to csv
foname = "./"* join([net, sta, loc, cha],".")*"_$(IsRemoveresp)_SeisIO.csv"

open(foname,"w") do fid
    println(fid, "t, x")
    for i in 1:length(tvec)
        println(fid, @sprintf("%12.8f, %e", tvec[i], S[1].x[i]))
    end
end



println("start test: SeisIO")
#timing
t3 = now()
for ii = 1:ntrials

    t_temp = now()

    t_temp_dl =  @elapsed S = get_data("FDSN", join([net, sta, loc, cha],"."), s=starttime, t=duration, v=0, src="IRIS",
    unscale=false, demean=false, detrend=false, taper=false, ungap=false, rr=false)

    push!(SeisIO_cputime_dl, t_temp_dl)

    # need to reset resp information to remove with stationxml file
    @inbounds for ii = 1:S.n
        S.resp[ii] = SeisIO.PZResp()
        S.gain[ii] = 1.0
    end

    if IsRemoveresp
        t_temp_resp = @elapsed remove_response!(S,stationxmlfilename,0.05,8.,np=2)
        push!(SeisIO_cputime_resp, t_temp_resp)
    end

    push!(SeisIO_cputime_tot, (now()-t_temp).value/1e3)

end
t4 = now()

obsT = round((t2 - t1).value / ntrials)
seisT = round((t4 - t3).value / ntrials)
println("Time for Obspy: $(Millisecond(obsT)) ($ntrials trials)")
println("Time for SeisIO: $(Millisecond(seisT)) ($ntrials trials)")
println("SeisIO SpeedUp: $(obsT/seisT)")

if isempty(Obspy_cputime_resp)
    Obspy_cputime_resp = zeros(length(Obspy_cputime_dl))
    SeisIO_cputime_resp = zeros(length(SeisIO_cputime_dl))
end

# output sigle process time
fo = open("./Obspy_removal$(IsRemoveresp).txt", "w");
for i = 1:length(Obspy_cputime_dl)
    write(fo, @sprintf("%12.8f %12.8f %12.8f\n", Obspy_cputime_dl[i], Obspy_cputime_resp[i], Obspy_cputime_tot[i]))
end
close(fo)

# output sigle process time
fo = open("./SeisIO_removal$(IsRemoveresp).txt", "w");
for i = 1:length(SeisIO_cputime_dl)
    write(fo, @sprintf("%12.8f %12.8f %12.8f\n", SeisIO_cputime_dl[i], SeisIO_cputime_resp[i], SeisIO_cputime_tot[i]))
end
close(fo)


# plot difference between Julia and Python
S[1].x ./= maximum(abs.(S[1].x))
newarr = get(st,0).data ./ maximum(abs.(get(st,0).data))
starttime = u2d(S[1].t[1,2]*1e-6)
t = collect(starttime:Millisecond(1 / S[1].fs * 1000):starttime+Second(duration))[1:end-1]
#plotly()
span = 100
using PlotlyJS
trace1 = PlotlyJS.scatter(;x= t[1:span:end], y=newarr[1:span:end-1],label="obspy")
trace2 = PlotlyJS.scatter(;x= t[1:span:end], y=S[1].x[1:span:end-1],label="SeisIO")
PlotlyJS.plot([trace1, trace2])
#title!("Instrument response removal")
