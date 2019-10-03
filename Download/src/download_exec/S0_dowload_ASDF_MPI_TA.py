import sys
import time
import obspy
import pyasdf
import os, glob
import numpy as np
import pandas as pd
import noise_module_DLTEST
from mpi4py import MPI
from obspy import UTCDateTime
from obspy.clients.fdsn import Client
from obspy.io.sac.sactrace import SACTrace

if not sys.warnoptions:
    import warnings
    warnings.simplefilter("ignore")

'''
This downloading script:
    1) downloads data chunck on your choice of length and Client or pre-compiled station list;
    2) cleans up the traces including gaps, removing instrumental response, downsampling and trim;
    3) saves data into ASDF format;
    4) use MPI to speep up downloading process.

Authors: Marine Denolle (mdenolle@fas.harvard.edu) - 11/16/18,06/08/19
         Chengxin Jiang (chengxin_jiang@fas.harvard.edu) - 02/22/19,07/01/19

Note: 1. segmentation fault while manipulating obspy stream can come from too large data in memory:
     reduce the inc_hours variable.
      2. if choose to download stations from an existing CSV files, station with the same name but
     different channel is regarded as different stations.
      3. including the location code of the station sometime result in no-data during feteching pro-
      cessing, thus we recommend setting location code to "*" in the request setting when it is con-
      firmed by the users that no station with the same name but different location codes occurs

A beginning of wonderful NoisePy journey!
'''

#######################################################
################PARAMETER SECTION######################
#######################################################


#===Added for DLtest===#
args = sys.argv
#======================#

# paths and filenames
rootpath = os.getcwd()
DATADIR  = os.path.join(rootpath,'../output/%s/obspy/RAW_DATA'%args[1])         # where to store the downloaded data
stalist  = os.path.join(rootpath,'request_TA.csv')      # CSV file for station location info

# download parameters
client    = Client('IRIS')                      # client/data center. see https://docs.obspy.org/packages/obspy.clients.fdsn.html for a list
down_list = True                              # download stations from pre-compiled list
oput_CSV  = False                               # output station.list to a CSV file for future reference
flag      = False                               # print progress when running the script
NewFreq   = 40.0                                  # resampling at X samples per seconds
rm_resp   = False                               # False to not remove, True to remove, but 'inv' to remove with inventory
respdir   = 'none'                              # dir of response files (required if rm_resp is true and other than inv)
freqmin   = 0.05                                # pre filtering frequency bandwidth
freqmax   = 3                                   # note this cannot exceed Nquist freq
out_form  = 'ASDF'                              # choose between ASDF and SAC

# station/network information
# lamin,lomin,lamax,lomax=47,-124,49,-121         # regional box: min lat, min lon, max lat, max lon
# dchan= ['BH*']                                  # channel if down_list=false
# dnet = ["TA"]                                   # network
# dsta = ["*"]                                    # station (do either one station or *)

# target time range and interval
start_date = ["2014_03_01_0_0_0"]               # start date of download
end_date   = ["2014_03_17_0_0_0"]               # end date of download
inc_hours  = 24                                 # length of data for each request (in hour)

# pre-processing parameters: estimate memory needs
cc_len    = 3600                                # basic unit of data length for fft (s)
step      = 1800                                # overlapping between each cc_len (s)
MAX_MEM   = 3.0                                 # maximum memory allowed per core in GB

# time tags
starttime = obspy.UTCDateTime(start_date[0])
endtime   = obspy.UTCDateTime(end_date[0])
if flag:
    print('station.list selected [%s] for data from %s to %s with %sh interval'%(down_list,starttime,endtime,inc_hours))

# assemble parameters for pre-processing
prepro_para = {'rm_resp':rm_resp,'respdir':respdir,'freqmin':freqmin,'freqmax':freqmax,\
    'samp_freq':NewFreq,'start_date':start_date,'end_date':end_date,'inc_hours':inc_hours}
metadata = os.path.join(DATADIR,'download_info.txt')

# prepare station info (existing station list vs. fetching from client)
if down_list:
    if not os.path.isfile(stalist):
        raise IOError('file %s not exist! double check!' % stalist)

    # read station info from list
    locs = pd.read_csv(stalist)
    nsta = len(locs)
    chan = list(locs.iloc[:]['channel'])
    net  = list(locs.iloc[:]['network'])
    sta  = list(locs.iloc[:]['station'])
    lat  = list(locs.iloc[:]['latitude'])
    lon  = list(locs.iloc[:]['longitude'])

    # location info: useful for some occasion
    try:
        location = list(locs.iloc[:]['location'])
    except Exception as e:
        location = ['*']*nsta
    prepro_para['nsta'] = nsta

else:

    # gather station info
    try:
        inv = client.get_stations(network=dnet[0],station=dsta[0],channel=dchan[0],location='*', \
            starttime=starttime,endtime=endtime,minlatitude=lamin,maxlatitude=lamax, \
            minlongitude=lomin, maxlongitude=lomax,level="response")

        # make a selection to remove redundent channel (it indeed happens!)
        inv1 = inv.select(network=dnet[0],station=dsta[0],channel=dchan[0],starttime=starttime,\
            endtime=endtime,location='*')

        if flag:print(inv1)
    except Exception as e:
        print('Abort! '+str(e))
        sys.exit()

    # calculate the total number of channels for download
    sta=[];net=[];chan=[];location=[]
    nsta=0
    for K in inv:
        for sta1 in K:
            for chan1 in sta1:
                sta.append(sta1.code)
                net.append(K.code)
                chan.append(chan1.code)
                if chan1.location_code:
                    location.append(chan1.location_code)
                else: location.append('*')
                nsta+=1
    prepro_para['nsta'] = nsta

