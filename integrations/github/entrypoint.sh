#!/bin/bash
set -e

b64url() {
    base64 -w 0 | tr '+' '-' | tr '/' '_' | tr -d '='
}

get_token_via_app() {
    local now iat exp header payload sig_input signature jwt token_response install_token
    now=$(date +%s)
    iat=$((now - 60))
    exp=$((now + 540))

    header=$(printf '{"alg":"RS256","typ":"JWT"}' | b64url)
    payload=$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' "${iat}" "${exp}" "${GH_APP_CLIENT_ID}" | b64url)
    sig_input="${header}.${payload}"
    signature=$(printf '%s' "${sig_input}" | openssl dgst -sha256 -sign <(printf '%s' "${GH_APP_PRIVATE_KEY}") -binary | b64url)
    jwt="${sig_input}.${signature}"

    echo "Fetching installation access token using GitHub App (installation ${GH_APP_INSTALLATION_ID})..."
    token_response=$(curl -s -X POST \
        -H "Authorization: Bearer ${jwt}" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/app/installations/${GH_APP_INSTALLATION_ID}/access_tokens")

    install_token=$(echo "${token_response}" | jq -r .token)
    if [ -z "${install_token}" ] || [ "${install_token}" = "null" ]; then
        echo "Error: failed to fetch installation access token"
        echo "Response: ${token_response}"
        exit 1
    fi
    printf '%s' "${install_token}"
}

get_registration_token() {
    local bearer_token="$1"
    local api_url reg_response reg_token

    if [ -n "${GH_ORG}" ]; then
        echo "Fetching org-level runner registration token for org: ${GH_ORG}..."
        api_url="https://api.github.com/orgs/${GH_ORG}/actions/runners/registration-token"
    else
        local owner repo_name
        owner=$(echo "${GH_REPO}" | awk -F'/' '{print $(NF-1)}')
        repo_name=$(echo "${GH_REPO}" | awk -F'/' '{print $NF}')
        echo "Fetching repo-level runner registration token for ${owner}/${repo_name}..."
        api_url="https://api.github.com/repos/${owner}/${repo_name}/actions/runners/registration-token"
    fi

    reg_response=$(curl -s -X POST \
        -H "Authorization: Bearer ${bearer_token}" \
        -H "Accept: application/vnd.github+json" \
        "${api_url}")

    reg_token=$(echo "${reg_response}" | jq -r .token)
    if [ -z "${reg_token}" ] || [ "${reg_token}" = "null" ]; then
        echo "Error: failed to fetch registration token"
        echo "Response: ${reg_response}"
        exit 1
    fi
    printf '%s' "${reg_token}"
}

if [ -n "${GH_APP_CLIENT_ID}" ] && [ -n "${GH_APP_INSTALLATION_ID}" ] && [ -n "${GH_APP_PRIVATE_KEY}" ]; then
    bearer=$(get_token_via_app)
    export GH_TOKEN=$(get_registration_token "${bearer}")
elif [ -n "${GH_PAT}" ]; then
    echo "Fetching registration token using PAT..."
    export GH_TOKEN=$(get_registration_token "${GH_PAT}")
elif [ -z "${GH_TOKEN}" ]; then
    echo "Error: set GH_APP_ID+GH_APP_INSTALLATION_ID+GH_APP_PRIVATE_KEY, GH_PAT, or GH_TOKEN"
    exit 1
fi

if [ -n "${GH_ORG}" ]; then
    export GH_CONFIG_URL="https://github.com/${GH_ORG}"
else
    export GH_CONFIG_URL="${GH_REPO}"
fi

exec bash -c "$@"
