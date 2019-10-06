# SeisIO_paper
Downloadable benchmark tests and raw results from Jones et al., SeisIO: a fast, efficient geophysical data architecture for the Julia language, submitted to SRL.

# How to Run Benchmarks
0. Install Julia ≥1.1 and Python ≥3.6. We used Julia v1.1.0 and Python v3.6.8
in the manuscript.
1. (Optional) Get restricted files; see "Data and Resources" section in paper.
   + Start Julia and run these commands: `using Pkg; Pkg.add("SeisIO"); using SeisIO; SeisIO_root = dirname(pathof(SeisIO))`. Save that location for the next step.
   + Place the restricted files in `SeisIO_root/../test/SampleFiles/Restricted/`.
2. **SAC**:
   + Install SAC 101.6a from source
   + Follow example template and instructions in `SAC/sac_shell.sh`
   + These runs produce screen output; dump or redirect to a temporary file
   + Parse the temp file with grep -v to generate log files `SAC.read_sac.log`, `SAC.read_suds.log`
   + If carefully checking memory, repeat the process with `time -v` and
     overwrite values in `run_sac_stats.jl` with the medians
3. **ObsPy**:
   + (Ubuntu 18.04) ensure pip is installed: `sudo apt install pip`
   + Modify the value of `SeisIO_path` in `Python/ObsPy_bench1.py` if you
     need to run the "restricted" benchmarks.
   + Install ObsPy [following these instructions](https://github.com/obspy/obspy/wiki/Installation-via-Anaconda)
     - Be sure to create and activate an ObsPy environment
   + From the bash shell: `conda install pytest memory_profiler pyasdf`
   + Change directory to `Python/`.
   + Start python3.
   + At the prompt: `exec(open("ObsPy_bench1.py").read())`
4. **SeisIO**
   + Start Julia in the root directory of this project.
   + At the Julia prompt:

```
include("configure.jl")             # configure Julia portion of project
include("benchmark_file_reads.jl")  # run SeisIO benchmarks
include("benchmark_hist.jl")        # generate plots for your own benchmarks
```
