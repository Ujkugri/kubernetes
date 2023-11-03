#!/bin/bash
#
# Get Total storage allocation of customer PVCs in Gi usage
# Ignores any returned PVCs that are in the Mi range, thus it is slightly inaccurate but ok.

kubectl get pvc --no-headers -A -l 'de.clara.net/storage!=claranet' | awk '/Gi/{ gsub(/Gi/, "", $5); s+=$5 } END { print s }'
