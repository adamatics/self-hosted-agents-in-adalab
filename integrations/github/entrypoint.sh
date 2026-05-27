#!/bin/bash
set -e

if [ -n "${GH_PAT}" ]; then
    echo "Fetching registration token using PAT..."
    GH_OWNER=$(echo "${GH_REPO}" | awk -F'/' '{print $(NF-1)}')
    GH_REPO_NAME=$(echo "${GH_REPO}" | awk -F'/' '{print $NF}')
    API_RESPONSE=$(curl -s -X POST \
        -H "Authorization: Bearer ${GH_PAT}" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${GH_OWNER}/${GH_REPO_NAME}/actions/runners/registration-token")
    echo "Registration token fetched successfully"
    export GH_TOKEN=$(echo "${API_RESPONSE}" | jq -r .token)
    if [ -z "${GH_TOKEN}" ] || [ "${GH_TOKEN}" = "null" ]; then
        echo "Error: failed to fetch registration token"
        exit 1
    fi
elif [ -z "${GH_TOKEN}" ]; then
    echo "Error: either GH_PAT or GH_TOKEN must be set"
    exit 1
fi

exec bash -c "$@"
