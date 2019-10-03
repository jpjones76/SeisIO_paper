#!/bin/bash
#-----------------------------------#
#script for remove datasets to upload to github
#Kurama Okubo
#-----------------------------------#
sourcedir=./
outdir=../output
#nplist=( 1 2 4 8 10 )
nplist=( 1 2 4 8 )
#------------------------------------#

rootdir=$PWD

# download test

for i in "${nplist[@]}"
do

   dname=$outdir/${i}

   rm $rootdir/$outdir/$i/rover/data/*.h5
   rm $rootdir/$outdir/$i/obspy/RAW_DATA/*.h5
   rm $rootdir/$outdir/$i/obspy/RAW_DATA_rmresp/*.h5
   rm $rootdir/$outdir/$i/obspy/RAW_DATA_rmresp_ref/*.h5
   rm -rf $rootdir/$outdir/$i/SeisIO/seisdownload_tmp

done

echo remove all dataset done.
