using DelimitedFiles, Printf, Statistics
ovh = median(readdlm("SAC/SAC.q.log", ',')[:,1]) # overhead; time to start/exit SAC
t_sac = median(readdlm("SAC/SAC.read_sac.log", ',')[:,1])
t_suds = median(readdlm("SAC/SAC.read_suds.log", ',')[:,1])

# Memory -- median values
# SUDS file test: 11132 K
# SAC file test: 73140 K
# start and quit SAC: 5540 K
mem_sac = 73140/1024
mem_suds = 11132/1024
mem_q = 5540/1024

@printf("%13s %30s %9s %9s\n", "Format", "Filename", "Mem_[MB]", "T_[ms]")
@printf("%13s %30s %9.2f %9.2f\n", "SAC", "1day-100hz.sac", mem_sac-mem_q, t_sac-ovh)
@printf("%13s %30s %9.2f %9.2f\n", "SUDS", "10081701.WVP", mem_suds-mem_q, t_suds-ovh)

# From Jones' run:
#
# Format                       Filename  Mem_[MB]    T_[ms]
#    SAC                 1day-100hz.sac     66.02    113.58
#   SUDS                   10081701.WVP      5.46     15.35

out = open("SAC/benchmarks_sac.csv", "w")
write(out, "Format;Filename;Mem_[MB];T_[ms]\n")
@printf(out, "%s;%s;%0.2f;%0.2f\n", "SAC", "1day-100hz.sac", mem_sac-mem_q, t_sac-ovh)
@printf(out, "%s;%s;%0.2f;%0.2f\n", "SUDS", "10081701.WVP", mem_suds-mem_q, t_suds-ovh)
close(out)
