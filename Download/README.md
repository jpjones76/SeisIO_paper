# Download Benchmarks
#### September 30 2019 Kurama Okubo

## Software
1. [__ROVER__](https://iris-edu.github.io/rover/) a command line tool to robustly retrieve geophysical timeseries data from data centers such as IRIS DMC
2. [__Obspy__](https://github.com/obspy/obspy/wiki) an open-source project dedicated to provide a Python framework for processing seismological data.
In this project, we used [__NoisePy__](https://github.com/chengxinjiang/Noise_python), a Python package designed for fast and easy computation of ambient noise cross-correlation functions.    
3. [__SeisIO__](http://seisio.readthedocs.org) Julia-based collection of utilities for reading, downloading, and processing geophysical timeseries data.

## Version info
1. __ROVER__ 1.0.4 installed from [https://iris-edu.github.io/rover](https://iris-edu.github.io/rover/)
2. __Obspy__ 1.1.1 installed from [https://github.com/obspy/obspy/wiki/Installation-via-Anaconda](https://github.com/obspy/obspy/wiki/Installation-via-Anaconda)
3. __SeisIO__ v0.4.0 uses the latest commit from the master branch:
```
> commit 97bec05262f71ec965c8d685cf464def3345d367
Author: Joshua Jones <jpjones76@users.noreply.github.com>
Date:   Sun Sep 29 02:16:47 2019 -0700
fix for Julia 1.2.0 Pkg("update") breaking MbedTLS dependency
```

## CPU info
We use the [Harvard RC cluster](https://www.rc.fas.harvard.edu/cluster/) in this benchmark test:

- Architecture:          x86_64
- CPU(s):                32
- Model name: Intel(R) Xeon(R) Platinum 8268 CPU @ 2.90 GHz
- RAM: 64GB


## Dataset
1. 10 stations in network TA from [IRIS DMC](https://ds.iris.edu/ds/nodes/dmc/):


|net|sta|cha|
|---|---|---|
| TA | 109C  | BH* (40 Hz)|
| TA | 121A  | BH* |
| TA | 157A | BH* |
| TA | 158A | BH* |
| TA | 214A  | BH* |
| TA | 435B  | BH* |
| TA | 833A  | BH* |
| TA | A04D  | BH* |
| TA | A36M  | BH* |
| TA | ABTX  | BH* |

- Start time = 2014-03-01T00:00:00
- End time = 2014-03-17T00:00:00

2. 10 stations in network BP from [NCEDC](https://ncedc.org):


|net|sta|cha|
|---|---|---|
| BP | SMNB  | BP* (20 Hz)|
| BP | EADB  | BP* |
| BP | FROB | BP* |
| BP | GHIB | BP* |
| BP | JCNB  | BP* |
| BP | JCSB  | BP* |
| BP | LCCB  | BP* |
| BP | MMNB  | BP* |
| BP | RMNB  | BP* |
| BP | SCYB  | BP* |

- Start time = 2006-03-01T00:00:00
- End time = 2006-04-01T00:00:00


## Workflow
1. Download data from IRISDMC and save to ASDF format (rover and obspy) or SeisData binary (SeisIO) with number of workers =  1, 2, 4, 8, 10
2. Download data from NCEDC and save to ASDF format (obspy) or SeisData binary (SeisIO) with number of workers =  1, 2, 4, 8, 16, 32
3. Download data from NCEDC with removing instrumental response (obspy and SeisIO)

## Reproducing the Results
* Install Obspy, Rover, and SeisIO.
* Function and module of NoisePy are already located in `src`. You do not have to install the entire package.
* Install [SeisDownload](https://github.com/kura-okubo/SeisDownload.jl):
  + In Julia, `]dev https://github.com/kura-okubo/SeisDownload.jl`
  + In a Linux shell, `cd (juliaroot)/dev/SeisDownload && git pull && git checkout SeisIO_DLTest`
* Run with cpus > 32 using these shell commands:

```console
cd SeisIO_Validation/src
#Prepare request
python make_request_TA.py
python make_request_BP.py
#run all downloading processes
sh run_rover.sh
sh run_obspy.sh
sh run_SeisIO.sh

#Or submit job in cluster
#sbatch runall_slurm

#remove datasets as the total size of output is huge
#this command does not remove texts for computational time
sh remove_datasets.sh
```

## Results
See manuscript
