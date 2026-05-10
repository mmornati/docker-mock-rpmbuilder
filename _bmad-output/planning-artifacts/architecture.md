---
stepsCompleted: [1, 2, 3, 4, 5, 6]
inputDocuments:
  - path: "_bmad-output/planning-artifacts/prd.md"
    type: "prd"
  - path: "docs/architecture.md"
    type: "architecture"
workflowType: 'architecture'
project_name: 'docker-mock-rpmbuilder'
user_name: 'mmornati'
date: '2026-05-10'
---

# Architecture Decision Document - docker-mock-rpmbuilder

_This document defines the architecture for AI agent implementation consistency._

---

## Project Context Analysis

### Requirements Overview

**Functional Requirements:** 27 FRs organized into 7 categories
- Build Configuration (FR1-FR6): Mock config, source RPM, spec file, defines, network, cleanup
- Build Execution (FR7-FR12): Mock execution, SRPM+rebuild, logs, output, cache, cross-arch
- Output Management (FR13-FR16): Directory structure, permissions, script generation
- RPM Signing (FR17-FR20): GPG key, passphrase, automatic signing, read-only keyring
- Network & Proxy (FR21-FR23): HTTP proxy configuration
- Container Integration (FR24-FR27): User isolation, privileges, exit codes, logging

**Non-Functional Requirements:**
- Performance: <500MB image, <5s startup, concurrent containers
- Security: No embedded secrets, non-root user, minimal attack surface, read-only mounts
- Reliability: Reproducible builds, proper exit codes, build isolation
- Scalability: Horizontal scaling, no state sharing

### Scale & Complexity

- **Complexity:** Low-Medium
- **Primary domain:** Infrastructure/DevOps (Docker container)
- **Components:** 3 (entry point, signing script, Dockerfile)
- **Cross-cutting concerns:** Build isolation, GPG signing, proxy support, CI/CD integration

### Technical Constraints

- Requires `--privileged=true` or `--cap-add=SYS_ADMIN` for Mock namespace operations
- QEMU user emulation required for ARM64 builds on x86_64 hosts
- GPG keyring must be mountable read-only from host
- Fedora base image for Mock compatibility

---

## Starter Template Evaluation

### Existing Architecture (Pre-established)

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| Base Image | Fedora:latest | Provides Mock compatibility |
| Entry Point | Bash (build-rpm.sh) | Industry standard for container scripts |
| Signing Script | Expect (rpm-sign.exp) | Interactive passphrase automation |
| Cross-Arch | QEMU user-static | ARM64 builds on x86_64 hosts |
| Build Isolation | Mock chroot | RPM spec compliance |
| CI/CD | Travis CI | Docker Hub integration |
| Container User | mockbuilder (UID 1000) | Non-root security |

**No Change Recommended:** This is a brownfield project with established, appropriate architecture.

---

## Core Architectural Decisions

### Security Architecture

| Component | Decision | Rationale |
|-----------|----------|-----------|
| User Isolation | mockbuilder (non-root) | FR24 compliance |
| Secrets | None embedded | NFR4 compliance |
| GPG Keyring | Read-only mount | Security requirement |
| Attack Surface | Minimal packages | Only required deps |

### Build Architecture

| Component | Decision | Rationale |
|-----------|----------|-----------|
| Build Tool | Mock project | Standard RPM isolation |
| Output Structure | `${MOUNT_POINT}/output/${MOCK_CONFIG}/` | Organized by config |
| Caching | Root cache + yum cache | Build speed |
| Reproducibility | `--source-date-epoch-from-changelog` | Identical outputs |

### Infrastructure & Deployment

| Component | Decision | Rationale |
|-----------|----------|-----------|
| Registry | Docker Hub | Public distribution |
| Auto-build | Travis CI | Docker Hub integration |
| Image Tags | `master` + version tags | Release tracking |
| Multi-arch | QEMU emulation | Democratize ARM64 |

