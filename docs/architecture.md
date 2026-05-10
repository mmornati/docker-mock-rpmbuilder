# Architecture Document: docker-mock-rpmbuilder

## Executive Summary

docker-mock-rpmbuilder is a single-purpose Docker container that provides an isolated RPM build environment using the Mock project. It enables reproducible, cross-platform RPM package building while maintaining host isolation through containerization.

## Technology Stack

| Category | Technology | Version | Justification |
|----------|-----------|---------|---------------|
| Base Image | Fedora | latest | Latest Mock and rpmdevtools |
| Package Manager | DNF | latest | Fedora's default package manager |
| Build Tool | Mock | latest | RPM build isolation tool |
| Build Tool | rpmdevtools | latest | RPM development utilities |
| Scripting | Bash | system | Entry-point script |
| Automation | Expect | latest | GPG passphrase automation |
| Emulation | qemu-user-static | latest | Cross-architecture builds |
| CI/CD | Travis CI | - | Docker Hub integration |

## Architecture Pattern

**Pattern:** Infrastructure-as-Container (Single-Purpose Builder)

```
┌─────────────────────────────────────────────────────────────┐
│                      Docker Container                        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   build-rpm.sh                         │  │
│  │                   (Entry Point)                       │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐   │  │
│  │  │ Config     │  │ Build       │  │ RPM Signing  │   │  │
│  │  │ Validation │  │ Execution   │  │ (Optional)   │   │  │
│  │  └─────────────┘  └─────────────┘  └──────────────┘   │  │
│  └───────────────────────────────────────────────────────┘  │
│                        │                                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                    Mock (chroot)                       │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │          Target Linux Environment                │  │  │
│  │  │  (RHEL/CentOS/Fedora/EPEL - any arch)           │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
         │                                    │
    Host Mount                              Host Mount
    (Sources)                           (Output RPMs)
```

## Component Overview

### 1. Entry Point: build-rpm.sh

**Purpose:** Orchestrate the complete RPM build workflow

**Responsibilities:**
- Validate environment variables
- Configure Mock options (proxy, network, defines)
- Execute mock build commands
- Handle GPG signing (optional)
- Manage output directory structure

**Key Sections:**
```
1. Variable Setup (lines 1-19)
   - Mock binary paths
   - Output/cache folder configuration
   - Mock defines parsing

2. Validation (lines 21-34)
   - MOCK_CONFIG presence
   - Mock config file existence
   - SOURCE_RPM or SPEC_FILE presence

3. Proxy Configuration (lines 41-60)
   - HTTP_PROXY detection
   - Config file patching

4. Build Execution (lines 76-146)
   - SOURCE_RPM path (simple rebuild)
   - SPEC_FILE path (srpm + rebuild)
   - Script generation and execution

5. RPM Signing (lines 148-157)
   - GPG configuration
   - expect-based passphrase handling
```

### 2. Signing Script: rpm-sign.exp

**Purpose:** Automate GPG passphrase entry for RPM signing

**Implementation:** Expect script that:
- Receives RPM file path and passphrase as arguments
- Spawns `rpm --resign` process
- Sends passphrase when prompted
- Handles EOF completion

### 3. Dockerfile

**Purpose:** Define reproducible container image

**Build Stages:**
```
1. Base: fedora:latest
2. Install: rpmdevtools, mock, qemu-user-static, rpm-sign, expect
3. User Setup: Create mockbuilder user with mock group access
4. ONBUILD: Copy local mock configs
5. Script Copy: build-rpm.sh, rpm-sign.exp
```

## Data Flow

```
User Command
     │
     ▼
┌─────────────┐
│ Docker Run  │ ←── Environment Variables
└─────────────┘
     │
     ▼
┌─────────────────────────────────┐
│      build-rpm.sh Entry          │
│  (Validation & Configuration)    │
└─────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────┐
│      Mock Build Execution       │
│  (as mockbuilder user)         │
└─────────────────────────────────┘
     │
     ├──> SRPM Generation (if spec file)
     │
     ▼
┌─────────────────────────────────┐
│     RPM Binary Generation       │
│  (chroot environment)          │
└─────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────┐
│     Optional GPG Signing        │
│  (via rpm-sign.exp)            │
└─────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────┐
│     Output to Host Mount        │
│  ${MOUNT_POINT}/output/        │
└─────────────────────────────────┘
```

## Build Modes

### Mode 1: Source RPM Rebuild
```
SOURCE_RPM provided → mock --rebuild → RPMs
```
- Single mock invocation
- Fastest execution
- No source compilation

### Mode 2: Spec File Build
```
SPEC_FILE + SOURCES → rpmbuild (SRPM) → mock (RPMs)
```
- Two-phase build
- Full source compilation in chroot
- Slower but complete

## Security Architecture

### User Privileges
- **Container User:** `mockbuilder` (UID 1000)
- **Group Membership:** `mock` group
- **Directory Permissions:** Write access to output/cache folders

### Privilege Requirements
- **Host Requirement:** `--privileged=true` or `--cap-add=SYS_ADMIN`
- **Reason:** Mock uses `unshare` for mount namespace isolation
- **Alternative:** `--privileged=true` if SYS_ADMIN insufficient

### GPG Signing Security
- GPG keyring mounted read-only from host
- Passphrase passed via environment/file
- `.rpmmacros` configured in container HOME

## CI/CD Integration

### Travis CI Pipeline
```
1. Build Docker image locally
2. Inspect image metadata
3. Run basic mock version check
4. Test via official-images test framework
5. Push to Docker Hub on success
```

### GitHub Actions Compatibility
- Uses GitHub Actions Docker metadata
- Supports `mmornati/docker-mock-rpmbuilder@master` reference
- Environment variable based configuration

## Source Tree Analysis

```
docker-mock-rpmbuilder/
├── Dockerfile          # Container definition
├── build-rpm.sh       # Main entry point (Bash)
├── rpm-sign.exp       # GPG signing automation (Expect)
├── .travis.yml        # CI/CD pipeline
├── README.md          # Usage documentation
├── LICENSE            # Project license
└── docs/              # Generated documentation
    ├── project-overview.md
    ├── architecture.md
    └── index.md
```

## Development Workflow

### Prerequisites
- Docker
- Mount point directory with RPM sources

### Local Development
```bash
# Build container
docker build -t mmornati/mock-rpmbuilder .

# Test basic mock version
docker run --rm mmornati/mock-rpmbuilder mock --version

# Run RPM build
docker run --rm --privileged=true \
  --volume="/path/to/rpmbuild:/rpmbuild" \
  -e MOUNT_POINT="/rpmbuild" \
  -e MOCK_CONFIG="epel-8-aarch64" \
  -e SOURCE_RPM="git-2.3.0-1.el7.centos.src.rpm" \
  mmornati/mock-rpmbuilder
```

### Testing Approach
- Travis CI runs official Docker image tests
- Mock version check validates installation
- Full integration test via official-images framework

## Deployment Architecture

### Container Registry
- **Primary:** Docker Hub (`mmornati/mock-rpmbuilder`)
- **Build Trigger:** Travis CI on each commit
- **Tags:** `master`, version tags

### Environment Configuration
All configuration via environment variables at runtime:
- No build-time configuration required
- No config files baked into image
- Maximum flexibility for users

### Storage Requirements
- **Minimum:** 10GB for chroot cache
- **Recommended:** 20GB+ for multiple builds
- **Cache Location:** `${MOUNT_POINT}/cache`
- **Output Location:** `${MOUNT_POINT}/output`
