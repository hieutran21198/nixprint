# Polyrepo

This workspace uses a polyrepo layout. Each application, service, library, and deployment setup can live in its own repository.

- `apps/` contains frontend applications.
- `services/` contains server-side services.
- `libs/` contains shared or public libraries used across the project.
- `deployment/` contains deployment configuration and related files.

Keep each repository focused on one clear purpose. Add project-specific setup and usage details in that repository's README.

Read [Polyrepo Governance](docs/wiki/governance/polyrepo.md) before you add or change a project artifact.
