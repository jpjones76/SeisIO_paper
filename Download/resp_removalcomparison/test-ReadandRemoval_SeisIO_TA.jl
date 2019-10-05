# """
# Evaluate computational time of pure instrumental response removal.
# Original script by Tim Clements
# Modified by Kurama Okubo
# 2019.10.2
# """

using PyCall, SeisIO, Printf, Dates, Plots, BenchmarkTools, Statistics
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


function resp_remove_all_seisio(mfile, xmlfile)

    S = read_data("mseed", mfile)
    remove_response!(S,xmlfile,0.05,19.9,np=2)

end

function main()
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

    ntrials = 100
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
    println("Save waveform for validation with Obspy")

    st = obspy.read(mfile)
    # save inventory

    if IsRemoveresp
        inv = obspy.read_inventory(xmlfile)
        st.attach_response(inv)
        pre_filt = (0.01, 0.05, 19.9, 20.0)
        st.remove_response(pre_filt=pre_filt,taper=false, zero_mean=false)
    end

    st.write("./"* join([net, sta, loc, cha],".")*"_$(IsRemoveresp)_Obspy.mseed", format="MSEED")

    #-----------------#
    #---SeisIO test---#
    #-----------------#
    # warmup
    # read waveform
    println("Save waveform for validation with SeisIO")

    S = read_data("mseed", mfile)

    if IsRemoveresp
        remove_response!(S,xmlfile,0.05,19.9,np=2)
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

        println("trial $ii: ")
        t_temp = now()

        t_temp_dl = @elapsed S = read_data("mseed", mfile)

        push!(SeisIO_cputime_dl, t_temp_dl*1e3)

        if IsRemoveresp
            t_temp_resp = @elapsed remove_response!(S,xmlfile,0.05,19.9,np=2)
            push!(SeisIO_cputime_resp, t_temp_resp*1e3)
        end

        push!(SeisIO_cputime_tot, (now()-t_temp).value)

        # GC.gc() is important to stabilize computational time for benchmark
        GC.gc()

    end
    t4 = now()

    seisT = round((t4 - t3).value / ntrials)
    println("Time for SeisIO: $(Millisecond(seisT)) ($ntrials trials)")

    if isempty(SeisIO_cputime_resp)
        SeisIO_cputime_resp = zeros(length(SeisIO_cputime_dl))
    end

    # output sigle process time
    fo = open("./SeisIO_removal$(IsRemoveresp).txt", "w");
    for i = 1:length(SeisIO_cputime_dl)
        write(fo, @sprintf("%12.8f, %12.8f, %12.8f\n", SeisIO_cputime_dl[i], SeisIO_cputime_resp[i], SeisIO_cputime_tot[i]))
    end
    close(fo)

end

main()
