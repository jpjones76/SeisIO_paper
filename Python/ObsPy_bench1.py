# Prereqs:
# conda install pytest memory_profiler pyasdf
# conda install -c conda-forge pytest-benchmark # NOT NEEDED
import numpy as np
import glob
import gc
import os
import sys
import obspy
from pyasdf import ASDFDataSet
from obspy import read
from memory_profiler import memory_usage
from timeit import default_timer as timer
from time import sleep

def get_obj_size(obj):
    marked = {id(obj)}
    obj_q = [obj]
    sz = 0

    while obj_q:
        sz += sum(map(sys.getsizeof, obj_q))

        # Lookup all the object referred to by the object in obj_q.
        # See: https://docs.python.org/3.7/library/gc.html#gc.get_referents
        all_refr = ((id(o), o) for o in gc.get_referents(*obj_q))

        # Filter object that are already marked.
        # Using dict notation will prevent repeated objects.
        new_refr = {o_id: o for o_id, o in all_refr if o_id not in marked and not isinstance(o, type)}

        # The new obj_q will be the ones that were not marked,
        # and we will update marked with their ids so we will
        # not traverse them again.
        obj_q = new_refr.values()
        marked.update(new_refr.keys())

    return sz

n = 100
rubric =[["20050904.PA01.E.sac.ah",     "AH"],              # 0
         ["2019_07_07_00_00_00.h5",     "asdf"],            # 1
         ["FDSNWS.IRIS.geocsv",         "TSPAIR"],          # 2 unsupported -- TSPAIR isn't GeoCSV
         ["geocsv_slist.csv",           "SLIST"],           # 3 unsupported -- SLIST isn't GeoCSV
         ["one_day.mseed",              "MSEED"],           # 4
         ["Restricted/SHW.UW.mseed",    "MSEED"],           # 5
         ["test_PASSCAL.segy",          "SU"],              # 6 unsupported -- SU SEG Y != PASSCAL SEG Y
         ["test_PASSCAL.segy",          "SU"],              # 7 unsupported -- SU SEG Y != PASSCAL SEG Y
         ["one_day.sac",                "SAC"],             # 8
         ["one_day.sac",                "SAC"],             # 9
         ["SUDS/10081701.WVP",          "SUDS"],            # 10 unsupported
         ["99011116541W",               "UW"],              # 11 unsupported
         ["Restricted/2014092709*.cnt", "WIN"]]             # 12 fails: ObsPy recognizes files as valid but reads no trace data; doesn't support wildcards.
T = np.zeros((1+len(rubric), n, 3), dtype=float)
# 0 size
# 1 memory
# 2 time

print("%13s %30s %9s %9s %9s %9s %9s" % ('Format', 'File(s)', 'Opts', 'Sz_[MB]', 'Mem_[MB]', 'Ovh_[%]', 'T_[ms]'))
path = os.path.abspath('../test/SampleFiles/')
for j in [0,4,5,8,9]:
    for i in range(0, n):
        s = path + '/' + rubric[j][0]
        fmt = rubric[j][1]
        opts = ' '
        if j == 9:
            T[j,i,1] = np.mean(memory_usage((read, (s,), {'format' : fmt, 'debug_headers' : True, 'check-compression' : False}), timeout=10.0, include_children=True, multiprocess=True))
            ts = timer()
            rt = read(s, format=fmt)
            te = timer()
            opts = 'debug'
        # elif j == 1:
            # ds = ASDFDataSet(s)
            # s = obspy.UTCDateTime("2019-07-07T23:00:00.000000Z")
            # t = obspy.UTCDateTime("2019-07-09T00:00:00.000000Z")
            # how do I load data between s and t from ds into an ObsPy Stream?
        else:
            T[j,i,1] = np.mean(memory_usage((read, (s,), {'format' : fmt, 'check-compression' : False}), timeout=10.0, include_children=True, multiprocess=True))
            ts = timer()
            rt = read(s, format=fmt)
            te = timer()
        T[j,i,0] = get_obj_size(rt)/(1024**2)
        T[j,i,2] = (te-ts)*1000.0
        gc.collect()

    t = T[j,:,:]
    m = np.median(t, axis=0)
    print('%13s %30s %9s %9.2f %9.2f %9.2f' '%9.2f'% (fmt, rubric[j][0], opts, m[0], m[1], 100.0*(m[1]/m[0]-1.0), m[2]) )

# find these with:
# import inspect
# inspect(obspy.io.sac.core)
# ...etc
# Using read functions directly
# ==========================================
# from obspy.io.ah.core import _read_ah1 as read_ah1
# from obspy.io.sac.core import _read_sac as read_sac
# from obspy.io.segy.core import _read_segy as read_segy
# from obspy.io.segy.core import _read_su_file as read_su
# from obspy.io.mseed.core import _read_mseed as read_mseed
# from obspy.io.win.core import _read_win as read_win
# from obspy.io.ascii.core import _read_slist as read_slist
# from obspy.io.ascii.core import _read_tspair as read_tspair
# def rah():
#     return read('../test/SampleFiles/lhz.ah', format="AH")
# def rmseed1():
#     # return read_mseed('../test/SampleFiles/one_day.mseed')
#     return read('../test/SampleFiles/one_day.mseed', format="MSEED")
# def rmseed2():
#     return read('../test/SampleFiles/Restricted/SHW.UW.mseed', format="MSEED")
# def rpasscal(s):
#     x = read_su(s, endian='<', unpack_headers=False)
#     stream = obspy.Stream()
#     endian = x.traces[0].endian
#     for tr in x.traces:
#         trace = obspy.Trace()
#         stream.append(trace)
#         trace.stats.su = obspy.core.AttribDict()
#         header = obspy.io.segy.core.LazyTraceHeaderAttribDict(tr.header.unpacked_header, tr.header.endian)
#         trace.stats.su.trace_header = header
#         trace.stats.su.endian = endian
#         tr_header = trace.stats.su.trace_header
#         if tr_header.sample_interval_in_ms_for_this_trace > 0:
#             trace.stats.delta = \
#                 float(tr.header.sample_interval_in_ms_for_this_trace) / \
#                 1E6
#         if tr_header.year_data_recorded > 0:
#             year = tr_header.year_data_recorded
#             if year < 100:
#                 if year < 30:
#                     year += 2000
#                 else:
#                     year += 1900
#             julday = tr_header.day_of_year
#             julday = tr_header.day_of_year
#             hour = tr_header.hour_of_day
#             minute = tr_header.minute_of_hour
#             second = tr_header.second_of_minute
#             trace.stats.starttime = obspy.UTCDateTime(
#                 year=year, julday=julday, hour=hour, minute=minute,
#                 second=second)
#     return stream
# def rsac():
#     return read('../test/SampleFiles/one_day.sac', format="SAC")
# def rsegy():
#     return read_segy('../test/SampleFiles/test_PASSCAL.segy')
# def rtspair():
#     return read_tspair(s)
# def rslist():
#     return read_slist(s)
# def rwin():
#     path = os.path.abspath('../test/SampleFiles/Restricted')
#     files = glob.glob(path + "/2014092709*.cnt")
#     tr = read_win(files[0])
#     files.pop(0)
#     for file in files:
#         tr += read_win(file)
#     return tr
# ==========================================
