"""
Execute SeisDownload for evaluation of download efficiency.
2019.09.30 Kurama Okubo
"""

@everywhere using SeisIO, SeisDownload, JLD2, Printf, Dates

#************************************#
#--- Process configuration---#
# request process; you can resume from perticular process by the following options

np = ARGS[1]
rootdir = pwd()
Outputdir   = rootdir*"/../output/$np/SeisIO"

# define global value
const DL_time_unit = 3600 * 24
const samplingfrequency = 40.0

#************************************#


#===
1. Seis Download configuration
===#
InputDictionary_download = Dict([
        "MAX_MEM_PER_CPU" =>  2.0, # [GB] maximum allocated memory for one cpu
        "DownloadType"=> "Noise", # Choise of "Noise" or "Earthquake"
        "starttime"   => DateTime(2014,3,1,0,0,0),
        "endtime"     => DateTime(2014,3,17,0,0,0),
        "DL_time_unit"     => DL_time_unit, # Download time unit [s] more than one day is better to avoid artifacts of response removal
        "IsLocationBox"    => false,
        "reg"              => [], # [minlat, maxlat, minlon, maxlon] if needed; you can combine this with station names as IRIS requests.
        "IsResponseRemove" => false, # remove instrumental response using SeisIO
        "download_margin"  => 60 * 0, # Int, [s] margin of both edges while downloading data to avoid the edge effect due to instrument response removal.
        "fopath"           => joinpath(Outputdir, "Rawdata.jld2"), # this is automatically determined by arguments
        "savesamplefreq"   => samplingfrequency, #[1/s] when saving the data, downsample at this freq
        "outputformat"     => "JLD2",   # output format can be JLD2, (under implementing; ASDF, SAC, ...)
        "Istmpfilepreserved" => false, # if true, do not delete intermediate binary tmp files
        "IsXMLfileRemoved" =>true, # if false, all station xml file is preserbed.
    ])


# HERE User can modify as their use; Please make 'stationinfo' dictionary as input.

stationlist       = String[]
stationmethod    = String[]
stationsrc        = String[]

# specific channels

#for TA network
network = ["TA"]

stream = open("request_TA.txt", "r")
station = String[]
while eof(stream) != true
    tmp = readline(stream, keep=true)
    sta = String(split(tmp)[2])
    push!(station, sta)
end
close(stream)

location = ["*"]
channel = ["BH*"]

method  = "FDSN" # Method to download data.
datasource = "IRIS" # currently, only one src can be specified.

stationlist       = String[]
stationmethod    = String[]
stationsrc        = String[]
for i=1:length(network)
    for j=1:length(station)
        for k=1:length(location)
            for l=1:length(channel)
                stationname = join([network[i], station[j], location[k], channel[l]], ".")
                push!(stationlist, stationname)

                #Here should be improved for multiple seismic network; we have to make
                #proper conbination of request station and data server.
                push!(stationmethod, method)
                push!(stationsrc, datasource)
            end
        end
    end
end

numofstation= length(stationlist)
stationinfo = Dict(["stationlist" => stationlist, "stationmethod" => stationmethod, "stationsrc" => stationsrc])

println("===SUMMARY===")
println("Num of Station = $numofstation.")

#add statinoinfo to input dictionary
InputDictionary_download["stationinfo"] = stationinfo

#println(InputDictionary_download)

st=time()
SeisDownload.seisdownload(InputDictionary_download)
et=time()
println("Download data successfully done in $(et-st) seconds.")


totaltime = et-st
np = nprocs() - 1
# output summary for Download efficiency evaluation
fo = open(Outputdir*"/downloadtime_TA_np$np.txt", "w");
write(fo, "rank: 0 size: $np\n")
write(fo, @sprintf("%12.8f [s]", totaltime))
close(fo)

println("#--------------------------------------------#");
println("All requested processes have been successfully done.");
println("Total Computational time is $totaltime seconds.");
println("#--------------------------------------------#");


rmprocs(workers())
