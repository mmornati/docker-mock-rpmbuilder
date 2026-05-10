---
stepsCompleted: ["step-01-init", "step-02-discovery", "step-02b-vision", "step-02c-executive-summary", "step-03-success", "step-04-journeys", "step-05-domain", "step-06-innovation", "step-07-project-type", "step-08-scoping", "step-09-functional", "step-10-nonfunctional", "step-11-polish", "step-12-complete"]
inputDocuments:
  - path: "docs/project-overview.md"
    type: "project-overview"
  - path: "docs/architecture.md"
    type: "architecture"
  - path: "docs/source-tree-analysis.md"
    type: "source-tree"
  - path: "docs/development-guide.md"
    type: "development-guide"
  - path: "README.md"
    type: "existing-documentation"
workflowType: 'prd'
classification:
  projectType: "Infrastructure/DevOps Tool (Docker Container)"
  domain: "RPM Package Management / Linux Distribution Support"
  complexity: "Low-Medium"
  projectContext: "Brownfield"
---

# Product Requirements Document - docker-mock-rpmbuilder

**Author:** mmornati
**Date:** 2026-05-10

## Executive Summary

**docker-mock-rpmbuilder** provides containerized, cross-platform RPM package building using the Mock project. It enables developers and CI/CD pipelines to build RPMs for any target Linux distribution (RHEL, CentOS, Fedora, EPEL) from any host OS that supports Docker.

**Target Users:**
- DevOps engineers building RPM-based CI/CD pipelines
- Package maintainers needing cross-architecture builds (ARM64, x86_64)
- Teams requiring reproducible, isolated build environments

**Problem Solved:**
- Eliminates need for native build hosts per target distribution
- Provides consistent build environments without host pollution
- Enables automated RPM signing in CI/CD workflows

### What Makes This Special

- **Zero-installation builds:** No Mock or rpmdevtools installation needed on host
- **Cross-architecture native:** Builds ARM64 RPMs from x86_64 hosts via QEMU
- **GitHub Actions ready:** Drop-in action for RPM workflows
- **Automated signing:** GPG passphrase automation
- **Build caching:** Mock chroot cached between builds

## Project Classification

- **Type:** Infrastructure/DevOps Tool (Docker Container)
- **Domain:** RPM Package Management / Linux Distribution Support
- **Complexity:** Low-Medium
- **Context:** Brownfield (actively maintained since 2016)

## Success Criteria

### User Success
- RPMs successfully built within expected timeframes per Mock config
- ARM64 builds produce working RPMs from x86_64 hosts
- Users can run builds with minimal environment variables
- GitHub Actions workflows complete without manual intervention

### Business Success
- Docker Hub pulls indicate consistent usage
- External contributors submit patches/features
- Container image updates only when dependencies change
- Builds succeed consistently across supported distributions

### Technical Success
- Reasonable image size for fast pulls
- No host contamination from build dependencies
- No credentials or secrets embedded in image
- Identical source produces identical RPMs across builds

## User Journeys

### Sarah - DevOps Engineer (CI/CD Pipeline)
Sarah's team needs to build RPMs for EL7, EL8, EL9. She discovers docker-mock-rpmbuilder, sets up her GitHub Actions workflow, and the first CI run produces RPMs for all platforms without server maintenance.

### Marco - Package Maintainer (Cross-Architecture)
Marco's application needs ARM64 RPMs but his build machine is x86_64. ARM64 RPMs are built via QEMU emulation — no ARM hardware needed.

### Amanda - Release Manager (Secure Signing)
Security policy requires GPG-signed RPMs. She configures signing parameters, mounts her GPG keyring, and all RPMs are automatically signed before retrieval.

### David - Developer (Local Debug)
A customer reports a build failure. David runs the container with `NO_CLEANUP=true`, examines the chroot environment, identifies the missing dependency, and verifies the fix.

### Journey Requirements Summary

| Capability | Required By |
|-----------|-------------|
| Source RPM rebuild | Sarah (CI/CD), David (debug) |
| Spec + sources build | Sarah (CI/CD) |
| Multi-arch support | Marco (ARM64) |
| GPG signing | Amanda (compliance) |
| Build caching | David (debug) |
| Network control | Sarah (golang builds) |
| Proxy support | Amanda (enterprise firewall) |

