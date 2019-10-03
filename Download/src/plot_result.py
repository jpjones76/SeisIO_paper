import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mattk

# Results of SeisIO Donwload validation
# Manually read the computational time and donwload size from output log of each tool
# Because obspy does not work with np=10 on IRISDMC, ignore the result of np=10 for TA.
# time unit is [second]

#-------------------------------------------------------------------#
NW_TA = [1,2,4,8] #Number of Workers
NW_BP = [1,2,4,8,16,32] # number of workers
# 1. TA
dsize_TA = 6635.5674 #[MB]
rover_TA = [57.1*60, 27.3*60, 14.0*60, 7.4*60] #(nw, time) = (10, 5.8*60)
obspy_TA = [1983.27288818, 867.22932243, 433.88771629, 206.68937683] #(nw, time) = (10, NaN)
SeisIO_TA = [1156.97683001, 540.55473900, 314.38477707, 160.92335701] #(nw, time) = (10, 160.88732409)
# 2. BP
dsize_BP = 6274.9970 #[MB]
obspy_BP = [3873.94928622, 2130.17192125, 1070.35983872, 545.40759301, 289.60592937, 171.31436825]
SeisIO_BP = [1015.56813288, 501.46771002, 248.90292001, 185.52307582, 114.50451303, 82.02367902]
# 3. Instrumental resp
dsize_resp = 396.6349 #[MB]
chunknum = 2 * 10 * 3 # 2 days, 10 station with 3 channel
obspy_respref = 277.53793502 # 2 days, 10 station with 3 channel
obspy_resp = 3491.07119632
SeisIO_respref = 85.28962803
SeisIO_resp = 93.50685596
#-------------------------------------------------------------------#

#---plot configuration---#
ref_col = 0.00*np.ones(3)
ju_col  = 0.25*np.ones(3)
py_col  = 0.50*np.ones(3)
rover_col = 0.75*np.ones(3)

py_label = "ObsPy v1.1.1"
ju_label = "SeisIO v0.4.0"
sz_label = "File Size"
rover_label = "Rover v1.0.4"


IfplotFigure1 = True
IfplotFigure2 = True
IfplotFigure3 = True
#-------------------------#

