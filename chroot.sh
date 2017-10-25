#!/bin/bash

#The following environment variables must be set before running the script:
#LFS -> Filesystem mount location

#Ensure LFS is set
if [ ! -v LFS ]; then
	echo 'Filesystem mount location is not set ! Use environment variable LFS to set mount location before launching script.'
	exit 1
fi

#Capture invalid system root
if [ -d $LFS ]; then

	#Virtual kernel filesystems
	read -p 'Mount virtual kernel filesystems (y/n)? ' result
	if [ $result = y ]; then
		sudo mkdir -pv ${LFS}/{dev,proc,sys,run}
		sudo mknod -m 600 ${LFS}/dev/console c 5 1
		sudo mknod -m 666 ${LFS}/dev/null c 1 3
		sudo mount -v --bind /dev ${LFS}/dev
		sudo mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
		sudo mount -vt proc proc $LFS/proc
		sudo mount -vt sysfs sysfs $LFS/sys
		sudo mount -vt tmpfs tmpfs $LFS/run
		if [ -h ${LFS}/dev/shm ]; then
			sudo mkdir -pv ${LFS}$(readlink ${LFS}/dev/shm)
		fi
	fi
	
	select action in "Chroot using temporary tools" "Chroot and install lfs system using temporary tools" "Chroot using lfs system binaries" "Chroot and install blfs system using lfs system system binaries" "Exit"
	do
		if [ "$action" = "Chroot using temporary tools" ]; then
			sudo chroot "$LFS" \
				/tools/bin/env -i \
				HOME=/root \
				TERM="$TERM" \
				PS1='\u@\h:\w\$ ' \
				PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
				/tools/bin/bash --login +h
			break
		elif [ "$action" = "Chroot and install lfs system using temporary tools" ]; then
			sudo rm -rv ${LFS}/alfs
			sudo cp -rv . ${LFS}/alfs
			sudo chroot "$LFS" \
				/tools/bin/env -i \
				HOME=/root \
				TERM="$TERM" \
				PS1='\u@\h:\w\$ ' \
				PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
				/tools/bin/bash --login +h /alfs/lfs-system.sh
			break
		elif [ "$action" = "Chroot using lfs system binaries" ]; then
			sudo chroot "$LFS" \
				/usr/bin/env -i \
				HOME=/root \
				TERM="$TERM" \
				PS1='\u@\h:\w\$ ' \
				PATH=/bin:/usr/bin:/sbin:/usr/sbin \
				/bin/bash --login
			break
		elif [ "$action" = "Chroot and install blfs system using lfs system system binaries" ]; then
			sudo rm -rv ${LFS}/alfs
			sudo cp -rv . ${LFS}/alfs
			if [ ! -d ${LFS}/sources ]; then
				sudo mkdir -v ${LFS}/sources
				sudo chown -v --recursive $(logname): ${LFS}/sources
			fi
			read -p 'Download packages (y/n)? ' result
			if [ $result = y ]; then
				if [ -e blfs-wget-list ] && [ -e blfs-xorg-wget-list ] && [ -e blfs-xfce-wget-list ]; then
					echo 'Downloading packages...'
					wget --input-file=blfs-wget-list --continue --directory-prefix=${LFS}/sources
					wget --input-file=blfs-xorg-wget-list --continue --directory-prefix=${LFS}/sources
					wget --input-file=blfs-xfce-wget-list --continue --directory-prefix=${LFS}/sources
					echo 'Download finished!'
				else echo 'No wget-list files found in current directory!'; fi
			fi
			if [ -e blfs-md5sums ] && [ -e blfs-xorg-md5sums ] && [ -e blfs-xfce-md5sums ]; then
				echo 'Checking downloaded packages...'
				pushd ${LFS}/sources
				md5sum -c $(dirs -l +1)/blfs-*md5sums
				popd
				echo 'Packages check finished!'
				read -p 'Is downloaded packages check successfull (y/n)? ' result
				if [ $result != y ]; then exit 1; fi
			else echo 'No md5sums file found in current directory!'; fi
			sudo chroot "$LFS" \
				/usr/bin/env -i \
				HOME=/root \
				TERM="$TERM" \
				PS1='\u@\h:\w\$ ' \
				PATH=/bin:/usr/bin:/sbin:/usr/sbin \
				/bin/bash --login /alfs/blfs-system.sh
			break
		elif [ "$action" = "Exit" ]; then
			break
		fi
	done
else echo 'Invalid path to system root!'; fi
