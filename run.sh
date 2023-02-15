#!/bin/bash

# Caveats:
# - This script will exit when CRASH_LIMIT has been reached

# how frequently (in seconds) do we run a check
# INTERVAL=2
[[ -z ${INTERVAL} ]] && echo "Error: INTERVAL not set. Exiting..." && exit 1

# number of checks to run. if set to value greater than 0, DURATION is ignored
# COUNT=0
[[ -z ${COUNT} ]] && COUNT=0

# set max duration to hold script to a specific duration is COUNT is used
[[ ${COUNT} -gt 0 && -z ${MAX_DURATION} ]] && echo "Error: COUNT is set but MAX_DURATION is not. Exiting..." && exit 1

# how long (in seconds) does the job run?
# DURATION=10
[[ -z ${DURATION} && ${COUNT} -eq 0 ]] && echo "Error: DURATION not set. Exiting..." && exit 1

# how many crashes can we tolerate?
# CRASH_LIMIT=3
[[ -z ${CRASH_LIMIT} ]] && echo "Error: CRASH_LIMIT not set. Exiting..." && exit 1

# pod hash to test
[[ -z ${HASH} ]] && echo "Error: HASH not set. Exiting..." && exit 1

# set to an integer greater than or equal to 1 to enable
[[ -z ${DEBUG} ]] && DEBUG=0

# temp file to capture response
TMP_FILE="/tmp/tmp.$$.1.txt"

# need these to maintain state
START_TIME=$(date +'%s')

if [[ $COUNT -gt 0 ]]; then
    [[ ${DEBUG} -ge 1 ]] && echo "Info: Making ${COUNT} observations."

    for((i=0; $i < $COUNT; i++)); do
        CURRENT_TIME=$(date +'%s')
        TIME_ELAPSED=$((CURRENT_TIME - START_TIME))

        # break if we've run to max duration
        if [[ ${TIME_ELAPSED} -ge ${MAX_DURATION} ]]; then
            [[ ${DEBUG} -ge 1 ]] && echo -e "Info: Execution time has reached max duration of ${MAX_DURATION} seconds\n\nExiting..."
            break
        fi

        kubectl get po --selector=rollouts-pod-template-hash=${HASH} -o json | jq '.items[].status.containerStatuses[].restartCount' > ${TMP_FILE}

        TOTAL_CRASHES=0

        while read CRASHES; do
            TOTAL_CRASHES=$((TOTAL_CRASHES + CRASHES))
        done < <(cat ${TMP_FILE})

        # NUM_PODS=$(kubectl get po --selector=rollouts-pod-template-hash=${HASH} -o json | jq -rM '.items | length')

        if [[ ${TOTAL_CRASHES} -ge ${CRASH_LIMIT} ]]; then
            [[ ${DEBUG} -ge 1 ]] && echo -e "Error: Observed ${CRASH_LIMIT} crashes\n\nExiting..."
            echo "{ \"Crashes\": ${TOTAL_CRASHES} }"
            exit 1
        fi

        [[ ${DEBUG} -ge 1 ]] && echo "Info: Crashes (${TOTAL_CRASHES})"

        sleep $INTERVAL
    done

    echo "{ \"Crashes\": ${TOTAL_CRASHES} }"
    exit 0
else
    [[ $((DURATION % INTERVAL)) -ne 0 ]] && echo "Error: DURATION must be evenly divisible by INTERVAL" && exit 1

    OBSERVATIONS=$((${DURATION} / ${INTERVAL}))
    [[ ${DEBUG} -ge 1 ]] && echo "Info: Running for ${DURATION} seconds making ${OBSERVATIONS} observations"

    while true; do
        CURRENT_TIME=$(date +'%s')
        TIME_ELAPSED=$((CURRENT_TIME - START_TIME))

        # break if we've run to full duration
        if [[ ${TIME_ELAPSED} -ge ${DURATION} ]]; then
            [[ ${DEBUG} -ge 1 ]] && echo -e "Info: Execution time has reached ${DURATION} seconds\n\nExiting..."
            break
        fi

        kubectl get po --selector=rollouts-pod-template-hash=${HASH} -o json | jq '.items[].status.containerStatuses[].restartCount' > ${TMP_FILE}

        TOTAL_CRASHES=0

        while read CRASHES; do
            TOTAL_CRASHES=$((TOTAL_CRASHES + CRASHES))
        done < <(cat ${TMP_FILE})

        # NUM_PODS=$(kubectl get po --selector=rollouts-pod-template-hash=${HASH} -o json | jq -rM '.items | length

        if [[ ${TOTAL_CRASHES} -ge ${CRASH_LIMIT} ]]; then
            [[ ${DEBUG} -ge 1 ]] && echo -e "Error: Observed ${CRASH_LIMIT} crashes\n\nExiting..."
            echo "{ \"Crashes\": ${TOTAL_CRASHES} }"
            exit 1
        fi

        [[ ${DEBUG} -ge 1 ]] && echo "Info: Crashes (${TOTAL_CRASHES})"

        sleep $INTERVAL
    done

    echo "{ \"Crashes\": ${TOTAL_CRASHES} }"
    exit 0
fi
