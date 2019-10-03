import numpy as np
import csv
import datetime
from obspy import read
import matplotlib.pyplot as plt
import matplotlib.ticker as mattk
from matplotlib.dates import  DateFormatter

# Results of SeisIO Donwload validation
# plot waveform and spectrum for validation of instrumental response removal

#-------------------------------------------------------------------#
fi_obspy = "TA.121A.--.BHZ_true_Obspy.mseed"
fi_seisio = "TA.121A.--.BHZ_true_SeisIO.csv"

#---plot configuration---#
ref_col = 0.00*np.ones(3)
ju_col  = 0.25*np.ones(3)
py_col  = 0.50*np.ones(3)
rover_col = 0.75*np.ones(3)

py_label = "ObsPy v1.1.1"
ju_label = "SeisIO v0.4.0"


#-------------------------------------------------------------------#

st = read(fi_obspy)
tr = st[0]
tvec = tr.times("matplotlib")  
obspy_v = [x * 1e6 for x in tr.data] #[micro m/s]

seisio_v = np.zeros(len(obspy_v))

with open(fi_seisio) as csv_file:
	csv_reader = csv.reader(csv_file, delimiter=',')
	line_count = 0
	for row in csv_reader:
		if line_count == 0:
			#print(f'Column names are {", ".join(row)}')
			line_count += 1
		else:
			seisio_v[line_count-1] = row[1]
			seisio_v[line_count-1] *= 1e6
			line_count += 1




#fig = plt.figure(num=None, figsize=(8.0, 8.0), dpi=300)
fig = plt.figure(num=None, figsize=(12.0, 8.0), dpi=80)
#plt.subplots_adjust(left=0.05, right=0.98)

#--- 1. result for TA ---#
ax1 = fig.add_subplot(1, 1, 1)

plt.grid(which='major',color='black',linestyle='-', alpha=0.2)
plt.grid(which='minor',color='black',linestyle=':', alpha=0.2)

plotspan = 40
linewidth = 1.5


ax1.plot_date(tvec[::plotspan], seisio_v[::plotspan], c='k', linestyle='-', linewidth=linewidth, label=ju_label)
ax1.plot_date(tvec[::plotspan], obspy_v[::plotspan], c=ju_col, linestyle=':', linewidth=linewidth*2.0, label=py_label)

ax1.xaxis.set_major_formatter( DateFormatter('%H:%M:%S') )
plt.xticks(rotation=45)
ax1.set_xlim([datetime.datetime(2014, 3, 1, 14, 0), datetime.datetime(2014, 3, 1, 14, 5)])
ax1.set_ylim([-1, 1])
#plt.xlabel('time', fontsize=14.0, family="serif", color="black")
plt.ylabel('velocity [$\mu$m/s]', fontweight="bold", fontsize=14.0, family="serif", color="black")
ax1.set_title('TA.121A.BHZ: 2014-03-01', fontsize=14, color="black", fontweight="bold", family="serif")
ax1.legend(loc=2, markerscale=0.0, fontsize=12)

ax1.lines[0].set_marker(None)
ax1.lines[1].set_marker(None)


plt.setp(plt.gca().get_yticklabels(), fontsize=12.0, color="black", fontweight="bold", family="serif")
plt.setp(plt.gca().get_xticklabels(), fontsize=12.0, color="black", fontweight="bold", family="serif")

plt.show()


fig.savefig("./waveform_comparison.png", dpi=300, format='png',
        transparent=False, frameon=False)
plt.show()

