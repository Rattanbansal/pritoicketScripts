#!/bin/bash

# Start time
start_time=$(date +%s)

# Commands or Script Logic
echo "Script is running..."

source combiMismatch.sh

source FetchAccountLevel-ResellerMatrix.sh

source FetchAccountLevelCommission-Matrix-standalone-Account.sh

source FetchAccountLevelCommission-Matrix-WithoutCommissionOverlap.sh

source FetchCatalogLevel-ResellerMatrix.sh

source FetchCatalogLevelCommission-Matrix.sh

source FetchDefaultLevel-ResellerMatrix-MissingEntries.sh

source FetchDefaultLevel-ResellerMatrix.sh

source FetchStandalone-Matrix-MissingEntries.sh


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

