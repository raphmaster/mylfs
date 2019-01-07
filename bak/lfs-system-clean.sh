#!/bin/bash

#The script must NOT be run in a chroot environment

#The following environment variable must be set to run the script :
#LFS -> Filesystem mount location

#Enable extended pattern matching feature
shopt -s extglob

#Ensure LFS is set
if [ ! -v LFS ]; then
	echo 'Filesystem mount location is not set ! Use environment variable LFS to set mount location before launching script.'
	exit 1
fi

#Ensure LFS directory exists
if [ -d $LFS ]; then
	#Unmount virtual kernel filesystems
	read -p 'Unmount virtual kernel filesystems (y/n) ? ' result
	if [ $result = y ]; then
		sudo umount -v ${LFS}/dev/pts
		sudo umount -v ${LFS}/proc
		sudo umount -v ${LFS}/sys
		sudo umount -v ${LFS}/run
		sudo umount -v ${LFS}/dev
	fi

	#Backup
	read -p 'Backup LFS system (y/n) ? ' result
	if [ $result = y ]; then
		read -p 'Enter backup location : ' location
		if [ -d $location ]; then cd $LFS; sudo tar -Jcvf ${location}/lfs.tar.xz !(sources|tools)
		else echo 'Invalid backup location!'; fi
	fi

	#Stripping
	read -p 'Strip binaries and libraries (y/n) ? ' result
	if [ $result = y ]; then sudo find ${LFS}/{,usr/}{bin,lib,sbin} -type f -exec strip --strip-unneeded {} ;; fi

	#Cleaning
	sudo rm -rvf ${LFS}/tmp/*
	sudo rm -rvf ${LFS}/alfs
	sudo rm -rvf ${LFS}/tools
	sudo rm -vf ${LFS}/usr/lib/lib{bfd,opcodes}.a
	sudo rm -vf ${LFS}/usr/lib/libbz2.a
	sudo rm -vf ${LFS}/usr/lib/lib{com_err,e2p,ext2fs,ss}.a
	sudo rm -vf ${LFS}/usr/lib/libltdl.a
	sudo rm -vf ${LFS}/usr/lib/libfl.a
	sudo rm -vf ${LFS}/usr/lib/libfl_pic.a
	sudo rm -vf ${LFS}/usr/lib/libz.a
	sudo find ${LFS}/lib ${LFS}/usr/lib -not -path "*Image*" -a -name \*.la -delete

else echo 'Invalid mount location!'; fi