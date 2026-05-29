#!/bin/bash
set -e

# --- Validation helpers ---

require_var() {
    local name="$1" value="$2" context="$3"
    if [ -z "${value}" ]; then
        echo "Error [${context}]: ${name} is required but not set" >&2
        exit 1
    fi
}

validate_base64() {
    local name="$1" value="$2" context="$3"
    if ! printf '%s' "${value}" | base64 -d > /dev/null 2>&1; then
        echo "Error [${context}]: ${name} is not valid base64 — encode the PEM file with: base64 -w 0 < key.pem" >&2
        exit 1
    fi
}

validate_target() {
    if [ -z "${GH_ORG}" ] && [ -z "${GH_REPO}" ]; then
        echo "Error: GH_ORG or GH_REPO must be set to specify where the runner should register" >&2
        exit 1
    fi
    if [ -n "${GH_ORG}" ] && [ -n "${GH_REPO}" ]; then
        echo "Error: set either GH_ORG (org-wide runner) or GH_REPO (repo runner), not both" >&2
        exit 1
    fi
    if [[ "${GH_ORG}" == http* ]]; then
        echo "Error: GH_ORG must be the organisation name only (e.g. 'myorg'), not a URL" >&2
        exit 1
    fi
}

# --- Auth flow detection and validation ---

detect_auth_flow() {
    local has_app_client_id has_app_installation_id has_app_key has_pat has_token
    [ -n "${GH_APP_CLIENT_ID}" ]       && has_app_client_id=1
    [ -n "${GH_APP_INSTALLATION_ID}" ] && has_app_installation_id=1
    [ -n "${GH_APP_PRIVATE_KEY}" ]     && has_app_key=1
    [ -n "${GH_PAT}" ]                 && has_pat=1
    [ -n "${GH_TOKEN}" ]               && has_token=1

    local app_vars_set=$(( ${has_app_client_id:-0} + ${has_app_installation_id:-0} + ${has_app_key:-0} ))

    if [ "${app_vars_set}" -gt 0 ] && [ "${app_vars_set}" -lt 3 ]; then
        echo "Error: GitHub App auth requires all three variables. Missing:" >&2
        [ -z "${has_app_client_id}" ]       && echo "  - GH_APP_CLIENT_ID" >&2
        [ -z "${has_app_installation_id}" ] && echo "  - GH_APP_INSTALLATION_ID" >&2
        [ -z "${has_app_key}" ]             && echo "  - GH_APP_PRIVATE_KEY" >&2
        exit 1
    fi

    if [ "${app_vars_set}" -eq 3 ]; then
        echo "app"
    elif [ -n "${has_pat}" ]; then
        echo "pat"
    elif [ -n "${has_token}" ]; then
        echo "token"
    else
        echo "Error: no auth method configured. Set one of:" >&2
        echo "  - GH_APP_CLIENT_ID + GH_APP_INSTALLATION_ID + GH_APP_PRIVATE_KEY  (GitHub App)" >&2
        echo "  - GH_PAT                                                           (Personal Access Token)" >&2
        echo "  - GH_TOKEN                                                         (manual registration token)" >&2
        exit 1
    fi
}

# --- Token fetch functions ---

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
    signature=$(printf '%s' "${sig_input}" | openssl dgst -sha256 -sign <(printf '%s' "${GH_APP_PRIVATE_KEY}" | base64 -d) -binary | b64url)
    jwt="${sig_input}.${signature}"

    echo "Fetching installation access token using GitHub App (installation ${GH_APP_INSTALLATION_ID})..." >&2
    token_response=$(curl -s -X POST \
        -H "Authorization: Bearer ${jwt}" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/app/installations/${GH_APP_INSTALLATION_ID}/access_tokens")

    install_token=$(echo "${token_response}" | jq -r .token)
    if [ -z "${install_token}" ] || [ "${install_token}" = "null" ]; then
        echo "Error: failed to fetch installation access token" >&2
        echo "Response: ${token_response}" >&2
        exit 1
    fi
    printf '%s' "${install_token}"
}

get_registration_token() {
    local bearer_token="$1"
    local api_url reg_response reg_token

    if [ -n "${GH_ORG}" ]; then
        echo "Fetching org-level runner registration token for org: ${GH_ORG}..." >&2
        api_url="https://api.github.com/orgs/${GH_ORG}/actions/runners/registration-token"
    else
        local owner repo_name
        owner=$(echo "${GH_REPO}" | awk -F'/' '{print $(NF-1)}')
        repo_name=$(echo "${GH_REPO}" | awk -F'/' '{print $NF}')
        echo "Fetching repo-level runner registration token for ${owner}/${repo_name}..." >&2
        api_url="https://api.github.com/repos/${owner}/${repo_name}/actions/runners/registration-token"
    fi

    reg_response=$(curl -s -X POST \
        -H "Authorization: Bearer ${bearer_token}" \
        -H "Accept: application/vnd.github+json" \
        "${api_url}")

    reg_token=$(echo "${reg_response}" | jq -r .token)
    if [ -z "${reg_token}" ] || [ "${reg_token}" = "null" ]; then
        echo "Error: failed to fetch registration token" >&2
        echo "Response: ${reg_response}" >&2
        exit 1
    fi
    printf '%s' "${reg_token}"
}

# --- Main ---

validate_target

AUTH_FLOW=$(detect_auth_flow)

case "${AUTH_FLOW}" in
    app)
        validate_base64 "GH_APP_PRIVATE_KEY" "${GH_APP_PRIVATE_KEY}" "GitHub App auth"
        bearer=$(get_token_via_app)
        export GH_TOKEN=$(get_registration_token "${bearer}")
        ;;
    pat)
        echo "Fetching registration token using PAT..." >&2
        export GH_TOKEN=$(get_registration_token "${GH_PAT}")
        ;;
    token)
        echo "Using provided GH_TOKEN directly" >&2
        ;;
esac

require_var "AGENT_NAME" "${AGENT_NAME}" "runner config"

if [ -n "${GH_ORG}" ]; then
    export GH_CONFIG_URL="https://github.com/${GH_ORG}"
else
    export GH_CONFIG_URL="${GH_REPO}"
fi

echo "Registering runner at: ${GH_CONFIG_URL}" >&2

# Unset credentials — only needed to obtain GH_TOKEN above.
# Without this, any workflow job running on this runner could read them via env.
unset GH_APP_CLIENT_ID GH_APP_INSTALLATION_ID GH_APP_PRIVATE_KEY GH_PAT

exec bash -c "$@"