if IfplotFigure1:
#1. computational efficiency

    y_r_TA = [dsize_TA / x for x in rover_TA]
    y_o_TA = [dsize_TA / x for x in obspy_TA]
    y_s_TA = [dsize_TA / x for x in SeisIO_TA]

    y_o_BP = [dsize_BP / x for x in obspy_BP]
    y_s_BP = [dsize_BP / x for x in SeisIO_BP]

    #fig = plt.figure(num=None, figsize=(8.0, 8.0), dpi=300)
    fig = plt.figure(num=None, figsize=(16.0, 8.0), dpi=80)
    plt.subplots_adjust(left=0.05, right=0.98)

    #--- 1. result for TA ---#
    ax1 = fig.add_subplot(1, 2, 1)

    plt.xscale('log')
    plt.yscale('log')

    plt.grid(which='major',color='black',linestyle='-', alpha=0.2)
    plt.grid(which='minor',color='black',linestyle=':', alpha=0.2)

    ax1.set_xticks([1, 2, 4, 8])
    ax1.get_xaxis().set_major_formatter(mattk.ScalarFormatter())
    ax1.set_yticks([1, 10, 100])
    ax1.get_yaxis().set_major_formatter(mattk.ScalarFormatter())

    markersize_r = 100
    markersize_o = 100
    markersize_s = 120

    ax1.scatter(NW_TA, y_s_TA, marker="D", s=markersize_s, zorder=10, clip_on=False, c=ju_col, edgecolors='k', label=ju_label)
    ax1.scatter(NW_TA, y_o_TA, marker="s", s=markersize_o, zorder=10, clip_on=False, c=py_col, edgecolors='k', label=py_label)
    ax1.scatter(NW_TA, y_r_TA, marker="v", s=markersize_r, zorder=10, clip_on=False, c=rover_col, edgecolors='k', label=rover_label)

    plt.xlabel('Number of Workers', fontweight="bold", fontsize=14.0, family="serif", color="black")
    plt.ylabel('Download Efficiency [MB/s]', fontweight="bold", fontsize=14.0, family="serif", color="black")
    ax1.set_title('TA: IRISDMC', fontsize=14, color="black", fontweight="bold", family="serif")

    plt.xlim(1, 8)
    plt.ylim(1, 100)
    ax1.legend(loc=2, markerscale=1.0, fontsize=12)

    plt.setp(plt.gca().get_yticklabels(), fontsize=12.0, color="black", fontweight="bold", family="serif")
    plt.setp(plt.gca().get_xticklabels(), fontsize=12.0, color="black", fontweight="bold", family="serif")

    for tic in ax1.xaxis.get_minor_ticks():
        tic.tick1On = tic.tick2On = False
        tic.label1On = tic.label2On = False




    #--- 2. result for BP ---#
    ax2 = fig.add_subplot(1, 2, 2)

    plt.xscale('log')
    plt.yscale('log')

    plt.grid(which='major',color='black',linestyle='-', alpha=0.2)
    plt.grid(which='minor',color='black',linestyle=':', alpha=0.2)

    ax2.set_xticks([1, 2, 4, 8, 16, 32])
    ax2.get_xaxis().set_major_formatter(mattk.ScalarFormatter())
    ax2.set_yticks([1, 10, 100])
    ax2.get_yaxis().set_major_formatter(mattk.ScalarFormatter())

    ax2.scatter(NW_BP, y_s_BP, marker="D", s=markersize_s, zorder=10, clip_on=False, c=ju_col, edgecolors='k', label=ju_label)
    ax2.scatter(NW_BP, y_o_BP, marker="s", s=markersize_o, zorder=10, clip_on=False, c=py_col, edgecolors='k', label=py_label)

    plt.xlabel('Number of Workers', fontweight="bold", fontsize=14.0, family="serif", color="black")
    plt.ylabel('Download Efficiency [MB/s]', fontweight="bold", fontsize=14.0, family="serif", color="black")
    ax2.set_title('BP: NCEDC', fontsize=14, color="black", fontweight="bold", family="serif")

    plt.xlim(1, 32)
    plt.ylim(1, 100)
    ax2.legend(loc=2, markerscale=1.0, fontsize=12)

    plt.setp(plt.gca().get_yticklabels(), fontsize=12.0, color="black", fontweight="bold", family="serif")
    plt.setp(plt.gca().get_xticklabels(), fontsize=12.0, color="black", fontweight="bold", family="serif")

    for tic in ax2.xaxis.get_minor_ticks():
        tic.tick1On = tic.tick2On = False
        tic.label1On = tic.label2On = False


    fig.savefig("../result/DownloadEfficiency.png", dpi=300, format='png',
            transparent=False, frameon=False)
    plt.show()



