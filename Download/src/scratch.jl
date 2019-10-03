stream = open("request_TA.txt", "r")
station = String[]
while eof(stream) != true
tmp = readline(stream, keep=true)
sta = String(split(tmp)[2])
push!(station, sta)
end
close(stream)