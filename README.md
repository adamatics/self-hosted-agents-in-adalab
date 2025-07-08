# Self-Hosted CI Agents inside AdaLab

This repository provides containerized examples of self-hosted CI/CD agents for the AdaLab platform.

## Integrations

| Platform       | Status                  | Directory                          |
|----------------|-------------------------|------------------------------------|
| Azure DevOps   | ✅ Implemented & Tested | [integrations/ado](integrations/ado) |
| GitHub Actions | ✅ Implemented & Tested | [integrations/github](integrations/github) |
| GitLab CI      | ✅ Implemented | [integrations/gitlab](integrations/gitlab) |

All three integrations provide runnable examples of self-hosted agents. See the README in each integration directory for detailed setup instructions.

## Repository Layout

```
integrations/
├── ado/    # Azure DevOps agent (implemented)
├── github/ # GitHub Actions runner (implemented)
└── gitlab/ # GitLab CI runner (implemented)
```

## Security Principles (General)

- Never bake long-lived tokens into container images.
- Use environment files or secure secret management systems.
- Agents make outbound HTTPS connections only; no inbound ports required.
- Agents run within your network perimeter for internal service access.

## Contributing

Contributions welcome—feel free to PR additional CI/CD systems or improvements.