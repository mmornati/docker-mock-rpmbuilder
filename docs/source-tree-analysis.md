# Source Tree Analysis: docker-mock-rpmbuilder

## Directory Structure

```
docker-mock-rpmbuilder/
├── .agents/                    # AI agent configuration (BMAD)
│   └── skills/                # Skill definitions for AI workflows
├── _bmad/                      # BMAD module configuration
│   ├── bmm/                    # BMM core
│   ├── custom/                 # Team/user customizations
│   ├── scripts/                # Helper scripts
│   └── output/                 # Generated artifacts
├── _bmad-output/              # BMAD output directory
├── docs/                       # Generated documentation
├── .git/                       # Git repository
├── .travis.yml                 # Travis CI configuration
├── build-rpm.sh               # Main entry point ⚠️
├── Dockerfile                 # Container definition ⚠️
├── LICENSE                    # Project license
├── README.md                  # User documentation ⚠️
└── rpm-sign.exp               # GPG signing script ⚠️
```

**Legend:** ⚠️ = Critical file (core functionality)

## Critical Folders

### Root Level (Project Root)

| File/Folder | Purpose |
|-------------|---------|
| `Dockerfile` | Container image definition |
| `build-rpm.sh` | Main RPM build orchestration script |
| `rpm-sign.exp` | Expect script for GPG signing |
| `.travis.yml` | Travis CI/CD pipeline configuration |
| `README.md` | User-facing documentation |

### Hidden Configuration Folders

| File/Folder | Purpose |
|-------------|---------|
| `.agents/` | AI agent skill definitions |
| `_bmad/` | BMad module configuration |
| `.git/` | Git repository data |

### Generated Documentation

| File/Folder | Purpose |
|-------------|---------|
| `docs/` | Auto-generated project documentation |
| `_bmad-output/` | BMad workflow output artifacts |

## Entry Points

### Primary Entry Point: build-rpm.sh

**Path:** `./build-rpm.sh`
**Type:** Bash script
**Invocation:** Docker CMD directive

**Execution Flow:**
```
1. Parse environment variables
2. Validate MOCK_CONFIG
3. Validate SOURCE_RPM or SPEC_FILE
4. Configure proxy (optional)
5. Setup output/cache directories
6. Generate build script
7. Execute as mockbuilder user
8. Sign RPMs (optional)
```

### Alternative Entry: rpm-sign.exp

**Path:** `./rpm-sign.exp`
**Type:** Expect script
**Invocation:** Called from `build-rpm.sh` for GPG signing

## Key Files Detail

### build-rpm.sh (159 lines)

**Sections:**
- Lines 1-19: Variable initialization
- Lines 21-34: Input validation
- Lines 36-39: Cleanup configuration
- Lines 41-60: Proxy configuration
- Lines 62-73: Directory setup and Mock options
- Lines 75-133: Build command generation
- Lines 135-146: Build execution
- Lines 148-157: RPM signing

### Dockerfile (24 lines)

**Stages:**
- Base: `fedora:latest`
- Install packages
- Create mockbuilder user
- ONBUILD for mock config injection
- Copy scripts
- Set CMD

### rpm-sign.exp (11 lines)

**Logic:**
- Parse command line arguments
- Spawn rpm --resign
- Send passphrase
- Wait for completion

## Integration Points

### Host System Integration

| Integration | Location | Type |
|-------------|----------|------|
| Source/RPM mount | `${MOUNT_POINT}` | Volume mount |
| Output directory | `${MOUNT_POINT}/output` | Directory creation |
| Cache directory | `${MOUNT_POINT}/cache` | Directory creation |
| GPG keyring | `${HOME}/.gnupg` | Read-only mount |

### Mock Integration

| Integration | Location | Type |
|-------------|----------|------|
| Mock binary | `/usr/bin/mock` | System binary |
| Mock configs | `/etc/mock/*.cfg` | Config files |
| Mock user | `mockbuilder:mock` | Privilege separation |

## File Permissions

| File | Owner | Permissions | Notes |
|------|-------|-------------|-------|
| `build-rpm.sh` | root | +x (755) | Executed as entry point |
| `rpm-sign.exp` | root | +x (755) | Called by build script |
| `${OUTPUT_FOLDER}` | mockbuilder:mock | rwx (775) | Build output |
| `${CACHE_FOLDER}` | mockbuilder:mock | rwx (775) | Chroot cache |