## Project Scoping

**Current State:** Production-ready container with established user base.
**Approach:** Evolution over revolution — incremental improvements.

### Shipping Features

| Feature | Status |
|---------|--------|
| Source RPM rebuild | ✅ |
| Spec + sources build | ✅ |
| Multi-architecture (ARM64 via QEMU) | ✅ |
| Build caching (NO_CLEANUP) | ✅ |
| GPG signing (expect-based) | ✅ |
| Proxy support (HTTP_PROXY) | ✅ |
| Network control (NETWORK) | ✅ |
| Custom defines (MOCK_DEFINES) | ✅ |

### Future Enhancements

| Feature | Priority |
|---------|----------|
| GitHub Actions docs | Medium |
| Shell completion | Low |
| Build result webhooks | Low |
| Multi-config parallel builds | Low |

## Functional Requirements

### Build Configuration
- FR1: Users can specify target Mock configuration for RPM builds
- FR2: Users can provide source RPM file for direct rebuild
- FR3: Users can provide spec file and sources directory for full builds
- FR4: Users can pass custom RPM macro defines to spec files
- FR5: Users can enable network access inside Mock chroot
- FR6: Users can control Mock chroot cleanup behavior between builds

### Build Execution
- FR7: System executes Mock rebuild with specified configuration
- FR8: System executes two-phase build (SRPM + binary RPM) from spec file
- FR9: System generates structured build logs for debugging
- FR10: System writes built RPMs to host-mounted output directory
- FR11: System preserves build cache for faster subsequent builds
- FR12: System supports cross-architecture builds (ARM64 on x86_64)

### Output Management
- FR13: System creates organized output directory structure by Mock config
- FR14: System sets appropriate permissions on output files
- FR15: System generates build-script.sh for reproducibility
- FR16: System removes temporary build script after execution

### RPM Signing
- FR17: Users can specify GPG key name for RPM signing
- FR18: Users can provide passphrase for GPG key decryption
- FR19: System automatically signs all generated RPMs with specified key
- FR20: System supports read-only GPG keyring mounting from host

### Network & Proxy
- FR21: Users can configure HTTP proxy for builds behind firewalls
- FR22: System patches Mock configuration with proxy settings
- FR23: Users can enable network access for builds requiring external resources

### Container Integration
- FR24: System runs as non-root user (mockbuilder) for security
- FR25: System requires minimal privileges for operation
- FR26: System provides proper exit codes for CI/CD pipelines
- FR27: System outputs structured logs to stdout for container inspection

## Non-Functional Requirements

### Performance
- **Image size:** <500MB for fast pulls
- **Startup:** Entry point script <5 seconds
- **Concurrency:** Multiple containers can run simultaneously

### Security
- **No embedded secrets:** No credentials in image
- **User isolation:** Runs as non-privileged mockbuilder user
- **Minimal attack surface:** Only required packages installed
- **Read-only mounts:** GPG keyring mounted read-only

### Reliability
- **Reproducibility:** Identical source produces identical RPMs
- **Exit codes:** 0=success, non-zero=failure
- **Build isolation:** No host contamination
- **Cleanup:** Chroot cleaned between builds (unless NO_CLEANUP=true)

### Scalability
- **Horizontal scaling:** Multiple containers in parallel
- **No state sharing:** Each build independent

## CLI Interface

**Primary Interface:** `docker run` with environment variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `MOCK_CONFIG` | Yes | Target distribution/config |
| `MOUNT_POINT` | Yes | Host directory for I/O |
| `SOURCE_RPM` | No* | Source RPM to rebuild |
| `SPEC_FILE` | No* | Spec file for source builds |
| `SOURCES` | No | Sources directory |
| `NETWORK` | No | Enable network access |
| `NO_CLEANUP` | No | Skip chroot cleanup |
| `MOCK_DEFINES` | No | RPM macro defines |
| `SIGNATURE` | No | GPG key name |
| `GPG_PASS` | No | GPG passphrase |

*Either SOURCE_RPM OR (SPEC_FILE + SOURCES) required.

**Output:**
- Logs: `build.log`, `root.log`, `state.log`
- Exit codes: 0=success, non-zero=failure
- GitHub Actions: `mmornati/docker-mock-rpmbuilder@master`
