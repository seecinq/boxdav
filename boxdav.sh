#!/usr/bin/env bash
#
# Copyright (c) 2012, Box, Inc.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# * Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

usage()
{
	cat << USAGE
boxdav mounts your Box account via WebDAV
on a Linux machine.

Mount usage:   sudo $0 [-b user@example.com]
Unmount usage: sudo $0 -u [-b user@example.com]

The mount point will be: /boxdav/user@example.com
(Where user@example.com is your Box account.)

If the -b flag is not given, you will be prompted
to supply your Box login (email address).

NOTE: boxdav depends on davfs2 (http://savannah.nongnu.org/projects/davfs2).
You must install davfs2 before running boxdav.
USAGE
	exit 1
}

unset box_account
declare -i umount=0

while getopts "hub:" option; do
	case $option in
		h) usage ;;
		u) umount=1 ;;
		b) box_account=$OPTARG ;;
	esac
done

if [[ -z "${SUDO_USER}" || "${SUDO_USER}" = 'root' ]] ; then
	echo 'ERROR must run via sudo'
	usage
fi

mount_box()
{
	box_account=$1
	mkdir -p /mnt/boxdav/${box_account}
	if (( $? != 0 )) ; then
		echo "ERROR creating /mnt/boxdav/${box_account}"
		exit 1
	fi
	echo -n "${box_account}"
	stty -echo
	mount -t davfs https://dav.box.com/dav /mnt/boxdav/${box_account} -o rw,username=${box_account},uid=$SUDO_USER,gid=$SUDO_USER,file_mode=0600,dir_mode=0700,nodev,nosuid,noexec
	mount_return=$?
	stty echo
	if (( $mount_return != 0 )) ; then
		echo "ERROR mounting /mnt/boxdav/${box_account}"
		exit 1
	else
		echo
		echo "SUCCESS mounted /mnt/boxdav/${box_account}"
		echo "To unmount it, run sudo $0 -u -b ${box_account}"
	fi
}

umount_box()
{
	box_account=$1
	mount=$(awk '$1=="https://dav.box.com/dav" {print $2}' /proc/mounts | grep ^"/mnt/boxdav/${box_account}"$ | head -1)
	if [[ "/mnt/boxdav/${box_account}" = "${mount}" && -d "${mount}" ]] ; then
		echo "Unmounting ${mount}"
		umount "/mnt/boxdav/${box_account}"
		if (( $? != 0 )) ; then
			echo "ERROR unmounting /mnt/boxdav/${box_account}"
			exit 1
		else
			echo "SUCCESS unmounted /mnt/boxdav/${box_account}"
			rmdir --ignore-fail-on-non-empty "/mnt/boxdav/${box_account}"
		fi
	else
		echo "/mnt/boxdav/${box_account} not found"
		exit 1
	fi
}

if [[ -z "${box_account}" ]] ; then
	echo -n 'Box login: '
	read box_account
	if [[ -z "${box_account}" ]] ; then
		usage
	fi
fi

if (( $umount == 1 )) ; then
	umount_box "${box_account}"
else
	mount_box "${box_account}"
fi
