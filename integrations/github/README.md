# GitHub Actions Self-Hosted Runner

This directory contains the containerized GitHub Actions self-hosted runner setup for AdaLab.

## Overview

⚠️ **This integration is not yet implemented/tested.**

The GitHub Actions runner will run in a Linux container and connect to your GitHub repository or organization to execute workflow jobs.

## Files

| File | Purpose |
|------|---------|
| `Containerfile` | Ubuntu base with Actions runner; labels/tokens via env-vars |
| `start.sh` | Configures runner (`./config.sh`) then `./run.sh` |

## Planned Features

- Self-hosted GitHub Actions runner in container
- Automatic registration with GitHub repository/organization
- Support for workflow job execution
- Integration with AdaLab network for internal service access

## Environment Variables (Planned)

| Variable | Required | Description |
|----------|----------|-------------|
| `GH_REPO` | Yes | GitHub repository URL |
| `GH_TOKEN` | Yes | GitHub registration token |
| `RUNNER_NAME` | No | Custom runner name |
| `RUNNER_LABELS` | No | Custom labels for the runner |

## Getting GitHub Registration Token

1. Go to your GitHub repository
2. Navigate to **Settings** → **Actions** → **Runners**
3. Click **New self-hosted runner**
4. Copy the registration token from the configuration command

## Status

🚧 **Coming Soon** - This integration will be implemented based on the Azure DevOps pattern.

For immediate needs, refer to the [official GitHub documentation](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners).

## Reference

- [GitHub Self-Hosted Runners Documentation](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Running Self-Hosted Runners in Docker](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/using-self-hosted-runners-in-a-workflow)
