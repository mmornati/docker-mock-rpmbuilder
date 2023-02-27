FROM fedora:latest
LABEL "maintainer"="Marco Mornati <marco@mornati.net>"
LABEL "com.github.actions.name"="RPM Builder"
LABEL "com.github.actions.description"="Build RPM using RedHat Mock"
LABEL "com.github.actions.icon"="pocket"
LABEL "com.github.actions.color"="green"

RUN dnf -y --setopt="tsflags=nodocs" update && \
	dnf -y --setopt="tsflags=nodocs" install rpmdevtools mock \
	qemu-user-static-x86 qemu-user-static-aarch64 rpm-sign expect && \
	dnf clean all && rm -rf "/var/cache/dnf"

RUN useradd mockbuilder && \
    usermod -a -G mock mockbuilder && \
    chmod g+w /etc/mock/*.cfg

ONBUILD COPY mock /etc/mock

COPY ./build-rpm.sh /build-rpm.sh
RUN chmod +x /build-rpm.sh
COPY ./rpm-sign.exp /rpm-sign.exp
RUN chmod +x /rpm-sign.exp

CMD ["/build-rpm.sh"]
