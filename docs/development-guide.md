# Development Guide: docker-mock-rpmbuilder

## Prerequisites

### Required Tools
- Docker (with support for multi-arch builds if needed)
- Git

### Optional Tools
- qemu-user-static (for cross-architecture builds on x86_64 host)

## Environment Setup

### 1. Clone Repository
```bash
git clone https://github.com/mmornati/docker-mock-rpmbuilder.git
cd docker-mock-rpmbuilder
```

### 2. Create Working Directory
```bash
mkdir -p /path/to/rpmbuild
chown 1000:1000 /path/to/rpmbuild
```
**Note:** On macOS, chown is not needed (Docker uses your default user).

### 3. Directory Structure
Expected structure in mount point:
```
/path/to/rpmbuild/
├── SOURCES/           # Source tarballs (optional)
├── SPECS/            # Spec files (optional)
├── output/          # Build results (created by container)
│   └── {MOCK_CONFIG}/
└── cache/           # Mock chroot cache (optional)
```

## Build Commands

### Building Container Locally
```bash
docker build -t mmornati/mock-rpmbuilder .
```

### Test Container
```bash
# Verify mock installation
docker run --rm mmornati/mock-rpmbuilder mock --version
```

### Build from Source RPM
```bash
docker run --rm --privileged=true \
  --volume="/path/to/rpmbuild:/rpmbuild" \
  -e MOUNT_POINT="/rpmbuild" \
  -e MOCK_CONFIG="epel-8-aarch64" \
  -e SOURCE_RPM="git-2.3.0-1.el7.centos.src.rpm" \
  mmornati/mock-rpmbuilder
```

### Build from Spec File
```bash
docker run --rm --privileged=true \
  --volume="/path/to/rpmbuild:/rpmbuild" \
  -e MOUNT_POINT="/rpmbuild" \
  -e MOCK_CONFIG="epel-8-aarch64" \
  -e SOURCES="SOURCES/git-2.3.0.tar.gz" \
  -e SPEC_FILE="SPECS/git.spec" \
  mmornati/mock-rpmbuilder
```

### Build with Network Enabled
```bash
docker run --rm --privileged=true \
  --volume="/path/to/rpmbuild:/rpmbuild" \
  -e MOUNT_POINT="/rpmbuild" \
  -e MOCK_CONFIG="centos-stream-8-x86_64" \
  -e NETWORK="true" \
  -e SPEC_FILE="SPECS/prometheus.spec" \
  mmornati/mock-rpmbuilder
```

### Build with Custom Defines
```bash
docker run --rm --privileged=true \
  --volume="/path/to/rpmbuild:/rpmbuild" \
  -e MOUNT_POINT="/rpmbuild" \
  -e MOCK_CONFIG="epel-8-aarch64" \
  -e SOURCES="SOURCES/git-2.3.0.tar.gz" \
  -e SPEC_FILE="SPECS/git.spec" \
  -e MOCK_DEFINES="VERSION=1 RELEASE=12 ANYTHING_ELSE=1" \
  mmornati/mock-rpmbuilder
```

### Build with Caching
```bash
docker run --rm --privileged=true \
  --volume="/path/to/rpmbuild:/rpmbuild" \
  -e MOUNT_POINT="/rpmbuild" \
  -e MOCK_CONFIG="epel-8-aarch64" \
  -e NO_CLEANUP="true" \
  -e SOURCES="SOURCES/git-2.3.0.tar.gz" \
  -e SPEC_FILE="SPECS/git.spec" \
  mmornati/mock-rpmbuilder
```

### Build with GPG Signing
```bash
docker run --cap-add=SYS_ADMIN \
  -e MOUNT_POINT="/rpmbuild" \
  -e MOCK_CONFIG="epel-8-aarch64" \
  -e SOURCE_RPM="git-2.3.0-1.el7.centos.src.rpm" \
  -e SIGNATURE="Corporate Repo Key" \
  -e GPG_PASS="$(cat .gpg_pass)" \
  -v /path/to/rpmbuild:/rpmbuild \
  -v $HOME/.gnupg:/home/rpmbuilder/.gnupg:ro \
  mmornati/mock-rpmbuilder
```

## Testing

### Local Container Test
```bash
docker run --rm mmornati/mock-rpmbuilder mock --version
```

### Full Integration Test (Travis CI)
Travis CI runs official-images test framework:
```bash
official-images/test/run.sh -t utc -t override-cmd "mmornati/mock-rpmbuilder"
```

### Check Build Logs
```bash
docker logs {container_id}
# Or check log files in output directory
cat /path/to/rpmbuild/output/{MOCK_CONFIG}/build.log
```

## Common Development Tasks

### Add New Mock Configuration
Mock configs are loaded via ONBUILD from host. Ensure your config file is in `/etc/mock/` and mounted or copied.

### Modify Build Behavior
Edit `build-rpm.sh` and rebuild:
```bash
# Edit build-rpm.sh
vim build-rpm.sh
# Rebuild
docker build -t mmornati/mock-rpmbuilder .
```

### Debug Build Issues
```bash
# Run without cleanup to inspect chroot
docker run --rm --privileged=true \
  --volume="/path/to/rpmbuild:/rpmbuild" \
  -e MOUNT_POINT="/rpmbuild" \
  -e MOCK_CONFIG="epel-8-aarch64" \
  -e NO_CLEANUP="true" \
  -e SOURCE_RPM="your-package.src.rpm" \
  mmornati/mock-rpmbuilder

# Check logs after
ls /path/to/rpmbuild/output/{MOCK_CONFIG}/
```

## Build Output Location

All outputs go to: `${MOUNT_POINT}/output/${MOCK_CONFIG}/`

| File | Description |
|------|-------------|
| `*.rpm` | Built RPM packages |
| `*.src.rpm` | Source RPM (from spec builds) |
| `build.log` | Mock build log |
| `root.log` | Chroot initialization log |
| `state.log` | Build state log |
| `build-script.sh` | Generated script (deleted after) |
