# Self-Hosted CI Agents inside AdaLab

This repository provides containerized examples of self-hosted CI/CD agents for the AdaLab platform.

## Integrations

| Platform       | Status                  | Directory                          |
|----------------|-------------------------|------------------------------------|
| Azure DevOps   | ✅ Implemented & Tested | [integrations/ado](integrations/ado) |
| GitHub Actions | 🚧 Planned              | [integrations/github](integrations/github) |
| GitLab CI      | 🚧 Planned              | [integrations/gitlab](integrations/gitlab) |

Only the Azure DevOps integration is currently implemented and tested. See the README in each integration directory for detailed setup instructions.

## Repository Layout

```
integrations/
├── ado/    # Azure DevOps agent (implemented)
├── github/ # GitHub Actions runner (planned)
└── gitlab/ # GitLab CI runner (planned)
```

## Security Principles (General)

- Never bake long-lived tokens into container images.
- Use environment files or secure secret management systems.
- Agents make outbound HTTPS connections only; no inbound ports required.
- Agents run within your network perimeter for internal service access.

## Contributing

Contributions welcome—feel free to PR additional CI/CD systems or improvements.