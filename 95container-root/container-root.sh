#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh

command -v unpack_archive >/dev/null || . /lib/img-lib.sh

command -v fetch_url >/dev/null || . /lib/url-lib.sh

[ -e /lib/nfs-lib.sh ] && . /lib/nfs-lib.sh

PATH=/usr/sbin:/usr/bin:/sbin:/bin

rootfs=$(getarg rd.container.rootfs)
rootfs_filename=$(basename "$rootfs")
tmpfs_size=$(getarg rd.tmpfs.size)
download_tmpfs="/run/initramfs/tmp"

mkdir -m 0755 -p "$download_tmpfs"

info "Mounting download tmpfs"
mount -t tmpfs -o size="$tmpfs_size" tmpfs "$download_tmpfs"
if [ "$?" != "0" ]; then
  die "Failed to mount tmpfs root"
  exit 1
fi

info "Downloading Image"
fetch_url "$rootfs" "$download_tmpfs"
if [ "$?" != "0" ]; then
  die "Failed to download image"
  exit 1
fi

info "Mounting rootfs tmpfs"
mount -t tmpfs -o size="$tmpfs_size" tmpfs "$NEWROOT"
if [ "$?" != "0" ]; then
  die "Failed to mount tmpfs root"
  exit 1
fi

info "Unpacking archive to tmpfs root"
tar axpf /run/initramfs/tmp/"$rootfs_filename" -C "$NEWROOT" && umount "$download_tmpfs"
if [ "$?" != "0" ]; then
  die "Failed to extract rootfs"
  exit 1
fi
