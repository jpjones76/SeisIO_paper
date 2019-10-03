# Prereqs:
# conda install pytest memory_profiler pyasdf
#
# Additional steps:
# 1. create an ObsPy environment so Python doesn't go self-incompatible
# 2. to benchmark restricted files:
#    a. determine the path of SeisIO in Julia:
#       using SeisIO; dirname(pathof(SeisIO))
#    b. replace the string value of SeisIO_path with the output of step a.
#    c. ensure that the files exist in SeisIO_path + '../test/SampleFiles/Restricted'
#       you'll need to follow the guidelines in Data Sources and Availability
import numpy as np
import gc
import os
import sys
import obspy
import pyasdf
from obspy import read
from obspy.io.ascii.core import _read_slist as read_slist
from memory_profiler import memory_usage
from timeit import default_timer as timer
from time import sleep
from sys import getsizeof
SeisIO_path = '/data2/Code/Julia/SeisIO/src'

def rasdf(file, path, tag):
    ds = pyasdf.ASDFDataSet(file, mpi=False, mode='r')
    tr = ds.waveforms[path][tag]
    return tr

def rslist(s):
    tr = read_slist(s)
    return tr

# from https://stackoverflow.com/questions/449560/how-do-i-determine-the-size-of-an-object-in-python
def get_obj_size(obj):
    marked = {id(obj)}
    obj_q = [obj]
    sz = 0

    while obj_q:
        sz += sum(map(sys.getsizeof, obj_q))
        all_refr = ((id(o), o) for o in gc.get_referents(*obj_q))
        new_refr = {o_id: o for o_id, o in all_refr if o_id not in marked and not isinstance(o, type)}
        obj_q = new_refr.values()
        marked.update(new_refr.keys())

    return sz

n = 100
ascii_formats = ['SLIST', 'TSPAIR']
bb = '../Benchmarks/'
rr = SeisIO_path + '/../test/SampleFiles/Restricted/'
rubric =[[bb+"1day-1hz.ah",         "AH",       "ok"],  # 0
         [bb+"2days-40hz.h5",       "ASDF",     "ok"],  # 1
         [bb+"geo-tspair.csv",      "TSPAIR",   "--"],  # 2 unsupported -- TSPAIR isn't GeoCSV
         [bb+"1day-100hz.mseed",    "MSEED",    "ok"],  # 3
         [rr+"SHW.UW.mseed",        "MSEED",    "ok"],  # 4
         [bb+"1day-100hz.segy",     "PASSCAL",  "--"],  # 5 unsupported -- SU SEG Y != PASSCAL SEG Y
         [bb+"1day-100hz.sac",      "SAC",      "ok"],  # 6
         [bb+"1h-62.5hz.slist",     "SLIST",    "ok"],  # 7
         [rr+"10081701.WVP",        "SUDS",     "--"],  # 8 unsupported
         [bb+"99011116541W",        "UW",       "--"],  # 9 unsupported
         [rr+"2014092709*.cnt",     "WIN",      "--"]   # 10 fails: ObsPy recognizes files as valid but reads no trace data and doesn't support wildcards.
         ]
Ntests = len(rubric)
T = np.zeros((1+len(rubric), n, 3), dtype=float)
# 0 size
# 1 memory
# 2 time
out = open('benchmarks_python.csv', 'w')

print("%13s %30s %9s %9s %9s %9s" % ('Format', 'File(s)', 'Sz_[MB]', 'Mem_[MB]', 'Ovh_[%]', 'T_[ms]'))
for j in range(0, Ntests):
    if rubric[j][2] == 'ok':
        s = rubric[j][0]
        if os.path.isfile(s) == False:
            print('file not found: %s' % s)
            continue
        for i in range(0, n):
            fmt = rubric[j][1]
            if j == 1:
                sta = 'CI.SDD'
                tag = 'CI.SDD..HHZ__2019-07-07T00:00:00__2019-07-09T00:00:00__hhz_'
                T[j,i,1] = memory_usage((rasdf, (s, sta, tag)), include_children=True, max_usage=True)[0]
                ts = timer()
                rt = rasdf(s, sta, tag)
                te = timer()
            else:
                T[j,i,1] = memory_usage((read, (s,), {'format' : fmt, 'check-compression' : False}), include_children=True, max_usage=True)[0]
                ts = timer()
                rt = read(s, format=fmt)
                te = timer()
            T[j,i,0] = get_obj_size(rt)/(1024**2)

            # the object size function doesn't track size accurately for ASCII formats
            if fmt in ascii_formats:
                T[j,i,0] += (8*len(rt.traces[0].data)/(1024**2))

            T[j,i,2] = (te-ts)*1000.0
            gc.collect()

        t = T[j,:,:]
        m = np.median(t, axis=0)
        fname = os.path.split(rubric[j][0])[1]
        print('%13s %30s %9.2f %9.2f %9.2f %9.2f'% (fmt, fname, m[0], m[1], 100.0*(m[1]/m[0]-1.0), m[2]))
        out.write('%s;%s;%f;%f;%f;%f\n'% (fmt, fname, m[0], m[1], 100.0*(m[1]/m[0]-1.0), m[2]))

out.close()
