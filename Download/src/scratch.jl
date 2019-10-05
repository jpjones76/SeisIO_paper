stream = open("request_TA.txt", "r")
station = String[]
while eof(stream) != true
tmp = readline(stream, keep=true)
sta = String(split(tmp)[2])
push!(station, sta)
end
close(stream)



S = get_data("FDSN", "NC.BAP..EHZ", s="2003-01-02T23:55:00", t=3600, v=3, w=true, src="NCEDC", xf="NC.BAP..EHZ.1.xml", unscale=true, demean=true, detrend=false, taper=true, ungap=false, rr=false)
