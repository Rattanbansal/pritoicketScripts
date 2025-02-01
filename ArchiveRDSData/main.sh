#!/bin/bash

./archiveRDSBigquery.sh "$@"  # Run your existing script

if [ $? -eq 0 ]; then
    # Success sound
    echo "Successfully executed script"
    mpg123 sucess.mp3
    curl -d "✅ Script Completed Successfully!" ntfy.sh/ARDSD
else
    # Error sound
    echo "Error In Script"
    aplay error.wav
    curl -d "❌ Script Failed!" ntfy.sh/ARDSD
fi