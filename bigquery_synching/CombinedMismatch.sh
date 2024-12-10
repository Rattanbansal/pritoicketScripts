#!/bin/bash


pushd ./FullTABLECLC > /dev/null
/bin/bash finalFullTableCLC.sh 2 10 PROD
popd > /dev/null

sleep 5

pushd ./FULLTABLETLC > /dev/null
/bin/bash finalFullTableTLC.sh 2 10 PROD
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
/bin/bash finalFullTableOAC.sh 2 PROD
popd > /dev/null

sleep 5

pushd ./FullTABLEQRCodes > /dev/null
/bin/bash finalFullTableQRCodes.sh 2 PROD
popd > /dev/null

sleep 5

pushd ./FullTABLEReseller > /dev/null
/bin/bash finalFullTablereseller.sh 2 PROD
popd > /dev/null

sleep 5

pushd ./FullTABLETLT > /dev/null
/bin/bash finalFullTableTLT.sh 2 PROD
popd > /dev/null


sleep 5

pushd ./FullTABLETPS > /dev/null
/bin/bash finalFullTableTPS.sh 2 PROD
popd > /dev/null