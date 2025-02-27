FROM mcr.microsoft.com/devcontainers/base:latest

ARG TARGETARCH
ARG GOLANGVERS="1.24.0"
ARG UROOTVERS="v0.14.0"
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
ENV GOPATH=/home/v9fs-test/go
RUN mkdir -p /home/v9fs-test
RUN chown 1000.1000 /home/v9fs-test
USER 1000:1000
RUN mkdir -p /home/v9fs-test/go
# setup tests
WORKDIR /home/v9fs-test
RUN git clone https://github.com/chaos/diod.git
WORKDIR /home/v9fs-test/diod
RUN ./autogen.sh
RUN ./configure
RUN make
WORKDIR /home/v9fs-test/diod/tests/kern
RUN make check;exit 0
ENV PATH=/home/v9fs-test/go/bin:/usr/local/go/bin:${PATH}
ENV LANG="en_US.UTF-8"
ENV MAKE="/usr/bin/make"
WORKDIR /home/v9fs-test
RUN mkdir -p /home/v9fs-test/.ssh
RUN ssh-keygen -t rsa -q -f "/home/v9fs-test/.ssh/identity" -N ""
RUN git clone -b ${UROOTVERS} https://github.com/u-root/u-root.git
RUN git clone https://github.com/u-root/cpu.git
WORKDIR /home/v9fs-test/u-root
RUN go mod tidy
RUN go build .
RUN go install .
WORKDIR /home/v9fs-test/cpu
WORKDIR /home/v9fs-test/cpu/cmds/cpud
RUN go mod tidy
RUN go build
RUN go install
WORKDIR /home/v9fs-test/cpu/cmds/cpu
RUN go mod tidy
RUN go build
RUN go install
WORKDIR /home/v9fs-test
RUN ["go", "work", "init", "./u-root"]
RUN ["go", "work", "use", "./cpu" ]
RUN ["/home/v9fs-test/go/bin/u-root", "-o", "/home/v9fs-test/initrd.cpio", "-files", "/home/v9fs-test/.ssh/identity.pub:key.pub", "-files", "/mnt", "-initcmd=/bbin/cpud", "$*", "./u-root/cmds/core/{init,gosh}", "./cpu/cmds/cpud"]
ENV LANG="en_US.UTF-8"
ENV MAKE="/usr/bin/make"
WORKDIR /home/v9fs-test
RUN git clone https://github.com/v9fs/vscode
RUN git clone https://github.com/v9fs/test
WORKDIR /workspaces
CMD ["/bin/sh", "-c", "while sleep 1000; do :; done"]
