#!/bin/bash
#
# Evaluate extracted fingerprints on database and calculate statistics
# 02/22/2021
#

if [ $# -lt 2 ]
then
    echo "Invalid arguments. Usage: evalTlsFingerprints.sh <path_to_fingerprints> <path_to_database> [-q]"
    exit 1
fi

TP=0
FP=0
TN=0
FN=0

#
# Compare retrieved fingerprint to the database of finerprints and report matching fingerprint
#
function compareToDatabase
{
    fingerprint=$1
    database=$2
    quiet=$3

    R=`tput setaf 1`
    G=`tput setaf 2`
    N=`tput sgr0`

    while read -r dbFingerprint
    do
        a=$(echo "$fingerprint" | awk -F';' '{printf "%s", $5}'  | tr -d '"')
        b=$(echo "$dbFingerprint" | awk -F';' '{printf "%s", $5}'  | tr -d '"')

        if [ $(echo "$fingerprint" | awk -F';' '{printf "%s", $1}'  | tr -d '"') = $(echo "$dbFingerprint" | awk -F';' '{printf "%s", $1}'  | tr -d '"') ] &&     # JA3
          #[ $(echo "$fingerprint" | awk -F';' '{printf "%s", $2}'  | tr -d '"') = $(echo "$dbFingerprint" | awk -F';' '{printf "%s", $2}'  | tr -d '"') ] &&     # JA3S
           [ $(echo "$fingerprint" | awk -F';' '{printf "%s", $3}'  | tr -d '"') = $(echo "$dbFingerprint" | awk -F';' '{printf "%s", $3}'  | tr -d '"') ]; then  # Cert
            if [ "$a" = "$b" ]; then
                [ "$quiet" == "-q" ] || echo "[${G}OK${N}]  True  positive: $a | $b"
                TP=$(($TP+1))
            else
                [ "$quiet" == "-q" ] || echo "[${R}NOK${N}] False positive: $a | $b"
                FP=$(($FP+1))
            fi
        else
            if [ "$a" = "$b" ]; then
                [ "$quiet" == "-q" ] || echo "[${R}NOK${N}] False negative: $a | $b"
                FN=$(($FN+1))
            else
                [ "$quiet" == "-q" ] || echo "[${G}OK${N}]  True  negative: $a | $b"
                TN=$(($TN+1))
            fi
        fi
    done <<< $(tail -n +2 "$database") # Skip header
}

#
# For each fingerprint do the comparison with the whole database and calculate statistics
#
function main()
{
    fingerprints=$1
    database=$2
    quiet=$3

    while read -r fingerprint
    do
        compareToDatabase $fingerprint $database $quiet
    done <<< $(tail -n +2 "$fingerprints") # Skip header

    echo
    echo "                 Predicted"
    echo "                 +-----------------+-----------------+"
    echo "                 | Positive        | Negative        |"
    echo "      +----------+-----------------+-----------------+"
    printf "GT    | Positive | (TN) %10d | (FP) %10d |\n" $TN $FP
    echo "      +----------+-----------------+-----------------+"
    printf "      | Negative | (FN) %10d | (TP) %10d |\n" $FN $TP
    echo "      +----------+-----------------+-----------------+"
    echo

    acc=$(echo "($TP + $TN) / ($TP + $TN + $FP + $FN)" | bc -l)
    prc=$(echo "$TP / ($TP + $FP)" | bc -l)
    rec=$(echo "$TP / ($TP + $FN)" | bc -l)

    echo "Accuracy:        $acc"
    echo "Precision:       $prc"
    echo "Recall:          $rec"
}

main $1 $2 $3