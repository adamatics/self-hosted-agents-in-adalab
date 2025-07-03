# GitLab CI Self-Hosted Runner

This directory contains the containerized GitLab CI self-hosted runner setup for AdaLab.

## Overview

⚠️ **This integration is not yet implemented/tested.**

The GitLab CI runner will run in a Linux container based on the official gitlab/gitlab-runner image and connect to your GitLab instance to execute CI/CD jobs.

## Files

| File | Purpose |
|------|---------|
| `Containerfile` | Thin wrapper around official gitlab/gitlab-runner |
| `register.sh` | One-time helper to register a runner (writes config volume) |
| `run.sh` | Starts the persistent runner container |

## Planned Features

- Self-hosted GitLab CI runner in container
- Based on official GitLab Runner Docker image
- Automatic registration with GitLab instance
- Support for CI/CD pipeline execution
- Integration with AdaLab network for internal service access

## Environment Variables (Planned)

| Variable | Required | Description |
|----------|----------|-------------|
| `CI_SERVER_URL` | Yes | GitLab instance URL |
| `REGISTRATION_TOKEN` | Yes | GitLab runner registration token (one-time use) |
| `RUNNER_NAME` | No | Custom runner name |
| `RUNNER_TAGS` | No | Custom tags for the runner |

## Getting GitLab Registration Token

### For Project Runners
1. Go to your GitLab project
2. Navigate to **Settings** → **CI/CD**
3. Expand the **Runners** section
4. Copy the registration token

### For Group/Instance Runners
1. Go to GitLab Admin Area (instance) or Group settings
2. Navigate to **CI/CD** → **Runners**
3. Copy the registration token

## Planned Architecture

The GitLab integration will use a two-step process:
1. **Registration**: One-time setup using `register.sh` 
2. **Runtime**: Persistent runner using `run.sh`

This approach allows the registration token to be used once and stored in a volume, avoiding the need to embed it in the image.

## Status

🚧 **Coming Soon** - This integration will be implemented based on the Azure DevOps pattern.

For immediate needs, refer to the [official GitLab Runner documentation](https://docs.gitlab.com/runner/).

## Reference

- [GitLab Runner Documentation](https://docs.gitlab.com/runner/)
- [GitLab Runner Docker Image](https://docs.gitlab.com/runner/install/docker.html)
- [GitLab Runner Registration](https://docs.gitlab.com/runner/register/)
