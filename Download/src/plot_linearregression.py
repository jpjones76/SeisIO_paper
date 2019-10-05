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
#rover_TA = [1.1*60*60, 30.8*60, 16.2*60, 8*60] #(nw, time) = (10, 16.0*60)
#obspy_TA = [2176.23, 2001.66629148, 1797.66759729, 968.61585855] #(nw, time) = (10, 739.71695280)
rover_TA = [34.7*60, 18.5*60, 7.2*60, 4.1*60] #(nw, time) = (10, 16.0*60)
obspy_TA = [2176.22648287, 1093.44593859, 578.86283278, 283.33756423] #(nw, time) = (10, 739.71695280)
SeisIO_TA = [1742.08816409, 916.23014092, 436.72494221, 264.05373502] #(nw, time) = (10, 423.23682714)
# 2. BP
dsize_BP = 17627.4236 #[MB]
obspy_BP = [10224.24507380, 5283.88453650, 2541.56301594, 1350.99040246, 703.44365788, 441.18909049]
SeisIO_BP = [3974.19804406, 1242.65623403, 698.06878400, 373.56645608, 187.04703999, 132.37026000]
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
    ax1.scatter(NW_TA, y_o_TA, marker="s", s=markersize_o, zorder=11, clip_on=False, c=py_col, edgecolors='k', label=py_label)
    ax1.scatter(NW_TA, y_r_TA, marker="v", s=markersize_r, zorder=12, clip_on=False, c=rover_col, edgecolors='k', label=rover_label)

    # polyfit
    m_r,b_r = np.polyfit(np.log10(NW_TA), np.log10(y_r_TA), 1)
    m_o,b_o = np.polyfit(np.log10(NW_TA), np.log10(y_o_TA), 1)
    m_s,b_s = np.polyfit(np.log10(NW_TA), np.log10(y_s_TA), 1)

    f = open("exponentialscale_TA.txt", "w")
    f.write("rover %8.4f\n"%m_r)
    f.write("obspy %8.4f\n"%m_o)
    f.write("SeisIO %8.4f\n"%m_s)
    f.close()

    print([m_r,b_r])
    print([m_o,b_o])
    print([m_s,b_s])
    fit_fn_r = np.poly1d(np.polyfit(np.log10(NW_TA), np.log10(y_r_TA), 1))
    fit_fn_o = np.poly1d(np.polyfit(np.log10(NW_TA), np.log10(y_o_TA), 1))
    fit_fn_s = np.poly1d(np.polyfit(np.log10(NW_TA), np.log10(y_s_TA), 1))

    # fit_fn is now a function which takes in x and returns an estimate for y
    plt.plot(NW_TA, [10.0**fit_fn_r(x) for x in np.log10(NW_TA)], '--', color=rover_col)
    plt.plot(NW_TA, [10.0**fit_fn_o(x) for x in np.log10(NW_TA)], '--', color=py_col)
    plt.plot(NW_TA, [10.0**fit_fn_s(x) for x in np.log10(NW_TA)], '--', color=ju_col)

    plt.xlim(0, 5)
    plt.ylim(0, 12)

    plt.xlabel('Number of Workers', fontweight="bold", fontsize=16.0, family="serif", color="black")
    plt.ylabel('Download Efficiency [MB/s]', fontweight="bold", fontsize=16.0, family="serif", color="black")
    ax1.set_title('TA: IRISDMC', fontsize=16, color="black", fontweight="bold", family="serif")

    plt.xlim(1, 8)
    plt.ylim(1, 40)
    ax1.legend(loc=2, markerscale=1.0, fontsize=14)

    plt.setp(plt.gca().get_yticklabels(), fontsize=14.0, color="black", fontweight="bold", family="serif")
    plt.setp(plt.gca().get_xticklabels(), fontsize=14.0, color="black", fontweight="bold", family="serif")

    for tic in ax1.xaxis.get_minor_ticks():
        tic.tick1On = tic.tick2On = False
        tic.label1On = tic.label2On = False



    # figure notation
    ax1.text(0.04, 0.92, '(a)', fontsize=18, fontweight="bold", transform=plt.gcf().transFigure)

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
    ax2.scatter(NW_BP, y_o_BP, marker="s", s=markersize_o, zorder=9, clip_on=False, c=py_col, edgecolors='k', label=py_label)

    # polyfit
    mb_o,bb_o = np.polyfit(np.log10(NW_BP), np.log10(y_o_BP), 1)
    mb_s,bb_s = np.polyfit(np.log10(NW_BP), np.log10(y_s_BP), 1)

    f = open("exponentialscale_BP.txt", "w")
    f.write("obspy %8.4f\n"%mb_o)
    f.write("SeisIO %8.4f\n"%mb_s)
    f.close()

    print([mb_o,bb_o])
    print([mb_s,bb_s])
    fit_fn_bo = np.poly1d(np.polyfit(np.log10(NW_BP), np.log10(y_o_BP), 1))
    fit_fn_bs = np.poly1d(np.polyfit(np.log10(NW_BP), np.log10(y_s_BP), 1))

    # fit_fn is now a function which takes in x and returns an estimate for y
    plt.plot(NW_BP, [10.0**fit_fn_bo(x) for x in np.log10(NW_BP)], '--', color=py_col)
    plt.plot(NW_BP, [10.0**fit_fn_bs(x) for x in np.log10(NW_BP)], '--', color=ju_col)

    plt.xlabel('Number of Workers', fontweight="bold", fontsize=16.0, family="serif", color="black")
    plt.ylabel('Download Efficiency [MB/s]', fontweight="bold", fontsize=16.0, family="serif", color="black")
    ax2.set_title('BP: NCEDC', fontsize=16, color="black", fontweight="bold", family="serif")

    plt.xlim(1, 32)
    plt.ylim(1, 200)
    ax2.legend(loc=2, markerscale=1.0, fontsize=14.0)

    plt.setp(plt.gca().get_yticklabels(), fontsize=14.0, color="black", fontweight="bold", family="serif")
    plt.setp(plt.gca().get_xticklabels(), fontsize=14.0, color="black", fontweight="bold", family="serif")

    for tic in ax2.xaxis.get_minor_ticks():
        tic.tick1On = tic.tick2On = False
        tic.label1On = tic.label2On = False


    ax2.text(0.545, 0.92, '(b)', fontsize=18, fontweight="bold", transform=plt.gcf().transFigure)

    fig.savefig("../result/DownloadEfficiency_withexpscale.png", dpi=300, format='png',
            transparent=False, frameon=False)
    plt.show()
