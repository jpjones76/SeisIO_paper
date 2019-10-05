# make request.txt and request.csv for download validation
# using rover, obspy, SeisIO
# 2019.09.30 Kurama Okubo

import datetime

#---------------------------#
# request contents
net = ['BP']
sta = ['SMNB', 'EADB', 'FROB', 'GHIB', 'JCNB',
		'JCSB', 'LCCB', 'MMNB', 'RMNB', 'SCYB']
loc = ['--']
cha = ['BP*']

starttime = '2006-03-01T00:00:00'
endtime = '2006-06-01T00:00:00'
foname = 'request_BP'
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
			for c in ['BP1', 'BP2', 'BP3']:
				req = "%s, %s, %s, 0, 0" % (n, s, c)
				fo.write(req+"\n")
