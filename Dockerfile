FROM mcr.microsoft.com/devcontainers/base:latest

ARG TARGETARCH
ARG GOLANGVERS="1.26.2"
ARG UROOTVERS="v0.16.0"
ARG CPUVERS="32363d29d8100d0b938b4f7099bd21260d69b1bd"
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y eatmydata && \
    eatmydata apt-get dist-upgrade -y && \
    eatmydata apt-get install --no-install-recommends -y \
	gcc \
	gdb \
	libvirt-clients \
	build-essential bc fakeroot dwarves \
	libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf llvm \
        qemu-system ca-certificates git-core openssh-client \
        libpopt-dev ncurses-dev automake autoconf git pkgconf \
        lua5.1 liblua5.1-dev libmunge-dev libwrap0-dev libcap-dev libattr1-dev \
        time \
	mutt \
	pip \
	b4 \
	vim pinentry-tty libsasl2-modules \
	diod \
	bonnie++ \
        && \
    eatmydata apt-get autoremove -y && \
    eatmydata apt-get autoclean -y && \
    sed -Ei 's,^# (en_US\.UTF-8 .*)$,\1,' /etc/locale.gen && \
    dpkg-reconfigure locales && \
    dpkg-query --showformat '${Package}_${Version}_${Architecture}\n' --show > /packages.txt

RUN mkdir -p /mnt/9
RUN mkdir -p /mnt/root
WORKDIR /usr/local/bin
RUN ln -s /usr/bin/pinentry-tty
RUN mkdir -p /workspaces
RUN chown 1000.1000 /workspaces
WORKDIR /tmp
RUN if [ `uname -m` = "aarch64" ]; then \
	export TARGETGOARCH="arm64"; \
    else \
	export TARGETGOARCH="amd64"; \
    fi; \
    wget https://go.dev/dl/go${GOLANGVERS}.linux-${TARGETGOARCH}.tar.gz; \
    tar xf go*.tar.gz;rm go*.tar.gz;mv go /usr/local
ENV GOROOT=/usr/local/go
ENV V9FS_ROOT=/opt/v9fs
ENV GOPATH=/opt/v9fs/go
RUN install -d -m 0777 /opt/v9fs
USER 1000:1000
RUN mkdir -p /opt/v9fs/go
ENV PATH=/opt/v9fs/go/bin:/usr/local/go/bin:${PATH}
ENV LANG="en_US.UTF-8"
ENV MAKE="/usr/bin/make"
WORKDIR /opt/v9fs
RUN mkdir -p /opt/v9fs/.ssh
RUN ssh-keygen -t rsa -q -f "/opt/v9fs/.ssh/identity" -N ""
RUN go install github.com/u-root/u-root@${UROOTVERS}
RUN go install github.com/u-root/cpu/cmds/cpud@${CPUVERS}
RUN go install github.com/u-root/cpu/cmds/cpu@${CPUVERS}
RUN export UROOT_DIR="$(go list -f '{{.Dir}}' -m github.com/u-root/u-root@${UROOTVERS})" && \
    export CPU_DIR="$(go list -f '{{.Dir}}' -m github.com/u-root/cpu@${CPUVERS})" && \
    mkdir -p /opt/v9fs/uimage-ws && \
    cd /opt/v9fs/uimage-ws && \
    go work init "${UROOT_DIR}" "${CPU_DIR}" && \
    GOWORK=/opt/v9fs/uimage-ws/go.work /opt/v9fs/go/bin/u-root \
      -o /opt/v9fs/initrd.cpio \
      -files /opt/v9fs/.ssh/identity.pub:key.pub \
      -files /mnt \
      -initcmd=/bbin/cpud \
      "$*" \
      github.com/u-root/u-root/cmds/core/{init,gosh} \
      github.com/u-root/cpu/cmds/cpud
ENV LANG="en_US.UTF-8"
ENV MAKE="/usr/bin/make"