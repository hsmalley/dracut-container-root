#!/bin/sh
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

[ -z "$root" ] && root=$(getarg root=)

modprobe -q loop
rootok=1

# make sure that init doesn't complain
[ -z "$root" ] && root="tmpfs"
