[![Build Status](https://travis-ci.org/mmornati/docker-mock-rpmbuilder.svg)](https://travis-ci.org/mmornati/docker-mock-rpmbuilder)

# docker-mock-rpmbuilder
Build RPMs using the Mock Project (for any platform)

## Create working directory

To allow the import/export of created RPMs you need to create a docker volume
and allow the read/write rights (or add owner) to the user builder(uid:1000).

> NOTE: On Mac OSx the `chown` is not needed. Docker it will be able to build directly using your Mac default/admin user.

```bash
mkdir /Users/mmornati/rpmbuild
chown -R 1000:1000 /Users/mmornati/rpmbuild
```
In this folder you can put the src.rpms to rebuild.

This folder will also store mock cache directories that allow to speed up
repeated build

## Build the container locally

First you need to build the container, which we will call
"mmornati/mock-rpmbuilder":

```bash
docker build -t mmornati/mock-rpmbuilder <path to git repo>
```

## Download latest version of the image from Docker Hub

This git repository are actually linked with Docker Hub Automatic build system.
Any new commit here will produce a new version build. You can now simply pull
the latest image build.

```bash
docker pull mmornati/mock-rpmbuilder
```

## Execute the container to build RPMs

To execute the docker container and rebuild RPMs four SRPMs you can run it in
this way:

```bash
docker run --rm --privileged=true \
--volume="/Users/mmornati/rpmbuild:/rpmbuild" -e MOUNT_POINT="/rpmbuild" \
-e MOCK_CONFIG="epel-8-aarch64" \
-e SOURCE_RPM="git-2.3.0-1.el7.centos.src.rpm" mmornati/mock-rpmbuilder
```

If you don't have the source RPMs yet, but you get spec file + sources, to build RPMs you need to start the docker container in this way:

```bash
docker run --rm --privileged=true \
--volume="/Users/mmornati/rpmbuild:/rpmbuild" -e MOUNT_POINT="/rpmbuild" \
-e MOCK_CONFIG="epel-8-aarch64" -e SOURCES="SOURCES/git-2.3.0.tar.gz" \
-e SPEC_FILE="SPECS/git.spec" mmornati/mock-rpmbuilder
```

In case, when sources is not availables, but can be download, just omit the
SOURCE variable, rpmbuild will try to download it before mock build

```bash
docker run --rm --privileged=true \
--volume="/Users/mmornati/rpmbuild:/rpmbuild" -e MOUNT_POINT="/rpmbuild" \
-e MOCK_CONFIG="epel-8-aarch64" -e SPEC_FILE="SPECS/git.spec" \
mmornati/mock-rpmbuilder
```

The below line gives an example of defines configurations. If you have your spec file which takes defines you can configure them in the environment variable as below. The sytax is DEFINE=VALUE it will then be converted to --define 'DEFINE VALUE' instead. You can provide multiple defines by separating them by spaces.

```bash
docker run --rm --privileged=true \
--volume="/Users/mmornati/rpmbuild:/rpmbuild" -e MOUNT_POINT="/rpmbuild" \
-e MOCK_CONFIG="epel-8-aarch64" -e SOURCES="SOURCES/git-2.3.0.tar.gz" \
-e SPEC_FILE="SPECS/git.spec" \
-e MOCK_DEFINES="VERSION=1 RELEASE=12 ANYTHING_ELSE=1" mmornati/mock-rpmbuilder
```

It is important to know:

* With spec file the build process could be long. The reason is that mock is
invoked twice: the first to build SRPM the second to build all other RPMS
* The folders specified for SPEC_FILE, SOURCES and SOURCE_RPM env variables are relative to your mount point. This means if files are at the root of mount point
you need to specify only the file name, otherwise the subfolder should be added
too (See SOURCES in my example)

> NB: It's important to run the container with privileged rights because mock
> needs the "unshare" system call to create a
> new mountpoint inside the process.
> Withour this you will get this error:
>
>  ERROR: Namespace unshare failed.
>
> If the '--cap-add=SYS_ADMIN' is not working for you, you can run the container with the privilaged parameter.
> Replace '--cap-add=SYS_ADMIN' with '--privileged=true'.

## Execute without cleanup of Mock CHROOT folder

To speedup build, as suggested by [llicour](https://github.com/llicour), we can prevent the cleanup of the Mock chroot folder.
We can enable it simply by passing a new parameter (NO_CLEANUP) to the build
command:

```bash
docker run --rm --privileged=true \
--volume="/Users/mmornati/rpmbuild:/rpmbuild" -e MOUNT_POINT="/rpmbuild" \
-e MOCK_CONFIG="epel-8-aarch64" -e NO_CLEANUP="true" \
-e SOURCES="SOURCES/git-2.3.0.tar.gz" -e SPEC_FILE="SPECS/git.spec" \
mmornati/mock-rpmbuilder
```

## Allowed configurations

See at [mock repo](https://github.com/rpm-software-management/mock/tree/main/mock-core-configs/etc/mock)


## Signing your RPMs with GPG Key

If you want you sign your RPMs, you need to pass some extra parameters
* Mount the directory with your gpg private key : -v
$HOME/.gnupg:/home/rpmbuilder/.gnupg:ro
* Set the Signature key you want to use : -e SIGNATURE="Corporate Repo Key"
* Pass the GPG Key passphrase, if needed : -e GPG_PASS="my very secure password"
You can put the passphrase in a file and use GPG_PASS="$(cat $PWD/.gpg_pass)"

```basb
docker run --cap-add=SYS_ADMIN -d -e MOUNT_POINT="/rpmbuild" \
-e MOCK_CONFIG=epel-8-aarch64 -e SOURCE_RPM=git-2.3.0-1.el7.centos.src.rpm \
-v /Users/mmornati/rpmbuild:/rpmbuild -e SIGNATURE="Corporate Repo Key" \
-e GPG_PASS="$(cat $PWD/.gpg_pass)" -v $HOME/.gnupg:/home/builder/.gnupg:ro \
mmornati/mock-rpmbuilder
```

## BETA: Build on GitHub Actions
You can use the Dockerfile to build an RPM for your project. You can follow this sample action:

```
workflow "Build Repo RPM" {
  on = "push"
  resolves = ["Build RPM"]
}

action "Build RPM" {
  uses = "mmornati/docker-mock-rpmbuilder@master"
  env = {
    SPEC_FILE = "git.spec"
    SOURCES = "git-2.3.0.tar.gz"
    MOCK_CONFIG = "epel-8-aarch64"
    MOUNT_POINT = "${GITHUB_WORKSPACE}"
  }
}
```

## Check build state

To check the rpmbuild progress (and/or errors) you can simply check docker logs.

```bash
[root@server docker-mock-rpmbuilder]# docker ps
CONTAINER ID        IMAGE                            COMMAND             CREATED             STATUS              PORTS               NAMES
f8d161e72832        mmornati/mockrpmbuilder:latest   "/build-rpm.sh"     2 seconds ago       Up 1 seconds                            modest_bardeen
[root@server docker-mock-rpmbuilder]# docker logs -f f8d161e72832
=> Building parameters:
========================================================================
      MOCK_CONFIG:    epel-8-aarch64
      SOURCE_RPM:     git-2.3.0-1.el7.centos.src.rpm
========================================================================
INFO: mock.py version 1.2.6 starting (python version = 2.7.5)...
Start: init plugins
INFO: selinux disabled
Finish: init plugins
Start: run
INFO: Start(/rpmbuild/git-2.3.0-1.el7.centos.src.rpm)  Config(epel-8-aarch64)
Start: clean chroot
Finish: clean chroot
Start: chroot init
INFO: calling preinit hooks
INFO: enabled root cache
INFO: enabled yum cache
Start: cleaning yum metadata
Finish: cleaning yum metadata
INFO: enabled ccache
Mock Version: 1.2.6
INFO: Mock Version: 1.2.6
Start: yum install
[....]
```

And use Mock log files, that are created in the outputdir:

```bash
[root@server ~]# ll /Users/mmornati/rpmbuild/rpmbuild/output/
totale 188
-rw-rw-r--. 1 1000 1000  40795 21 feb 10:37 build.log
-rw-rw-r--. 1 1000 1000 144994 21 feb 10:34 root.log
-rw-rw-r--. 1 1000 1000    962 21 feb 10:34 state.log
```

## Output

If all worked well, you should have all the RPMs (source + binaries) availables
in the configured output folder:

```bash
[root@server ~]# ll /Users/mmornati/rpmbuild/output/
totale 28076
-rw-rw-r--. 1 1000 1000   117010 21 feb 10:40 build.log
-rw-rw-r--. 1 1000 mock  7941092 21 feb 10:39 git-2.3.0-1.el6.i686.rpm
-rw-rw-r--. 1 1000 mock  5193722 21 feb 10:33 git-2.3.0-1.el6.src.rpm
-rw-rw-r--. 1 1000 mock     5472 21 feb 10:39 git-all-2.3.0-1.el6.i686.rpm
-rw-rw-r--. 1 1000 mock    24540 21 feb 10:39 git-arch-2.3.0-1.el6.i686.rpm
-rw-rw-r--. 1 1000 mock    90668 21 feb 10:39 git-cvs-2.3.0-1.el6.i686.rpm
-rw-rw-r--. 1 1000 mock 14123468 21 feb 10:40 git-debuginfo-2.3.0-1.el6.i686.rpm
-rw-rw-r--. 1 1000 mock    37600 21 feb 10:39 git-email-2.3.0-1.el6.i686.rpm
-rw-rw-r--. 1 1000 mock   240400 21 feb 10:39 git-gui-2.3.0-1.el6.i686.rpm
-rw-rw-r--. 1 1000 mock   148940 21 feb 10:39 gitk-2.3.0-1.el6.i686.rpm
-rw-rw-r--. 1 1000 mock   437148 21 feb 10:39 git-svn-2.3.0-1.el6.i686.rpm
-rw-rw-r--. 1 1000 mock   145996 21 feb 10:39 gitweb-2.3.0-1.el6.i686.rpm
-rw-rw-r--. 1 1000 mock    67256 21 feb 10:39 perl-Git-2.3.0-1.el6.i686.rpm
-rw-rw-r--. 1 1000 1000   147267 21 feb 10:40 root.log
-rw-rw-r--. 1 1000 1000     1248 21 feb 10:40 state.log
```

## Contributions
Updated and fixed with contributions by [csmart](https://github.com/csmart/docker-mock-rpmbuilder/commit/c3f47343efd4484131af5fd254f3e51cb7414a78) and
[llicour](https://github.com/llicour/docker-mock-rpmbuilder/commit/6a5b169860b3b42f10a7c7771d1342dd7c78359b)

## Docker HUB
This repository is automatically linked to Docker Hub
[https://hub.docker.com/r/mmornati/mock-rpmbuilder/](https://hub.docker.com/r/mmornati/mock-rpmbuilder/).

Any new commit and contribution will automatically force a build on DockerHub to have the latest version of the container ready to use.
