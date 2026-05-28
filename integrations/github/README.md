# GitHub Actions Self-Hosted Agent

This directory contains the containerized GitHub Actions self-hosted agent setup for AdaLab.

## Overview

The GitHub Actions agent runs in a container based on Ubuntu 24.04. It automatically downloads the requested agent version, registers with the GitHub repository or organisation of interest, and starts listening for build jobs.

## Files

| File | Purpose |
|------|---------|
| `Containerfile` | Installs GitHub Actions runner plus its dependencies, switches to an unprivileged user |
| `entrypoint.sh` | Entrypoint of the image. Handles auth (GitHub App, PAT, or manual token) and sets the correct registration URL. |

## Quick Start

### Prerequisites

- Docker (or Podman) installed on your system
- Permission to create self-hosted runners in a GitHub repository or organisation
- Find the version to install in the [releases page](https://github.com/actions/runner/releases/)

### 1. Build the Container Image

```bash
cd integrations/github
docker build -t gh-actions-agent:latest . --build-arg=VERSION=<version>
```

### 2. Authenticate the Runner

There are three ways to provide a registration token. Choose one:

#### Option A — GitHub App (recommended for production/automated deployments)

A GitHub App authenticates as a non-human identity with no ties to any individual user account. This is the most robust option for persistent deployments.

**Set up the GitHub App once:**

> **Required GitHub role:** You must be an **organisation owner** to create a GitHub App under an organisation and to install it. If you only have member access, ask an owner to perform the setup steps below, then hand you the App ID, Installation ID, and private key.

1. Go to your GitHub organisation settings → **Developer settings → GitHub Apps → New GitHub App**.
2. Give it a name and set the **Homepage URL** to anything (e.g. your org URL).
3. Under **Permissions → Organisation permissions**, set **Self-hosted runners** to **Read and write**.
4. Disable webhooks (not needed here).
5. Create the App, then generate a **private key** — a PEM file will download automatically.
6. Note the **Client ID** shown on the App's settings page (a string starting with `Iv`, not the numeric App ID).
7. **Install** the App on your organisation (Settings → Install App → your org).
8. After installation, note the **Installation ID** from the URL: `https://github.com/organizations/<org>/settings/installations/<installation_id>`.

**Run the container** with:

| Variable | Description |
|----------|-------------|
| `GH_APP_CLIENT_ID` | The Client ID from the App's settings page (a string starting with `Iv`) |
| `GH_APP_INSTALLATION_ID` | The numeric installation ID |
| `GH_APP_PRIVATE_KEY` | The full PEM content of the downloaded private key |

The entrypoint generates a short-lived JWT, exchanges it for an installation access token, and uses that to fetch the runner registration token — fully non-interactive and restartable.

#### Option B — Personal Access Token (simpler automated deployments)

Set `GH_PAT` to a GitHub PAT. The entrypoint calls the GitHub API at startup to exchange it for a short-lived registration token automatically. The container can be restarted without human intervention.

See [Required PAT permissions](#required-pat-permissions) below for the exact scopes needed.

#### Option C — Manual registration token (quick one-off deployments)

Go to the GitHub organisation or repository where the runner should be made available. Navigate to **Actions > Runners**, and trigger the wizard for adding a new self-hosted runner.

Copy the token from the example script. **DO NOT CLOSE OR REFRESH THIS TAB** — the token is invalidated if the page is closed or refreshed.

Set `GH_TOKEN` to the copied token when starting the container.

> **Warning:** If the runner container is restarted, it will not be able to re-register — you will need to generate a new token from the GitHub UI. For persistent or auto-restarting deployments, use **Option A** or **Option B** instead.

### 3. Deploy the Agent

Run the agent (locally or as an app) passing the following environment variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `GH_ORG` | One of | GitHub organisation name (e.g. `myorg`). Use this for organisation-wide runners. |
| `GH_REPO` | One of | Full URL of the repository the runner should register with (e.g. `https://github.com/org/repo`). Use this for repository-level runners. |
| `GH_APP_ID` | One of (A) | Numeric GitHub App ID |
| `GH_APP_INSTALLATION_ID` | One of (A) | Numeric installation ID of the App on your org |
| `GH_APP_PRIVATE_KEY` | One of (A) | Full PEM content of the App's private key |
| `GH_PAT` | One of (B) | Personal Access Token used to auto-fetch the registration token |
| `GH_TOKEN` | One of (C) | Short-lived registration token obtained manually from the GitHub UI |
| `AGENT_NAME` | Yes | Name to be displayed in GitHub under **Actions > Runners** |
| `AGENT_LABELS` | No | Comma-separated labels to facilitate runner selection (e.g. `python,gpu`) |

Set either `GH_ORG` (org-wide runner) or `GH_REPO` (repo-level runner), not both.

### 4. Verify Connection

Observe the app logs and the **Runners** page in GitHub to make sure that the runner has reached *Online* or *Idle* status. This indicates it is ready to receive submissions.

## Required PAT permissions

The PAT is used to call the GitHub API endpoint that generates a short-lived runner registration token.

### Organisation runner

| PAT type | Required scope / permission |
|----------|-----------------------------|
| Classic PAT | `admin:org` |
| Fine-grained PAT | `Organization self-hosted runners` → **Read and write** |

API reference: [`POST /orgs/{org}/actions/runners/registration-token`](https://docs.github.com/en/rest/actions/self-hosted-runners?apiVersion=2022-11-28#create-a-registration-token-for-an-organization)

### Repository runner

| PAT type | Required scope / permission |
|----------|-----------------------------|
| Classic PAT | `repo` (full repository access) |
| Fine-grained PAT | `Administration` → **Read and write** on the target repository |

API reference: [`POST /repos/{owner}/{repo}/actions/runners/registration-token`](https://docs.github.com/en/rest/actions/self-hosted-runners?apiVersion=2022-11-28#create-a-registration-token-for-a-repository)

## Tips and Troubleshooting

- When using a manual registration token (`GH_TOKEN`), keep the GitHub page open until the container has registered successfully — closing or refreshing it invalidates the token.
- The container must expose a port to be deployed as an app. Any value can be used, since nothing will be served.
- If the container terminates or restarts, the connection might be lost. In that case, the agent needs to be deployed again (Options A and B handle this automatically).
- For GitHub App auth, the private key PEM can be passed as a multiline env var or a Docker/Kubernetes secret.

## Reference

- [Official GitHub Documentation](https://docs.github.com/en/actions/how-tos/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners)
- [GitHub Actions Runner Releases](https://github.com/actions/runner/releases/)
- [GitHub Apps — Creating a GitHub App](https://docs.github.com/en/apps/creating-github-apps/creating-github-apps/creating-a-github-app)
- [GitHub REST API — Self-hosted runners](https://docs.github.com/en/rest/actions/self-hosted-runners)
