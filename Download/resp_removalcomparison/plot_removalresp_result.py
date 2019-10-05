import numpy as np
import csv
import matplotlib.pyplot as plt
import matplotlib.ticker as mattk

# Results of SeisIO Donwload validation
# plot computational time for bar chart

#-------------------------------------------------------------------#
fi_obspy = "Obspy_removaltrue.txt"
fi_seisio = "SeisIO_removaltrue.txt"

#---plot configuration---#
ref_col = 0.00*np.ones(3)
ju_col  = 0.25*np.ones(3)
py_col  = 0.50*np.ones(3)
rover_col = 0.75*np.ones(3)

py_label = "ObsPy v1.1.1"
ju_label = "SeisIO v0.4.0"

numchunk = 1*1 # 1sta, 3cha 3days
numiter = 100

#-------------------------------------------------------------------#


#read results
dl_o 	= np.zeros(numiter)
resp_o 	= np.zeros(numiter)
tot_o 	= np.zeros(numiter)

dl_s 	= np.zeros(numiter)
resp_s 	= np.zeros(numiter)
tot_s 	= np.zeros(numiter)


with open(fi_obspy) as csv_file:
	csv_reader = csv.reader(csv_file, delimiter=',')
	line_count = 0
	for row in csv_reader:
			dl_o[line_count] = row[0]
			resp_o[line_count] = row[1]
			tot_o[line_count] = row[2]
			line_count += 1



with open(fi_seisio) as csv_file:
	csv_reader = csv.reader(csv_file, delimiter=',')
	line_count = 0
	for row in csv_reader:
			dl_s[line_count] = row[0]
			resp_s[line_count] = row[1]
			tot_s[line_count] = row[2]
			line_count += 1


# compute mean and std
dl_o_mean = np.mean(dl_o) /1e3
resp_o_mean = np.mean(resp_o)  /1e3
tot_o_mean = np.mean(tot_o) /1e3

dl_s_mean = np.mean(dl_s) /1e3
resp_s_mean = np.mean(resp_s) /1e3
tot_s_mean = np.mean(tot_s) /1e3


dl_o_std = np.std(dl_o) /1e3
resp_o_std = np.std(resp_o) /1e3
tot_o_std = np.std(tot_o) /1e3

dl_s_std = np.std(dl_s) /1e3
resp_s_std = np.std(resp_s) /1e3
tot_s_std = np.std(tot_s) /1e3

print("obspy read %f"%dl_o_mean)
print("seisIO read %f"%dl_s_mean)
# plot bar chart


fig = plt.figure(num=None, figsize=(8.0, 8.0), dpi=80)
ax1 = fig.add_subplot(1, 1, 1)

#plt.yscale('log')

#plt.grid(which='major',color='black',linestyle='-', alpha=0.2)
#plt.grid(which='minor',color='black',linestyle=':', alpha=0.2)

# bars1 = [dl_s_mean/numchunk, resp_s_mean/numchunk, tot_s_mean/numchunk]
# bars2 = [dl_o_mean/numchunk, resp_o_mean/numchunk, tot_o_mean/numchunk]
#
# err1 = [dl_s_std/numchunk, resp_s_std/numchunk, tot_s_std/numchunk]
# err2 = [dl_o_std/numchunk, resp_o_std/numchunk, tot_o_std/numchunk]

bars1 = [dl_s_mean/numchunk, resp_s_mean/numchunk]
bars2 = [dl_o_mean/numchunk, resp_o_mean/numchunk]

err1 = [dl_s_std/numchunk, resp_s_std/numchunk]
err2 = [dl_o_std/numchunk, resp_o_std/numchunk]


barWidth = 0.3
r1 = np.arange(len(bars1))
r2 = [x + barWidth for x in r1]

ax1.bar(r1, bars1, color = ju_col, zorder = 10, width=barWidth,  yerr=err1, ecolor='k', capsize=5, alpha=1.0, edgecolor='k', label=ju_label)
ax1.bar(r2, bars2, color = py_col, zorder = 10, width=barWidth,  yerr=err2, ecolor='k', capsize=5, alpha=1.0, edgecolor='k', label=py_label)

# Add xticks on the middle of the group bars
plt.xticks([r + barWidth/2 for r in range(len(bars1))], ['Read Time', 'Response Removal', 'Total'])

ax1.legend(loc=2, markerscale=1.0, fontsize=12)

ax1.set_ylim(0, 22)

plt.ylabel('Time [s]', fontweight="bold", fontsize=14.0, family="serif", color="black")
ax1.set_title('TA.121A.HHZ: 1 day 100Hz', fontsize=14, color="black", fontweight="bold", family="serif")
plt.setp(ax1.get_yticklabels(), fontsize=12.0, color="black", fontweight="bold", family="serif")
plt.setp(ax1.get_xticklabels(), fontsize=12.0, color="black", fontweight="bold", family="serif")

th1 = plt.text(0.04, 0.3, "47.9ms", fontsize=14.0, rotation=90, rotation_mode='anchor', fontweight="bold")
th2 = plt.text(0.32, 0.5, "77.1ms", fontsize=14.0, rotation=90, rotation_mode='anchor', fontweight="bold")

fig.savefig("./Barchart_respremoval.png", dpi=300, format='png',
       transparent=False, frameon=False)
plt.show()

#print the ratio
print("Read speed: %s times speedup."%(dl_o_mean/dl_s_mean))
print("resp removal  : %s times speedup."%(resp_o_mean/resp_s_mean))
print("Total         : %s times speedup."%(tot_o_mean/tot_s_mean))
