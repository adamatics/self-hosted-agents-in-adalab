# GitHub Actions Self-Hosted Agent

This directory contains the containerized GitHub Actions self-hosted agent setup for AdaLab.

## Overview

The GitHub Actions agent runs in a container based on Ubuntu 24.04. It automatically downloads the requested agent version, registers with the GitHub repository of interest, and starts listening for build jobs.

## Files

| File | Purpose |
|------|---------|
| `Containerfile` |  Installs GitHub Actions runner plus its dependencies, switches to an unprivileged user |
| `entrypoint.sh` | Entry point of the image. It allows setting GH_PAT for generating the registration token. |
## Quick Start

### Prerequisites

- Docker (or Podman) installed on your system
- Permission to create self-hosted runners in a GitHub repository
- Find the version to install in the [releases page](https://github.com/actions/runner/releases/)

### 1. Build the Container Image

```bash
cd integrations/github
docker build -t gh-actions-agent:latest . --build-arg=VERSION=<version>
```

### 2. Authenticate the Runner

There are two ways to provide a registration token. Choose one:

#### Option A — Personal Access Token (recommended for automated/persistent deployments)

Set `GH_PAT` to a GitHub PAT. The entrypoint calls the GitHub API at startup to exchange it for a short-lived registration token automatically. No manual token copy-paste needed, and the container can be restarted without human intervention.

See [Required PAT permissions](#required-pat-permissions) below for the exact scopes needed.

#### Option B — Manual registration token (quick one-off deployments)

Go to the GitHub organization/repository where the runner should be made available. Navigate to **Actions > Runners**, and trigger the wizard for adding a new self-hosted runner.

Copy the URL and token from the example script. **DO NOT CLOSE OR REFRESH THIS TAB** — the token is tied to this page session and will be invalidated if the page is closed or refreshed.

Set `GH_TOKEN` to the copied token when starting the container.

> **Warning:** If the runner container is restarted, it will not be able to re-register — the token is tied to the GitHub page session and is invalidated when the session is closed. You will need to generate a new token from the GitHub UI.
>
> For persistent or auto-restarting deployments, use **Option A** instead.

### 3. Deploy the Agent

Run the agent (locally or as an app) passing the following environment variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `GH_REPO` | Yes | Full URL of the repository the runner should register with (e.g. `https://github.com/org/repo`) |
| `GH_PAT` | One of | Personal Access Token used to auto-fetch the registration token (Option A) |
| `GH_TOKEN` | One of | Short-lived registration token obtained manually from the GitHub UI (Option B) |
| `AGENT_NAME` | Yes | Name to be displayed in GitHub under **Actions > Runners** |
| `AGENT_LABELS` | No | Comma-separated labels to facilitate runner selection (e.g. `python,gpu`) |

### 4. Verify Connection

Observe the app logs and the **Runners** page in GitHub to make sure that the runner has reached *Online* or *Idle* status. This indicates it is ready to receive submissions.

## Required PAT permissions

The PAT is used to call the GitHub API endpoint that generates a short-lived runner registration token. The required scopes depend on whether the runner is registered at the repository or organisation level.

> **Note:** The current `entrypoint.sh` uses the repository-level API endpoint (`/repos/{owner}/{repo}/actions/runners/registration-token`). Organisation-level registration requires a separate endpoint and is not yet implemented.

### Repository runner

| PAT type | Required scope / permission |
|----------|-----------------------------|
| Classic PAT | `repo` (full repository access) |
| Fine-grained PAT | `Administration` → **Read and write** on the target repository |

API reference: [`POST /repos/{owner}/{repo}/actions/runners/registration-token`](https://docs.github.com/en/rest/actions/self-hosted-runners?apiVersion=2022-11-28#create-a-registration-token-for-a-repository)

### Organisation runner *(not yet supported by entrypoint.sh)*

| PAT type | Required scope / permission |
|----------|-----------------------------|
| Classic PAT | `admin:org` |
| Fine-grained PAT | `Organization self-hosted runners` → **Read and write** |

API reference: [`POST /orgs/{org}/actions/runners/registration-token`](https://docs.github.com/en/rest/actions/self-hosted-runners?apiVersion=2022-11-28#create-a-registration-token-for-an-organization)

## Tips and Troubleshooting

- When using a manual registration token (`GH_TOKEN`), keep the GitHub page open until the container has registered successfully — closing or refreshing it invalidates the token.
- The container must expose a port to be deployed as an app. Any value can be used, since nothing will be served.
- If the container terminates or restarts, the connection might be lost. In that case, the agent needs to be deployed again.


## Reference

- [Official GitHub Documentation](https://docs.github.com/en/actions/how-tos/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners)
- [GitHub Actions Runner Releases](https://github.com/actions/runner/releases/)
