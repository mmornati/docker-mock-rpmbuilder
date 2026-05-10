# Project Documentation Index

## Project Overview

- **Name:** docker-mock-rpmbuilder
- **Type:** Monolith (single-part)
- **Primary Language:** Bash, Dockerfile
- **Architecture:** Infrastructure-as-Container (Docker)

### Quick Reference

- **Tech Stack:** Fedora (base), Mock, rpmdevtools, Bash, Expect
- **Entry Point:** `/build-rpm.sh` (Bash script)
- **Architecture Pattern:** Single-purpose builder container

### Key Features

- Cross-platform RPM building using Mock
- Multi-architecture support (ARM64, x86_64, i686)
- Optional GPG signing of RPMs
- Configurable proxy support
- Build caching for faster rebuilds

## Generated Documentation

### Core Documentation
- [Project Overview](./project-overview.md)
- [Architecture](./architecture.md)
- [Source Tree Analysis](./source-tree-analysis.md)
- [Development Guide](./development-guide.md)

### Existing Documentation
- [README.md](../README.md) - Full usage guide with examples

## Getting Started

### Quick Build

```bash
# Create working directory
mkdir /path/to/rpmbuild

# Run RPM build
docker run --rm --privileged=true \
  --volume="/path/to/rpmbuild:/rpmbuild" \
  -e MOUNT_POINT="/rpmbuild" \
  -e MOCK_CONFIG="epel-8-aarch64" \
  -e SOURCE_RPM="your-package.src.rpm" \
  mmornati/mock-rpmbuilder
```

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `MOCK_CONFIG` | Yes | Mock configuration |
| `MOUNT_POINT` | Yes | Host directory mount |
| `SOURCE_RPM` | No* | Source RPM to rebuild |
| `SPEC_FILE` | No* | Spec file path |
| `SOURCES` | No | Sources directory |
| `NETWORK` | No | Enable network ("true") |
| `NO_CLEANUP` | No | Skip chroot cleanup |
| `MOCK_DEFINES` | No | RPM macro defines |
| `SIGNATURE` | No | GPG key name |
| `GPG_PASS` | No | GPG passphrase |

*Either SOURCE_RPM or SPEC_FILE required.

## Build Outputs

After build completes, check:
- **Location:** `${MOUNT_POINT}/output/${MOCK_CONFIG}/`
- **Logs:** `build.log`, `root.log`, `state.log`
- **RPMs:** Binary and source RPMs

## CI/CD Integration

- **Travis CI:** Automated Docker Hub builds
- **GitHub Actions:** Use `mmornati/docker-mock-rpmbuilder@master`
- **Docker Hub:** Auto-build on commits

## Documentation Info

- **Generated:** 2026-05-10
- **Scan Level:** Deep
- **Location:** `docs/`
