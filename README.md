# SeisIO_paper
Downloadable benchmark tests and raw results from Jones et al., SeisIO: a fast, efficient geophysical data architecture for the Julia language, submitted to SRL.

# How to Run Benchmarks
1. (Optional) Get restricted files; see "Data Sources and Availability".
2. **SAC**:
   + Install SAC 101.6a from source
   + Follow example template and instructions in `SAC/sac_shell.sh`
   + Dump screen output to file
   + Parse file with grep -v to generate log files `SAC.read_sac.log`, `SAC.read_suds.log`
   + If carefully checking memory, repeat the process with `time -v` and
     overwrite values in `run_sac_stats.jl` with the medians
3. **ObsPy**:
   + (Ubuntu) ensure pip is installed: `sudo apt install pip`
   + Modify the value of `SeisIO_path` in `Python/ObsPy_bench1.py` if you
     need to run the "restricted" benchmarks.
   + Install ObsPy [following these instructions](https://github.com/obspy/obspy/wiki/Installation-via-Anaconda)
     - Be sure to create and activate an ObsPy environment
   + From the bash shell: `conda install pytest memory_profiler pyasdf`
   + Change directory to `Python/`.
   + Start python3.
   + At the prompt: `exec(open("ObsPy_bench1.py").read())`
4. **SeisIO**
   + Do either of these:
      - Ensure that you have a command-line svn client installed (Ubuntu 18.04: sudo apt install subversion)
      - Download benchmark test data from https://github.com/jpjones76/SeisIO-TestData/tree/master/Benchmarks
   + Start Julia in the root directory of this project.
   + At the Julia prompt:

```
include("configure.jl")             # configure Julia portion of project
include("benchmark_file_reads.jl")  # run SeisIO benchmarks
include("benchmark_hist.jl")        # generate plots for your own benchmarks
```
