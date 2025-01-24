#!/bin/bash

# Start time
start_time=$(date +%s)

# Commands or Script Logic
echo "Script is running..."

pushd ./FullTABLECLC > /dev/null
/bin/bash finalFullTableCLC.sh 2 15 PROD
popd > /dev/null

sleep 5

pushd ./FULLTABLETLC > /dev/null
/bin/bash finalFullTableTLC.sh 2 15 PROD
popd > /dev/null

sleep 5

pushd ./FullTABLECTD > /dev/null
/bin/bash finalFullTableCTD.sh 2 PROD
popd > /dev/null

sleep 5

pushd ./FullTABLEDestination > /dev/null
/bin/bash finalFullTableDestination.sh 2 PROD
popd > /dev/null

sleep 5

pushd ./FullTABLEMEC > /dev/null
/bin/bash finalFullTableMEC.sh 2 PROD
popd > /dev/null

sleep 5

pushd ./FullTABLEOAC > /dev/null
/bin/bash finalFullTableOAC.sh 2 15 PROD
popd > /dev/null

sleep 5

pushd ./FullTABLEQRCodes > /dev/null
/bin/bash finalFullTableQRCodes.sh 2 PROD
popd > /dev/null

sleep 5

pushd ./FullTABLEReseller > /dev/null
/bin/bash finalFullTableReseller.sh 2 PROD
popd > /dev/null

sleep 5

pushd ./FullTABLETLT > /dev/null
/bin/bash finalFullTableTLT.sh 2 PROD
popd > /dev/null


sleep 5

pushd ./FullTABLETPS > /dev/null
/bin/bash finalFullTableTPS.sh 2 PROD
popd > /dev/null

# End time
end_time=$(date +%s)

# Calculate elapsed time in seconds
execution_time=$((end_time - start_time))

# Calculate hours, minutes, and seconds
hours=$((execution_time / 3600))
minutes=$(( (execution_time % 3600) / 60 ))
seconds=$((execution_time % 60))

# Display execution time in HH:MM:SS
printf "Total Execution Time: %02d hours, %02d minutes, %02d seconds\n" $hours $minutes $seconds

