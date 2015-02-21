# docker-mock-rpmbuilder
Build RPMs using the Mock Project (for any platform)

## Create working directory

To allow the import/export of created RPMs you need to create a docker volume and allow the read/write rights (or add owner) to the user builder(uid:1000).

```bash
mkdir /tmp/rpmbuild
chown -R 1000:1000 /tmp/rpmbuild
```
In this folder you can put the src.rpms to rebuild.

## Execute the container to rebuild packages

To execute the docker container you can run it in this way:

```bash
docker run -d -e MOCK_CONFIG=epel-6-i386 -e SOURCE_RPM=git-2.3.0-1.el7.centos.src.rpm -v /tmp/rpmbuild:/rpmbuild --privileged=true mmornati/mockrpmbuilder
```

> NB: It's important to run the container with privileged rights because mock needs the "unshare" system call to create a
> new mountpoint inside the process.
> Withour this you will get this error:
>
>  ERROR: Namespace unshare failed.
>
> A different solution (which didn't worked for me right now) should be to change the lxc-configuration to allow docker the right admin just for this operation.
> With this command: setcap cap_sys_admin+ep
> But I didn't find the right way to execute it (any hint is welcome) :)

## Allowed configurations

```
default        epel-7-x86_64     fedora-19-x86_64  fedora-20-x86_64   fedora-21-s390x         fedora-rawhide-s390
epel-5-i386    fedora-19-armhfp  fedora-20-armhfp  fedora-21-aarch64  fedora-21-x86_64        fedora-rawhide-s390x
epel-5-ppc     fedora-19-i386    fedora-20-i386    fedora-21-armhfp   fedora-rawhide-aarch64  fedora-rawhide-sparc
epel-5-x86_64  fedora-19-ppc64   fedora-20-ppc64   fedora-21-i386     fedora-rawhide-armhfp   fedora-rawhide-x86_64
epel-6-i386    fedora-19-ppc     fedora-20-ppc     fedora-21-ppc64    fedora-rawhide-i386     logging.ini
epel-6-ppc64   fedora-19-s390    fedora-20-s390    fedora-21-ppc64le  fedora-rawhide-ppc64    site-defaults
epel-6-x86_64  fedora-19-s390x   fedora-20-s390x   fedora-21-s390     fedora-rawhide-ppc64le
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
      MOCK_CONFIG:    epel-6-i386
      SOURCE_RPM:     git-2.3.0-1.el7.centos.src.rpm
========================================================================
INFO: mock.py version 1.2.6 starting (python version = 2.7.5)...
Start: init plugins
INFO: selinux disabled
Finish: init plugins
Start: run
INFO: Start(/rpmbuild/git-2.3.0-1.el7.centos.src.rpm)  Config(epel-6-i386)
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
[root@server ~]# ll /tmp/rpmbuild/output/
totale 188
-rw-rw-r--. 1 1000 1000  40795 21 feb 10:37 build.log
-rw-rw-r--. 1 1000 1000 144994 21 feb 10:34 root.log
-rw-rw-r--. 1 1000 1000    962 21 feb 10:34 state.log
```

## Output

If all worked well, you should have all the RPMs (source + binaries) availables in the configured output folder:

```bash
[root@server ~]# ll /tmp/rpmbuild/output/
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

## TODOs

* Fix right problem (to execute container without root privileges)
* Improve build script to allow the build of spec+sources