if IfplotFigure2:
    fig, (ax1, ax2) = plt.subplots(2, 1, sharex=True, figsize=(8.0, 8.0), dpi=80)


    #fig = plt.figure(num=None, figsize=(8.0, 8.0), dpi=80)
    #ax1 = fig.add_subplot(1, 1, 1)

    respref_o = obspy_respref / chunknum # Unit is now [s / channel / day (20Hz)]
    resp_o = obspy_resp / chunknum
    respref_s = SeisIO_respref / chunknum
    resp_s = SeisIO_resp / chunknum

    objects = ('SeisIO', 'Obspy')
    y_pos = np.arange(len(objects))
    comptime_dl = [respref_s, respref_o]

    remresp_o = resp_o-respref_o
    remresp_s = resp_s-respref_s

    comptime_rmresp = [remresp_s, remresp_o]

    ax1.bar(y_pos, comptime_rmresp, color = rover_col, align='center', alpha=1.0, edgecolor='k', bottom = comptime_dl, label="Remove resp")
    ax1.bar(y_pos, comptime_dl, color = ju_col, align='center', alpha=1.0, edgecolor='k', label="Download")

    ax2.bar(y_pos, comptime_rmresp, color = rover_col, align='center', alpha=1.0, edgecolor='k', bottom = comptime_dl, label="Remove resp")
    ax2.bar(y_pos, comptime_dl, color = ju_col, align='center', alpha=1.0, edgecolor='k', label="Download")

    ax1.legend(loc=2, markerscale=1.0, fontsize=12)

    plt.xticks(y_pos, objects)

    ax1.set_ylim(55, 60)  # outliers only
    ax2.set_ylim(0, 6)  # most of the data
    ax1.spines['bottom'].set_visible(False)
    ax2.spines['top'].set_visible(False)
    ax1.xaxis.tick_top()
    ax2.tick_params(labeltop='off')  # don't put tick labels at the top
    ax2.xaxis.tick_bottom()


    d = 0.015  # how big to make the diagonal lines in axes coordinates
    # arguments to pass to plot, just so we don't keep repeating them
    kwargs = dict(transform=ax1.transAxes, color='k', clip_on=False)
    ax1.plot((-d, +d), (-d, +d), **kwargs)        # top-left diagonal
    ax1.plot((1 - d, 1 + d), (-d, +d), **kwargs)  # top-right diagonal

    kwargs.update(transform=ax2.transAxes)  # switch to the bottom axes
    ax2.plot((-d, +d), (1 - d, 1 + d), **kwargs)  # bottom-left diagonal
    ax2.plot((1 - d, 1 + d), (1 - d, 1 + d), **kwargs)  # bottom-right diagonal

    ax1.set_yticks([56, 57, 58, 59, 60])
    ax2.set_yticks([0, 1, 2, 3, 4, 5])

    plt.ylabel('Time for Instrumental response removal\n[sec/channel/day] (BP: 20Hz)', fontweight="bold", fontsize=14.0, family="serif", color="black")
    ax2.yaxis.set_label_coords(-0.07, 1.03)

    plt.setp(ax1.get_yticklabels(), fontsize=12.0, color="black", fontweight="bold", family="serif")
    plt.setp(ax1.get_xticklabels(), fontsize=12.0, color="black", fontweight="bold", family="serif")
    plt.setp(ax2.get_yticklabels(), fontsize=12.0, color="black", fontweight="bold", family="serif")
    plt.setp(ax2.get_xticklabels(), fontsize=12.0, color="black", fontweight="bold", family="serif")

    fig.savefig("../result/TimeforRemoveresponse.png", dpi=300, format='png',
            transparent=False, frameon=False)
    plt.show()

if IfplotFigure3:

    fig = plt.figure(num=None, figsize=(8.0, 8.0), dpi=80)
    ax1 = fig.add_subplot(1, 1, 1)

    respref_o = obspy_respref / chunknum # Unit is now [s / channel / day (20Hz)]
    resp_o = obspy_resp / chunknum
    respref_s = SeisIO_respref / chunknum
    resp_s = SeisIO_resp / chunknum


    remresp_o = resp_o-respref_o
    remresp_s = resp_s-respref_s

    bars1 = [respref_s, remresp_s]
    bars2 = [respref_o, remresp_o]

    barWidth = 0.3
    r1 = np.arange(len(bars1))
    r2 = [x + barWidth for x in r1]
    r3 = [x + barWidth for x in r2]

    ax1.bar(r1, bars1, color = ju_col, width=barWidth, alpha=1.0, edgecolor='k', label=ju_label)
    ax1.bar(r2, bars2, color = py_col, width=barWidth, alpha=1.0, edgecolor='k', label=py_label)

    # Add xticks on the middle of the group bars
    plt.xticks([r + barWidth/2 for r in range(len(bars1))], ['Download', 'Instrumental Response Removal'])


    ax1.legend(loc=2, markerscale=1.0, fontsize=12)


    ax1.set_ylim(0, 15)  # outliers only

    plt.ylabel('Time [sec/channel/day] (BP: 20Hz)', fontweight="bold", fontsize=14.0, family="serif", color="black")

    plt.setp(ax1.get_yticklabels(), fontsize=12.0, color="black", fontweight="bold", family="serif")
    plt.setp(ax1.get_xticklabels(), fontsize=12.0, color="black", fontweight="bold", family="serif")

    #print(bars1)
    #print(bars2)

    print(bars1[1]/bars1[0])
    print(bars2[1]/bars2[0])

    # notation
    th1 = plt.text(1.0, 0.4, "0.137s", fontsize=14.0, rotation=90, rotation_mode='anchor', fontweight="bold")
    th1 = plt.text(1.3, 13.0, "53.56s", fontsize=14.0, rotation=90, rotation_mode='anchor', fontweight="bold")

    fig.savefig("../result/TimeforRemoveresponse_separate.png", dpi=300, format='png',
           transparent=False, frameon=False)
    plt.show()
