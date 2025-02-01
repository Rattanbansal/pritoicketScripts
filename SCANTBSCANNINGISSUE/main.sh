#!/bin/bash

./getDataFromBigQuery.sh "$@"  # Run your existing script

if [ $? -eq 0 ]; then
    # Success sound
    echo "Successfully executed script"
    aplay success.wav
else
    # Error sound
    echo "Error In Script"
    aplay error.wav
fi