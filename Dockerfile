
FROM ubuntu:jammy

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y eatmydata && \
    eatmydata apt-get dist-upgrade -y && \
    eatmydata apt-get install --no-install-recommends -y \
        ccache \
		gcc \
        gdb \
        libvirt-clients \
		build-essential bc fakeroot linux-tools-generic dwarves \
        libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf llvm \
        qemu-system-x86 ca-certificates git-core openssh-client \
        libpopt-dev ncurses-dev automake autoconf git pkgconf \
        lua5.1 liblua5.1-dev libmunge-dev libwrap0-dev libcap-dev libattr1-dev \
        && \
    eatmydata apt-get autoremove -y && \
    eatmydata apt-get autoclean -y
ADD qemu.bash /root/qemu.bash
WORKDIR /root
RUN git clone https://github.com/chaos/diod.git
WORKDIR /root/diod
RUN ./autogen.sh
RUN ./configure
RUN make
WORKDIR /root
ADD https://go.dev/dl/go1.19.linux-amd64.tar.gz /root
RUN tar xf go*.tar.gz
ENV GOPATH /root/go
ENV PATH /root/go/bin:${PATH}
RUN go install github.com/u-root/cpu/cmds/cpu@latest
ENV LANG "en_US.UTF-8"
ENV MAKE "/usr/bin/make"
WORKDIR /root
RUN ssh-keygen -t rsa -q -f "/root/.ssh/id_rsa" -N ""
RUN git clone https://github.com/u-root/u-root.git
RUN git clone https://github.com/u-root/cpu.git
WORKDIR /root/u-root
RUN go build .
RUN go install .
WORKDIR /root/cpu
RUN /root/go/bin/u-root -files /root/.ssh/id_rsa.pub:key.pub -files /mnt -uroot-source /root/u-root -initcmd=/bbin/cpud $* core cmds/cpud cmds/cpu