# Azure DevOps Self-Hosted Agent

This directory contains the containerized Azure DevOps self-hosted agent setup for AdaLab.

## Overview

The Azure DevOps agent runs in a Linux container based on Alpine Linux with Python. It automatically downloads the latest agent version, registers with your Azure DevOps organization, and starts listening for build jobs.

## Files

| File | Purpose |
|------|---------|
| `Containerfile` | Minimal Alpine-Python base, installs Azure DevOps agent at runtime |
| `start.sh` | Downloads latest matching agent, registers with PAT, starts listener |

## Quick Start

### Prerequisites

- Docker installed on your system
- Azure DevOps organization
- Personal Access Token (PAT) with Agent Pools (read, manage) scope

### 1. Build the Container Image

```bash
cd integrations/ado
docker build -t azp-agent:linux .
```

### 2. Create Environment File

Create a `.ado.env` file with your Azure DevOps configuration:

```bash
echo 'AZP_URL=https://dev.azure.com/YOUR_ORG' > .ado.env
echo 'AZP_TOKEN=YOUR_PERSONAL_ACCESS_TOKEN' >> .ado.env
echo 'AZP_POOL=YOUR_AGENT_POOL_NAME' >> .ado.env
```

### 3. Run the Agent

```bash
docker run -d --env-file .ado.env azp-agent:linux
```

The agent will:
1. Download the latest Azure DevOps agent
2. Register itself with your organization
3. Start listening for pipeline jobs
4. Auto-unregister when the container is stopped

## Environment Variables

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| `AZP_URL` | Yes | Azure DevOps organization URL (e.g., `https://dev.azure.com/yourorg`) | None |
| `AZP_TOKEN` | Yes | Personal Access Token with Agent Pools permissions | None |
| `AZP_POOL` | No | Agent pool name | `Default` |
| `AZP_AGENT_NAME` | No | Custom agent name | Container hostname |
| `AZP_WORK` | No | Work directory for builds | `_work` |

## Personal Access Token Setup

1. Go to your Azure DevOps organization
2. Click on your profile picture → **Personal access tokens**
3. Click **+ New Token**
4. Configure the token:
   - **Name**: AdaLab Self-Hosted Agent
   - **Scopes**: **Agent Pools (read, manage)**
   - **Expiration**: Set as needed
5. Copy the generated token immediately (you won't see it again)

## Agent Pool Configuration

### Create a New Agent Pool (Recommended)

1. In Azure DevOps, go to **Organization Settings**
2. Select **Agent pools** under **Pipelines**
3. Click **Add pool**
4. Choose **Self-hosted** pool type
5. Name it (e.g., "AdaLab-Linux")
6. Grant access to all pipelines if desired

### Use Existing Pool

You can also use the default "Default" pool, but creating a dedicated pool provides better organization and security.

## Production Deployment

### Running Multiple Agents

Scale by running multiple containers:

```bash
# Agent 1
docker run -d --name azp-agent-1 --env-file .ado.env azp-agent:linux

# Agent 2  
docker run -d --name azp-agent-2 --env-file .ado.env azp-agent:linux
```

Each container represents one concurrent build slot.


### Persistent Work Directory

Mount a volume for build cache persistence:

```bash
docker run -d \
  --env-file .ado.env \
  -v azp-work:/azp/_work \
  azp-agent:linux
```

## Customization

### Adding Build Tools

Extend the `Containerfile` to include additional tools:

```dockerfile
FROM python:3-alpine
ENV TARGETARCH="linux-musl-x64"

# Install base dependencies
RUN apk update && apk upgrade && \
    apk add bash curl gcc git icu-libs jq musl-dev python3-dev libffi-dev openssl-dev cargo make

# Add your custom tools
RUN apk add --no-cache \
    zip unzip \
    nodejs npm \
    docker-cli

# Install Azure CLI
RUN pip install --upgrade pip && pip install azure-cli

# ... rest of original Containerfile
```

### Common Build Dependencies

For different project types, consider adding:

- **.NET Projects**: Follow [Install .NET on Alpine](https://learn.microsoft.com/en-us/dotnet/core/install/linux-alpine)
- **Node.js Projects**: `apk add nodejs npm`
- **Python Projects**: Already included (Python 3 + pip)
- **Archive Operations**: `apk add zip unzip` (for ArchiveFiles/ExtractFiles tasks)
- **Docker Builds**: `apk add docker-cli` (requires Docker socket mounting)

## Security Considerations

### Token Security

- **Never** bake tokens into the container image
- Use environment files or secure secret management
- Rotate tokens regularly
- Use minimal scope permissions

### Running as Non-Root

The container runs as the `agent` user by default. To run as root (not recommended):

```dockerfile
ENV AGENT_ALLOW_RUNASROOT="true"
# Remove the agent user creation lines
```

### Network Security

- Agents make only outbound HTTPS connections to Azure DevOps
- No inbound ports need to be exposed
- Runs entirely within your network perimeter

## Troubleshooting

### Common Issues

**Agent not appearing in pool:**
- Verify `AZP_URL` format: `https://dev.azure.com/yourorg` (no trailing slash)
- Check PAT permissions include "Agent Pools (read, manage)"
- Ensure the specified pool exists

**Build failures:**
- Check if required tools are installed in the container
- Verify the agent has access to required resources
- Review pipeline logs for missing dependencies

**Container exits immediately:**
- Check environment variables are correctly set
- Review container logs: `docker logs <container-name>`
- Verify token is valid and not expired

### Viewing Logs

```bash
# View agent registration and runtime logs
docker logs <container-name>

# Follow logs in real-time
docker logs -f <container-name>
```

## Reference

- [Official Microsoft Documentation](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops)
- [Azure DevOps Agent Releases](https://github.com/Microsoft/azure-pipelines-agent/releases)
- [Agent Pool Management](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues?view=azure-devops)
