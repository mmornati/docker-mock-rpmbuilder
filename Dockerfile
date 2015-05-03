FROM centos:centos7
MAINTAINER Marco Mornati <marco@mornati.net>

RUN rpm -ivh http://fr2.rpmfind.net/linux/epel/7/x86_64/e/epel-release-7-5.noarch.rpm

RUN yum clean all
RUN yum -y update

#Install Mock Package
RUN yum -y install mock 

#Configure users
RUN useradd -u 1000 builder
RUN usermod -a -G mock builder

VOLUME ["/rpmbuild"]

# create mock cache on external volume to speed up build
RUN install -g mock -m 2775 -d /rpmbuild/cache/mock
RUN echo "config_opts['cache_topdir'] = '/rpmbuild/cache/mock'" >> /etc/mock/site-defaults.cfg

ADD ./build-rpm.sh /build-rpm.sh
RUN chmod +x /build-rpm.sh
#RUN setcap cap_sys_admin+ep /usr/sbin/mock

USER builder
ENV HOME /home/builder
CMD ["/build-rpm.sh"]
