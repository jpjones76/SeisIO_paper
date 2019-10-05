#!/bin/bash
#-----------------------------------#
#script for obspy (with NoisePy) download test
#Kurama Okubo
#-----------------------------------#
sourcedir=./
outdir=../output
#nplist_TA=( 1 2 4 8 10 )
nplist_BP=( 2 4 8 16 32 )
#nplist=( 2 )
#------------------------------------#
mkdir $outdir
rootdir=$PWD

# download test

#for i in "${nplist_TA[@]}"
#do

#   dname=$outdir/${i}
#   mkdir $dname
#   mkdir $dname/obspy
#
#   #mpirun Noisepy (output directory is specified by np as args)
#   echo run with np=$i
#   mpirun -np $i python $rootdir/download_exec/S0_dowload_ASDF_MPI_TA.py $i

   #sleep to properly exit all mpi processors
#   sleep 20
#   cd $rootdir
#done

for i in "${nplist_BP[@]}"
do

   dname=$outdir/${i}
   mkdir $dname
   mkdir $dname/obspy

   #mpirun Noisepy (output directory is specified by np as args)
   echo run with np=$i
   mpirun -np $i python $rootdir/download_exec/S0_dowload_ASDF_MPI_BP.py $i

   #sleep to properly exit all mpi processors
   sleep 20
   cd $rootdir
done

# remove response test
# for i in 1
# do
#    #dname = output directory year by year
#    dname=$outdir/${i}
#    mkdir $dname
#    mkdir $dname/obspy
#
#    #mpirun Noisepy (output directory is specified by np as args)
#    echo run remove resp with np=$i
#    mpirun -np $i python $rootdir/resp_reference/S0_dowload_ASDF_MPI_BP_removeresp_ref.py $i
#
#    sleep 10
#
#    mpirun -np $i python $rootdir/resp_removal/S0_dowload_ASDF_MPI_BP_removeresp.py $i
#
#    cd $rootdir
# done
