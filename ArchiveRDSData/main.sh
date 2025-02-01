#!/bin/bash

./archiveRDSBigquery.sh "$@"  # Run your existing script

if [ $? -eq 0 ]; then
    # Success sound
    echo "Successfully executed script"
    mpg123 sucess.wav
else
    # Error sound
    echo "Error In Script"
    aplay error.wav
fi