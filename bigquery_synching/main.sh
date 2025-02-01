#!/bin/bash

./CombinedMismatch.sh "$@"  # Run your existing script

if [ $? -eq 0 ]; then
    # Success sound
    echo "Successfully executed script"
    aplay ../SCANTBSCANNINGISSUE/success.wav
    curl -d "✅ Script Completed Successfully!" ntfy.sh/BIGSINK
else
    # Error sound
    echo "Error In Script"
    aplay ../SCANTBSCANNINGISSUE/error.wav
    curl -d "❌ Script Failed!" ntfy.sh/BIGSINK
fi