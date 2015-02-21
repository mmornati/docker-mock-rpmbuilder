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
docker run -d -e MOCK_CONFIG=epel-6-i386 -e SOURCE_RPM=git-2.3.0-1.el7.centos.src.rpm -v /tmp/rpmbuild:/rpmbuild mmornati/mockrpmbuilder --privileged=true
```

> NB: It's important to run the container with privileged rights because mock needs the "unshare" system call to create a
> new mountpoint inside the process.
> Withour this you will get this error:
>  ERROR: Namespace unshare failed.
> A different solution (which didn't worked for me right now) should be to change the lxc-configuration to allow docker the right admin just for this operation.
> With this command: setcap cap_sys_admin+ep
> But I didn't find the right way to execute it (any hint is welcome) :)

## TODOs

* Fix right problem (to execute container without root privileges)
* Improve build script to allow the build of spec+sources
