#!/bin/bash

sleepvalue=$1

# Start time
start_time=$(date +%s)

rm -rf processedProducts
rm -rf records

# Commands or Script Logic
echo "Script is running..."

echo "Combi Script Running...."
source combiMismatch.sh
echo "Combi Script Ended"

sleep $sleepvalue

echo "Fecth Account Level-Reseller Matrix Running..."
source FetchAccountLevel-ResellerMatrix.sh
echo "Fecth Account Level-Reseller Matrix Ended"

sleep $sleepvalue

echo "FetchAccountLevelCommission-Matrix-standalone-Account running..."
source FetchAccountLevelCommission-Matrix-standalone-Account.sh
echo "FetchAccountLevelCommission-Matrix-standalone-Account ended"

sleep $sleepvalue

echo "FetchAccountLevelCommission-Matrix-WithoutCommissionOverlap Running..."
source FetchAccountLevelCommission-Matrix-WithoutCommissionOverlap.sh
echo "FetchAccountLevelCommission-Matrix-WithoutCommissionOverlap Ended"

sleep $sleepvalue

echo "FetchCatalogLevel-ResellerMatrix Running...."
source FetchCatalogLevel-ResellerMatrix.sh
echo "FetchCatalogLevel-ResellerMatrix Ended"

echo "FetchCatalogLevelCommission-Matrix.sh Running..."
source FetchCatalogLevelCommission-Matrix.sh
echo "FetchCatalogLevelCommission-Matrix.sh Ended..."

sleep $sleepvalue

echo "FetchDefaultLevel-ResellerMatrix-MissingEntries Running...."
source FetchDefaultLevel-ResellerMatrix-MissingEntries.sh
echo "FetchDefaultLevel-ResellerMatrix-MissingEntries Ended"

sleep $sleepvalue

echo "FetchDefaultLevel-ResellerMatrix Running..."
source FetchDefaultLevel-ResellerMatrix.sh
echo "FetchDefaultLevel-ResellerMatrix Ended"

sleep $sleepvalue

echo "FetchStandalone-Matrix-MissingEntries Running..."
source FetchStandalone-Matrix-MissingEntries.sh
echo "FetchStandalone-Matrix-MissingEntries Ended"

sleep $sleepvalue

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

