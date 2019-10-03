# THIS IS NOT A SHELL SCRIPT. It's a set of example commands.
# NOTE: obtain file 10081701.WVP and copy to the SAC directory if you want the SUDS benchmark

# time
for i in {1..100}; do (sudo chrt -f 99 perf stat -e task-clock -x ',' bash -c 'export SACAUX=/usr/local/sac/aux; /usr/local/sac/bin/sac sac_suds'); done

# memory
sudo chrt -f 99 /usr/bin/time -v bash -c 'export SACAUX=/usr/local/sac/aux; /usr/local/sac/bin/sac sac_suds'

# memory trials; memory use is quasi-static so this isn't strictly necessary
for i in {1..100}; do (sudo chrt -f 99 /usr/bin/time -v bash -c 'export SACAUX=/usr/local/sac/aux; /usr/local/sac/bin/sac sac_suds'); done
