FROM centos:centos7
MAINTAINER Marco Mornati <marco@mornati.net>

RUN rpm -ivh http://mir01.syntis.net/epel/7/x86_64/e/epel-release-7-5.noarch.rpm 

RUN yum clean all
RUN yum -y update

#Install Mock Package
RUN yum -y install mock 

#Configure users
RUN useradd builder
RUN usermod -a -G mock builder

VOLUME ["/rpmbuild"]

ADD ./build-rpm.sh /build-rpm.sh
RUN chmod +x /build-rpm.sh

USER builder
ENV HOME /home/builder
ENV PATH /usr/bin:$PATH
CMD ["/build-rpm.sh"]
