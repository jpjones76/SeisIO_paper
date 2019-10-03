# make request.txt and request.csv for download validation
# using rover, obspy, SeisIO
# 2019.09.30 Kurama Okubo

import datetime

#---------------------------#
# request contents
net = ['TA']
sta = ['109C', '121A', '157A', '158A', '214A',
		'435B', '833A', 'A04D', 'A36M', 'ABTX']
loc = ['--']
cha = ['BH*']

starttime = '2014-03-01T00:00:00'
endtime = '2014-03-17T00:00:00'
foname = 'request_TA'
#---------------------------#

#=== 1. rover and SeisIO===#
fo = open('%s.txt'%foname, 'w')

for n in net:
	for s in sta:
		for l in loc:
			for c in cha:
				req = "%s %s %s %s %s %s" % (n, s, l, c, starttime, endtime)
				fo.write(req+"\n")


fo.close()

#=== 2. obspy ===#
fo = open('%s.csv'%foname, 'w')
fo.write("network,station,channel,latitude,longitude\n")

for n in net:
	for s in sta:
		for l in loc:
			for c in ['BHN', 'BHE', 'BHZ']:
				req = "%s, %s, %s, 0, 0" % (n, s, c)
				fo.write(req+"\n")
