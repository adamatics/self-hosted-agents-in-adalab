# GitLab CI Self-Hosted Runner

This directory contains the containerized GitLab CI self-hosted runner setup for AdaLab.

## Overview

The image installs the official GitLab Runner on Ubuntu 24.04. At startup it registers using a one-time registration token and then runs the runner using the specified executor.

## Files

| File | Purpose |
|------|---------|
| `Containerfile` | Installs GitLab Runner and sets up entrypoint to register and run |

## Quick Start

### Prerequisites

- Docker (or Podman) installed on your system
- Access to a GitLab instance and a registration token
- The URL of your GitLab server (e.g., `https://gitlab.com`)

### 1. Build the Container Image

```bash
cd integrations/gitlab
docker build -t gitlab-runner:latest .
```

### 2. Deploy the Runner

Run the container passing the following environment variables:

- `CI_SERVER_URL`: URL of the GitLab instance
- `REGISTRATION_TOKEN`: token used to register the runner
- `RUNNER_NAME`: name to display in GitLab
- `RUNNER_TAGS`: comma-separated tags for the runner
- `RUNNER_EXECUTOR`: executor to use (`shell` by default)

Example:

```bash
docker run -d \
  -e CI_SERVER_URL=https://gitlab.com/ \
  -e REGISTRATION_TOKEN=<token> \
  -e RUNNER_NAME=AdaLabRunner \
  -e RUNNER_TAGS=linux,x64 \
  gitlab-runner:latest
```

### 3. Verify Connection

Observe the container logs and the **Runners** page in GitLab to ensure the runner is registered and online.

## Reference

- [GitLab Runner Documentation](https://docs.gitlab.com/runner/)
