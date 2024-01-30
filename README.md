# dracut-container-root

Dracut Module to boot OCI containers

> [!caution]
> This is very much a work in progress and a damn dirty hack. It shouldn't be used by anyone, it's not really a sane thing to do, but YMMV...
> However there are some good reasons why you would want to load a container into memory and boot it.
> Like when you don't want to install an OS and just need the bare amount of OS to run your application.
> For example, super computing clusters.

---

## What / Why

This is inspired by a few things I've worked on over the years, NFS dracut module, warewulf apptainers, and [dracut-tmpfs-root](https://github.com/wutcat/dracut-tmpfs-root)

This will download an OCI container eg LXC rootfs, extract it to tmpfs and pviot to it. The idea is to download your custom rootfs, configure things with cloud-init, and start your application(s). As long as it's an OCI container you should be able to boot it. Obviously the kernel you use to boot it needs to compatible too. For example if you want to selinux then you need to use a kernel to boot the system that supports it eg fedora, rocky, etc. So in general you'll want to avoid booting ubuntu or alpine with a fedora kernel...

---

## POC

Building a unified efi kernel on fedora and booting rocky lxc rootfs:

```shell
sudo dracut -v -a container-root --uefi --early-microcode --no-hostonly --enhanced-cpio --kernel-cmdline 'rd.shell=1 ip=dhcp rd.neednet=1 rd.tmpfs.size=3G rd.container.rootfs=https://dl.rockylinux.org/pub/rocky/8/images/x86_64/Rocky-8-Container-Base.latest.x86_64.tar.xz' -f ~/test.efi

```

This will download the container rootfs, however since it doesn't have the kernel modules it will not full boot, it does pivot though. So we'll need to give that a little more love.

---

## A little more love

So let's create a quick _bootable_ container.

```shell
sudo dracut -v -a container-root --uefi --early-microcode --no-hostonly --enhanced-cpio --kernel-cmdline 'rd.shell=1 ip=dhcp rd.neednet=1 rd.tmpfs.size=6G selinux=0 rd.container.rootfs=http://10.10.10.10:8000/rootfs_custom.tar.xz -f ~/test.efi
```

That will make the efi file, now let's grab the files, build the tar file, and serve the file via http

```shell
cd $HOME/Public
aria2c https://jenkins.linuxcontainers.org/view/Images/job/image-fedora/architecture=amd64,release=39,variant=default/lastSuccessfulBuild/artifact/rootfs.tar.xz
sudo mkdir rootfs
sudo tar axpf rootfs.tar.xz -C rootfs/
sudo dnf --installroot=$HOME/Public/rootfs install kernel-modules kernel-modules-extra cloud-init -y
cd rootfs
sudo tar acpf ../rootfs_custom.tar.xz .
cd ..
sudo chmod a+r *.xz
python -m http.server
```

This will allow your container to boot, paired this with cloud-init this will get you a completely bootable cloud-init enabled lxc container running in memory on bare metal
