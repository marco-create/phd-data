#!/bin/bash

participantdir=$1

echo "Run participants with masked stimulus"

participant=$(basename $participantdir)

date=$(date)

echo "Processing participant: $participant"

cd $participantdir

cd NORMALVISION

matlab -nodisplay -nosplash -singleCompThread -batch "addpath(genpath('/home/marco/pRF_server_analyses/'));mountParamsRunPrf;exit;"

echo "Finished pRF on $participant at $date" > PRF_.log

exit
