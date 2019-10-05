import sys
import time
import obspy
import numpy as np
from obspy import UTCDateTime

if not sys.warnoptions:
    import warnings
    warnings.simplefilter("ignore")

'''
Obspy removal response benchmark
2019.10.1 Kurama Okubo
'''

#--- parameters----------------#
starttime   = "2018-03-01T00:00:00.000"
duration = 86400*1 # [s]

net = "TA"
sta = "121A"
loc = "--"
cha = "HHZ"

mfile = "%s.%s.%s.%s.mseed"%(net, sta, loc, cha)
xmlfile ="%s.%s.xml"%(net, sta)

pre_filt = (0.001, 0.005, 19.0, 20.0)

IsRemoveresp = True

#seconds = 120
samples = 2
#------------------------------#


Obspy_cputime_dl   = []
Obspy_cputime_resp = []
Obspy_cputime_tot  = []


for i in range(samples):
    print("trial %d"%i)
    t1 = time.time()
    # read waveform
    st = obspy.read(mfile)
    t2 = time.time()
    Obspy_cputime_dl.append(t2 - t1)
    t3 = time.time()
    if IsRemoveresp:
        inv = obspy.read_inventory(xmlfile)
        st.attach_response(inv)
        st.remove_response(pre_filt=pre_filt, taper=False, zero_mean=False)
        t4 = time.time()
        Obspy_cputime_resp.append(t4 - t3)
    else:
        Obspy_cputime_resp.append(0)
    t5 = time.time()
    Obspy_cputime_tot.append(t5 - t1)



# output sigle process time
respstr = "%s"%IsRemoveresp
fo = open("./Obspy_removal%s.txt"%(respstr.lower()), "w");
for i in range(len(Obspy_cputime_dl)):
    fo.write("%12.8f, %12.8f, %12.8f\n"%(Obspy_cputime_dl[i], Obspy_cputime_resp[i], Obspy_cputime_tot[i]))


fo.close()
