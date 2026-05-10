# Project Overview: docker-mock-rpmbuilder

## Project Name and Purpose

**docker-mock-rpmbuilder** is a Docker container image that enables cross-platform RPM package building using the [Mock](https://github.com/rpm-software-management/mock) project. It allows developers to build RPMs for any target Linux distribution/platform from any host OS that supports Docker.

**Primary Use Cases:**
- CI/CD pipelines for RPM-based Linux distributions (RHEL, CentOS, Fedora, EPEL)
- Cross-platform RPM building (e.g., building ARM64 RPMs from x86_64 host)
- Isolated, reproducible RPM build environments
- Automated RPM signing with GPG keys

## Repository Structure

- **Type:** Monolith (single-part)
- **Architecture:** Infrastructure/DevOps Tool (Docker container)

## Technology Stack

| Category | Technology | Version | Justification |
|----------|-----------|---------|---------------|
| Base Image | Fedora | latest | Provides latest Mock and rpmdevtools |
| Package Manager | DNF | latest | Fedora's default package manager |
| Build Tool | Mock | latest | RPM build isolation tool |
| Build Tool | rpmdevtools | latest | RPM development utilities |
| Scripting | Bash | system | Entry-point script language |
| Automation | Expect | latest | Interactive GPG passphrase automation |
| Emulation | qemu-user-static | latest | Cross-architecture builds (ARM64) |
| CI/CD | Travis CI | - | Automated Docker Hub builds |
| Registry | Docker Hub | - | Public image distribution |

## Architecture Type

- **Pattern:** Infrastructure-as-Container
- **Entry Point:** `/build-rpm.sh` (Bash script)
- **Container Type:** Single-purpose builder container

## Key Features

1. **Source RPM Rebuilding** - Rebuild pre-built SRPMs for different platforms
2. **Spec File Building** - Build RPMs from spec files and source tarballs
3. **Multi-architecture Support** - ARM64, x86_64, i686 via QEMU
4. **Network Control** - Enable/disable network access inside chroot
5. **Build Caching** - Cache Mock chroot directories for faster rebuilds
6. **GPG Signing** - Sign resulting RPMs with GPG keys
7. **Proxy Support** - Configure HTTP proxy for builds behind firewalls
8. **Custom Defines** - Pass RPM macro defines to spec files

## Existing Documentation

- [README.md](../README.md) - Full usage guide and examples

## Quick Reference

- **Build Script:** `/build-rpm.sh`
- **Signing Script:** `/rpm-sign.exp`
- **Mock Configs:** `/etc/mock/*.cfg` (from base image)
- **Container User:** `mockbuilder` (UID 1000, member of `mock` group)

## Entry Points

1. **Docker run** - Primary usage via `docker run` with environment variables
2. **GitHub Actions** - Via `mmornati/docker-mock-rpmbuilder@master`
3. **Docker Hub** - Pull pre-built image: `docker pull mmornati/mock-rpmbuilder`

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `MOCK_CONFIG` | Yes | Mock configuration (e.g., epel-8-aarch64) |
| `SOURCE_RPM` | No* | Source RPM filename to rebuild |
| `SPEC_FILE` | No* | Spec file path (requires SOURCES) |
| `SOURCES` | No | Sources directory path |
| `MOUNT_POINT` | Yes | Host directory mounted for I/O |
| `NETWORK` | No | Enable network in chroot ("true") |
| `NO_CLEANUP` | No | Skip chroot cleanup between builds |
| `MOCK_DEFINES` | No | Space-separated macro defines |
| `SIGNATURE` | No | GPG key name for signing |
| `GPG_PASS` | No | GPG passphrase |
| `HTTP_PROXY` | No | HTTP proxy URL |

*Either SOURCE_RPM or SPEC_FILE must be provided.

## Build Outputs

- RPMs stored in: `${MOUNT_POINT}/output/${MOCK_CONFIG}/`
- Build logs: `build.log`, `root.log`, `state.log`
- Build script saved: `build-script.sh` (deleted after execution)
