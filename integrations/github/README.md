# GitHub Actions Self-Hosted Agent

This directory contains the containerized GitHub Actions self-hosted agent setup for AdaLab.

## Table of Contents

- [Overview](#overview)
- [Files](#files)
- [Quick Start](#quick-start)
  - [Prerequisites](#prerequisites)
  - [1. Build the Container Image](#1-build-the-container-image)
  - [2. Authenticate the Runner](#2-authenticate-the-runner)
  - [3. Deploy the Agent](#3-deploy-the-agent)
  - [4. Verify Connection](#4-verify-connection)
- [Required PAT permissions](#required-pat-permissions)
- [Extending the Image](#extending-the-image)
- [Tips and Troubleshooting](#tips-and-troubleshooting)
- [Reference](#reference)

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

```sh
cd integrations/github
docker build -t gh-actions-agent:latest -f Containerfile . --build-arg=VERSION=<version>
```

### 2. Authenticate the Runner

There are three ways to provide a registration token. Choose one:
- Option A — GitHub App
    - Recommended for production/automated deployments
    - Requires GitHub Organization owner permission
- Option B — Personal Access Token
    - Simpler automated deployments
    - (Preferably) Use a service account
- Option C — Manual registration token
    - Quick one-off deployments

The Options are described below:


#### **Option A — GitHub App (recommended for production/automated deployments)**

A GitHub App authenticates as a non-human identity with no ties to any individual user account. This is the most robust option for persistent deployments.

**Set up the GitHub App once:**

> **Required GitHub role:** You must be an **organisation owner** to create a GitHub App under an organisation and to install it. If you only have member access, ask an owner to perform the setup steps below, then hand you the App ID, Installation ID, and private key.

1. Go to your GitHub organisation settings → **Developer settings → GitHub Apps → New GitHub App**.
2. Give it a name and set the **Homepage URL** to anything (e.g. your org URL).
3. Disable webhooks (not needed here).
4. Under **Permissions → Organisation permissions**, set **Self-hosted runners** to **Read and write**.
5. Note the **Client ID** shown on the App's settings page (a string starting with `Iv`, not the numeric App ID).
6. Create the App, then generate a **private key** — a PEM file will download automatically.
7. **Install** the App on your organisation (Settings → Install App → your org).
8. After installation, note the **Installation ID** from the URL: `https://github.com/organizations/<org>/settings/installations/<installation_id>`.

**Run the container** with:

| Variable | Description |
|----------|-------------|
| `GH_APP_CLIENT_ID` | The Client ID from the App's settings page (a string starting with `Iv`) |
| `GH_APP_INSTALLATION_ID` | The numeric installation ID |
| `GH_APP_PRIVATE_KEY` | The base64-encoded PEM private key (see below) |

The PEM private key must be base64-encoded before storing it as an environment variable, since multiline values are not reliably preserved across container runtimes:

```bash
GH_APP_PRIVATE_KEY=$(base64 -w 0 < your-app.private-key.pem)
```

The entrypoint decodes it at runtime before use.

The entrypoint generates a short-lived JWT, exchanges it for an installation access token, and uses that to fetch the runner registration token — fully non-interactive and restartable.

#### **Option B — Personal Access Token (simpler automated deployments)**

Set `GH_PAT` to a GitHub PAT. The entrypoint calls the GitHub API at startup to exchange it for a short-lived registration token automatically. The container can be restarted without human intervention.

> **Note:** The PAT is tied to a user account. Prefer using a dedicated service account so the runner does not break if the user leaves the organisation.

See [Required PAT permissions](#required-pat-permissions) below for the exact scopes needed.

#### **Option C — Manual registration token (quick one-off deployments)**

Go to the GitHub organisation or repository where the runner should be made available. Navigate to **Actions > Runners**, and trigger the wizard for adding a new self-hosted runner.

Copy the token from the example script. **DO NOT CLOSE OR REFRESH THIS TAB** — the token is invalidated if the page is closed or refreshed.

Set `GH_TOKEN` to the copied token when starting the container.

> **Warning:** If the runner container is restarted, it will not be able to re-register — you will need to generate a new token from the GitHub UI. For persistent or auto-restarting deployments, use **Option A** or **Option B** instead.

### 3. Deploy the Agent

Run the agent (locally or as an app) passing the following environment variables:

**Runner scope** — set exactly one:

| Variable | Description |
|----------|-------------|
| `GH_ORG` | Organisation name only (e.g. `myorg`). Registers the runner org-wide. |
| `GH_REPO` | Full repository URL (e.g. `https://github.com/org/repo`). Registers the runner for that repo only. |

**Authentication** — set exactly one group:

| Variable | Option | Description |
|----------|--------|-------------|
| `GH_APP_CLIENT_ID` | A — GitHub App | Client ID from the App's settings page |
| `GH_APP_INSTALLATION_ID` | A — GitHub App | Installation ID of the App on your org |
| `GH_APP_PRIVATE_KEY` | A — GitHub App | Base64-encoded PEM private key |
| `GH_PAT` | B — PAT | Personal Access Token; exchanged for a registration token at startup |
| `GH_TOKEN` | C — Manual | Short-lived registration token copied directly from the GitHub UI |

**Runner identity:**

| Variable | Required | Description |
|----------|----------|-------------|
| `AGENT_NAME` | Yes | Name displayed in GitHub under **Actions > Runners** |
| `AGENT_LABELS` | No | Comma-separated labels for runner selection (e.g. `python,gpu`) |
| `ACTIONS_RUNNER_INPUT_REPLACE` | No | Replace an existing runner with the same name. Defaults to `true`. Set to `false` to disable. |

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

## Extending the Image

If your workflows require tools beyond what the base image provides (e.g. Python, Node.js, Docker CLI, cloud CLIs), use this image as a base and install what you need on top.

```dockerfile
FROM gh-actions-agent:latest

USER root

RUN apt install -y python3 python3-pip

USER agent
```

A few things to keep in mind:

- **Switch to `root` for installs**, then switch back to `agent` before the end of the file. The base image drops privileges to the `agent` user, and most package managers require root.
- **Add labels** to your extended image and set `AGENT_LABELS` accordingly when deploying, so workflows can target runners that have the right tools (e.g. `--labels python,gpu`).
- **Pin versions** of any installed tools to keep runner behaviour predictable across rebuilds.

## Tips and Troubleshooting

- When using a manual registration token (`GH_TOKEN`), keep the GitHub page open until the container has registered successfully — closing or refreshing it invalidates the token.
- If using a PAT against an organisation with SAML SSO enabled, the token must also be explicitly authorised for that organisation in GitHub — correct scopes alone are not enough. Look for the **"Configure SSO"** button next to the token on the [Personal access tokens](https://github.com/settings/tokens) page.
- The container must expose a port to be deployed as an app. Any value can be used, since nothing will be served.
- If the container terminates or restarts, the connection might be lost. In that case, the agent needs to be deployed again (Options A and B handle this automatically).
- For GitHub App auth, the private key PEM can be passed as a multiline env var or a Docker/Kubernetes secret.

## Reference

- [Official GitHub Documentation](https://docs.github.com/en/actions/how-tos/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners)
- [GitHub Actions Runner Releases](https://github.com/actions/runner/releases/)
- [GitHub Apps — Creating a GitHub App](https://docs.github.com/en/apps/creating-github-apps/creating-github-apps/creating-a-github-app)
- [GitHub REST API — Self-hosted runners](https://docs.github.com/en/rest/actions/self-hosted-runners)
