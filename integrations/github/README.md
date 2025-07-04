# GitHub Actions Self-Hosted Agent

This directory contains the containerized GitHub Actions self-hosted agent setup for AdaLab.

## Overview

The GitHub Actions agent runs in a container based on Ubuntu 24.04. It automatically downloads the requested agent version, registers with the GitHub repository of interest, and starts listening for build jobs.

## Files

| File | Purpose |
|------|---------|
| `Containerfile` |  Installs GitHub Actions runner plus its dependencies, switches to an unprivileged user |

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

### 2. Obtain Handshake Token

Go to the GitHub organization/repository where the runner should be made available. Navigate to **Actions > Runners**, and trigger the wizard for adding a new self-hosted runner.

Copy the URL and token from the example script. **DO NOT CLOSE OR REFRESH THIS TAB**.

### 3. Deploy the Agent

Run the agent (locally or as an app) passing the following environment variables:

-`GH_REPO`: full URL obtained in [step 2](#2-obtain-handshake-token)
-`GH_TOKEN`: token obtained in [step 2](#2-obtain-handshake-token)
-`AGENT_NAME`: name to be displayed in GitHub
-`AGENT_LABELS`: labels to facilitate runner selection (e.g., *python*)

### 4. Verify Connection

Observe the app logs and the **Runners** page in GitHub to make sure that the runner has reached *Online* or *Idle* status. This indicates it is ready to receive submissions.

## Tips and Troubleshooting

- The handshake token is *very* short lived. Thus, make sure you use it immediately after generating it.
- The container must expose a port to be deployed as an app. Any value can be used, since nothing will be served.
- If the container terminates or restarts, the connection might be lost. In that case, the agent needs to be deployed again.


## Reference

- [Official GitHub Documentation](https://docs.github.com/en/actions/how-tos/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners)
- [GitHub Actions Runner Releases](https://github.com/actions/runner/releases/)
