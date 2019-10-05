#!/bin/bash
#-----------------------------------#
#script for SeisIO (with SeisDownload [https://github.com/kura-okubo/SeisDownload.jl])
#Kurama Okubo
#-----------------------------------#
sourcedir=./
outdir=../output
nplist_TA=( 1 2 4 8 10 )
nplist_BP=( 1 2 4 8 16 32 )

#nplist_TA=( 4 )
#nplist_BP=( 4 )
#------------------------------------#
mkdir $outdir
rootdir=$PWD

# download test

for i in "${nplist_TA[@]}"
do

   dname=$outdir/${i}
   mkdir $dname
   mkdir $dname/SeisIO
   mkdir $dname/SeisIO/mseed

   #mpirun Noisepy (output directory is specified by np as args)
   echo run with np=$i
   #/Applications/Julia-1.2.app/Contents/Resources/julia/bin/julia  -p $i $rootdir/download_exec/seisdownload_TA.jl $i
   /n/home03/kokubo/packages/julia-1.2.0/bin/julia -p $i $rootdir/download_exec/seisdownload_TA.jl $i

   mv *.mseed $dname/SeisIO/mseed/
   sleep 20

   cd $rootdir
done


for i in "${nplist_BP[@]}"
do

   dname=$outdir/${i}
   mkdir $dname
   mkdir $dname/SeisIO

   #mpirun Noisepy (output directory is specified by np as args)
   echo run with np=$i
   #/Applications/Julia-1.2.app/Contents/Resources/julia/bin/julia  -p $i $rootdir/download_exec/seisdownload_BP.jl $i
   /n/home03/kokubo/packages/julia-1.2.0/bin/julia -p $i $rootdir/download_exec/seisdownload_BP.jl $i

   mv *.mseed $dname/SeisIO/mseed/
   sleep 20

   cd $rootdir
done

# # remove response test
#
# for i in 1
# do
#    #dname = output directory year by year
#    dname=$outdir/${i}
#    mkdir $dname
#    mkdir $dname/SeisIO
#
#    #mpirun Noisepy (output directory is specified by np as args)
#    echo response removal test run with np=$i
#    /n/home03/kokubo/packages/julia-1.2.0/bin/julia  -p $i $rootdir/resp_reference/seisdownload_BP_removeresp_ref.jl $i
#
#    sleep 10
#
#    /n/home03/kokubo/packages/julia-1.2.0/bin/julia  -p $i $rootdir/resp_removal/seisdownload_BP_removeresp.jl $i
#
#    cd $rootdir
# done
