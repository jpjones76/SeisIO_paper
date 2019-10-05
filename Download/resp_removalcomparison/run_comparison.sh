##### These are shell commands: Please configure them
conda activate obspy

srun -p shared -n 1 -t 1:00:00 --mem=4000 -o out_obspy_resp.dat -e err_obspy_resp.dat python test-ReadandRemoval_Obspy_TA.py
srun -p shared -n 1 -t 1:00:00 --mem=4000 -o out_obspy_resp.dat -e err_obspy_resp.dat /n/home03/kokubo/packages/julia-1.2.0/bin/julia test-ReadandRemoval_TA.jl

echo all process has been done.
