from obspy.clients.fdsn import Client
from obspy import UTCDateTime

client = Client("IRIS")

# save waveform
t = UTCDateTime("2018-03-01T00:00:00.000")
st = client.get_waveforms("TA", "121A", "--", "HHZ", t, t+86400)
st.write("TA.121A.--.HHZ.mseed", format="MSEED")

# save inventory
inventory = client.get_stations(starttime=t, endtime=t+86400, network="TA", sta="121A", loc="--", channel="HHZ", level="response")
inventory.write("TA.121A.xml", format="stationxml")

#st.plot()