### Cross-Component Dependencies

1. Mock → Requires `--privileged=true` or `--cap-add=SYS_ADMIN`
2. QEMU → Must be installed in container for ARM64
3. GPG signing → Requires host keyring mount
4. Proxy → Requires `/etc/mock` config patching

### Deferred Decisions

- GitHub Actions migration (Travis CI aging)
- Shell completion support

---

## Implementation Patterns & Consistency Rules

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Scripts | `kebab-case.ext` | `build-rpm.sh`, `rpm-sign.exp` |
| Configs | Same as source | `*.cfg` for Mock |
| Output dirs | Underline-separated | `output_${MOCK_CONFIG}` |
| Env vars | UPPER_SNAKE_CASE | `MOCK_CONFIG`, `MOUNT_POINT` |

### Structure Patterns

```
project/
├── Dockerfile           # Container definition
├── build-rpm.sh        # Main entry point
├── rpm-sign.exp        # Signing automation
├── .travis.yml         # CI/CD pipeline
└── docs/               # Documentation
```

### Scripting Patterns

**Bash Guidelines:**
- Use `set -e` for exit on error
- Always quote variables
- Use `shellcheck` for linting
- Check return codes after commands

**Expect Scripting:**
- Minimal, focused on passphrase automation
- Handle EOF properly
- Log errors to stderr

### Error Handling

**Exit Codes:**
- `0` = Success
- `1` = General failure
- Non-zero = Specific error conditions

**Logging:**
- Build logs: `build.log`, `root.log`, `state.log`
- Structured output for Docker logs

### CI/CD Patterns

**Travis CI Pipeline:**
1. `before_install`: Docker version check
2. `install`: Clone official-images
3. `before_script`: Build and inspect image
4. `script`: Run official-images test
5. `after_success`: Docker Hub push

---

## Project Structure

### Root Level Files

| File | Purpose | Pattern |
|------|---------|---------|
| `Dockerfile` | Container definition | Standard naming |
| `build-rpm.sh` | Main entry point | Executable (+x) |
| `rpm-sign.exp` | Signing script | Executable (+x) |
| `.travis.yml` | CI/CD config | Standard naming |
| `README.md` | User documentation | Standard naming |

### Documentation Structure

```
docs/
├── index.md                    # Documentation index
├── project-overview.md         # Project overview
├── architecture.md             # This architecture doc
├── source-tree-analysis.md     # Source tree documentation
└── development-guide.md        # Developer guide
```

### Output Structure

```
${MOUNT_POINT}/
├── output/
│   └── ${MOCK_CONFIG}/         # Build results
│       ├── *.rpm              # Built packages
│       ├── build.log          # Mock build log
│       ├── root.log            # Chroot initialization
│       └── state.log           # Build state
├── cache/                      # Mock cache (optional)
├── SOURCES/                   # Source tarballs (optional)
└── SPECS/                      # Spec files (optional)
```

---

## AI Agent Implementation Guidelines

### Mandatory Patterns

1. **All scripts must set `set -e`** at the top for error handling
2. **Environment variables always quoted** when used
3. **Exit codes propagated** - don't swallow errors
4. **Logging to stderr for errors**, stdout for progress
5. **Output directories created with proper permissions**
6. **User isolation respected** - run as mockbuilder for builds

### Enforcement

- Use `shellcheck` for Bash scripts
- Verify exit codes are correct for CI/CD
- Test container runs without privileged mode warning (where possible)

---

## Summary

This is a **mature brownfield project** with established architecture. The key value for AI agents is:

1. **Clear component boundaries** - 3 core files, well-defined responsibilities
2. **Environment variable API** - No config files, pure env var configuration
3. **Security model** - Non-root user, no embedded secrets, read-only mounts
4. **CI/CD integration** - Travis CI + Docker Hub auto-builds

**No architectural changes recommended** unless pursuing:
- GitHub Actions migration
- Shell completion features
- Build webhook notifications