# crude estimation on memory needs (assume float32)
nsec_chunck = inc_hours/24*86400
nseg_chunck = int(np.floor((nsec_chunck-cc_len)/step))+1
npts_chunck = int(nseg_chunck*cc_len*NewFreq)
memory_size = nsta*npts_chunck*4/1024**3
if memory_size > MAX_MEM:
    raise ValueError('Require %s G memory for cc (%s GB provided)! Please consider \
        reduce inc_hours as it cannot load %s h of data all at once!' % (memory_size,MAX_MEM,inc_hours))


########################################################
#################DOWNLOAD SECTION#######################
########################################################

#--------MPI---------
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

if rank==0:
    if not os.path.isdir(DATADIR):os.mkdir(DATADIR)
    # output station list
    if not down_list:
        if oput_CSV:noise_module_DLTEST.make_stationlist_CSV(inv,DATADIR)
    # save parameters for future reference
    fout = open(metadata,'w')
    fout.write(str(prepro_para));fout.close()

    # get MPI variables ready
    all_chunck = noise_module_DLTEST.get_event_list(start_date[0],end_date[0],inc_hours)
    if len(all_chunck)<1:
        raise ValueError('Abort! no data chunck between %s and %s' % (start_date[0],end_date[0]))
    splits = len(all_chunck)-1
else:
    splits,all_chunck = [None for _ in range(2)]

# broadcast the variables
splits = comm.bcast(splits,root=0)
all_chunck  = comm.bcast(all_chunck,root=0)

tt0=time.time()

#--------MPI: loop through each time chunck--------
totalsize = 0

for ick in range (rank,splits,size):

    s1=obspy.UTCDateTime(all_chunck[ick])
    s2=obspy.UTCDateTime(all_chunck[ick+1])
    date_info = {'starttime':s1,'endtime':s2}

    # loop through each channel
    for ista in range(nsta):

        # select from existing inventory database
        if down_list:
            print('request station:',net[ista],sta[ista],location[ista],s1,s2)
            try:
                sta_inv = client.get_stations(network=net[ista],station=sta[ista],\
                    location=location[ista],starttime=s1,endtime=s2,level="response")
            except Exception as e:
                print('request station error:',e,'for',sta[ista]);continue
        else:
            sta_inv = inv1.select(network=net[ista],station=sta[ista],location=location[ista])
            if not sta_inv:
                continue

        if out_form == 'ASDF':
            ff=os.path.join(DATADIR,all_chunck[ick]+'T'+all_chunck[ick+1]+'.h5')
            with pyasdf.ASDFDataSet(ff,mpi=False,compression="gzip-3") as ds:
                # add the inventory for all components + all time of this tation
                try:ds.add_stationxml(sta_inv)
                except Exception: pass
        try:
            # get data
            t0=time.time()
            tr = client.get_waveforms(network=net[ista],station=sta[ista],\
                channel=chan[ista],location=location[ista],starttime=s1,endtime=s2)
            t1=time.time()
        except Exception as e:
            print('requesting data error',e,'for',sta[ista]);continue

        # preprocess to clean data

        totalsize = totalsize + tr[0].data.__sizeof__() #[Bytes]

        tr = noise_module_DLTEST.preprocess_raw(tr,sta_inv,prepro_para,date_info)
        t2 = time.time()

        if len(tr):
            if out_form == 'ASDF':
                with pyasdf.ASDFDataSet(ff,mpi=False,compression="gzip-3") as ds:
                    if location[ista] == '*':tlocation = str('00')
                    else:tlocation = location[ista]
                    new_tags = '{0:s}_{1:s}'.format(chan[ista].lower(),tlocation.lower())
                    ds.add_waveforms(tr,tag=new_tags)

            elif out_form == 'SAC':
                ff=os.path.join(DATADIR,net[ista]+sta[ista]+'.'+all_chunck[ick]+'T'+all_chunck[ick+1]+'.SAC')
                sac = SACTrace(nzyear=s1.year,nzjday=s1.julday,nzhour=s1.hour,nzmin=s1.minute,nzsec=s1.second,nzmsec=0,b=0,\
                    delta=1/tr[0].stats.sampling_rate,stla=sta_inv[0][0].latitude,stlo=sta_inv[0][0].longitude,data=tr[0].data)
                sac.write(ff,byteorder='big')

        if flag:
            print(new_tags);print('downloading data %6.2f s; pre-process %6.2f s' % ((t1-t0),(t2-t1)))

tt1=time.time()
print('downloading step takes %6.2f s' %(tt1-tt0))
comm.barrier()

totalsize = comm.gather(totalsize, root=0)

if rank == 0:
    # gather total download size
    totaldownloadsize = sum(totalsize) / 1e6 #[MB]
    fo=open(DATADIR+"/../downloadtime_TA_np%s.txt"%args[1], "w")
    fo.write('rank: %s size: %s\n'%(rank, size))
    fo.write("%12.8f [s]\n"%(tt1-tt0))
    fo.write("%12.4f [MB]\n"%(totaldownloadsize))
    fo.close()
    sys.exit()
