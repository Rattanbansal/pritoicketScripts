#!/bin/bash

./CombinedMismatch.sh "$@"  # Run your existing script

if [ $? -eq 0 ]; then
    # Success sound
    echo "Successfully executed script"
    aplay ../SCANTBSCANNINGISSUE/success.wav
else
    # Error sound
    echo "Error In Script"
    aplay ../SCANTBSCANNINGISSUE/error.wav
fi