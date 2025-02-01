#!/bin/bash

./getDataFromBigQuery.sh "$@"  # Run your existing script

if [ $? -eq 0 ]; then
    # Success sound
    echo "Successfully executed script"
    aplay success.wav
    curl -d "✅ Script Completed Successfully!" ntfy.sh/scanTbReport
else
    # Error sound
    echo "Error In Script"
    aplay error.wav
    curl -d "❌ Script Failed!" ntfy.sh/scanTbReport
fi