cd #!/bin/bash

# ^a+x to terminate

export QEMU="qemu-system-x86_64"
export KERNEL="v9fs/arch/x86_64/boot/bzImage"
export INITRD="/tmp/initramfs.linux_amd64.cpio"

${QEMU} -kernel \
    ${KERNEL} \
	-cpu  max \
    -s   \
    -smp 4 \
    -m 8192m \
    -machine q35  \
    -initrd ${INITRD} \
    -object rng-random,filename=/dev/urandom,id=rng0 \
    -device virtio-rng-pci,rng=rng0 \
    -device virtio-net-pci,netdev=n1 \
    -netdev user,id=n1,hostfwd=tcp:127.0.0.1:17010-:17010,net=192.168.1.0/24,host=192.168.1.1 \
    -serial mon:stdio -nographic \
    -debugcon file:debug.log -global isa-debugcon.iobase=0x402 \
    -fsdev local,security_model=passthrough,id=fsdev0,path=/tmp \
    -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare \
    -append "console=ttyS0"
