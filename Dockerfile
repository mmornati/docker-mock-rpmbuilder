FROM centos:centos8.3.2011
LABEL "maintainer"="Marco Mornati <marco@mornati.net>"
LABEL "com.github.actions.name"="RPM Builder"
LABEL "com.github.actions.description"="Build RPM using RedHat Mock"
LABEL "com.github.actions.icon"="pocket"
LABEL "com.github.actions.color"="green"

RUN dnf -y --setopt="tsflags=nodocs" update && \
	dnf -y --setopt="tsflags=nodocs" install epel-release && \
	dnf -y --setopt="tsflags=nodocs" install mock rpm-sign expect && \
	dnf clean all && \
	rm -rf /var/cache/dnf/

#Configure users
RUN useradd -u 1000 -G mock builder && \
	chmod g+w /etc/mock/*.cfg

VOLUME ["/rpmbuild"]

ONBUILD COPY mock /etc/mock

# create mock cache on external volume to speed up build
RUN install -g mock -m 2775 -d /rpmbuild/cache/mock
RUN echo "config_opts['cache_topdir'] = '/rpmbuild/cache/mock'" >> /etc/mock/site-defaults.cfg

ADD ./build-rpm.sh /build-rpm.sh
RUN chmod +x /build-rpm.sh
#RUN setcap cap_sys_admin+ep /usr/sbin/mock
ADD ./rpm-sign.exp /rpm-sign.exp
RUN chmod +x /rpm-sign.exp

CMD ["/build-rpm.sh"]
