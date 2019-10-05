#!/bin/bash
#-----------------------------------#
#script for rover download test
#Kurama Okubo
#-----------------------------------#
sourcedir=./
outdir=../output
requesttxt=request_TA.txt
#nplist=( 1 2 4 8 10 )
nplist=( 4 8 )
#------------------------------------#
mkdir $outdir
rootdir=$PWD

for i in "${nplist[@]}"
do

   dname=$outdir/${i}
   mkdir $dname
   rm -r $dname/rover
   mkdir $dname/rover
   #move to working directory
   cd $dname/rover
   #init rover repository
   rover init-repository
   #manipulate download-workers
   newworkers=s/download-workers=5/download-workers=$i/g
   #output in mseed
   #outputformat=s/output-format=mseed/output-format=asdf/g
   sed -i ${newworkers} rover.config
   #sed -i ${outputformat} rover.config
   #start downloading data
   rover retrieve $rootdir/$requesttxt

   sleep 20

   cd $rootdir
done
