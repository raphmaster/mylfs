#!/bin/bash

#The following environment variables must be set before running the script:
#STEP -> Starting step

#Ensure STEP is set
if [ ! -v STEP ]; then
	echo 'Starting step is not set ! Use environment variable STEP to set starting step before launching script.'
	exit 1
fi

#Recover device
if [ $STEP -ge 0 ] && [ $STEP -lt 4 ]; then
	read -p 'Please enter device : ' device
fi

#Make partiton table
if [ $STEP -eq 0 ]; then
	if sudo parted $device mktable; then let "STEP++"; else echo 'Making partition table failed!'; fi
fi

#Make partition
if [ $STEP -eq 1 ]; then
	echo 'Making root partition...'
	if sudo parted $device mkpart; then
		sudo parted $device set 1 boot on
		read -p 'Do you want to create a swap partition? (y/n) ' result
		if [ $result = y ]; then 
			echo 'Making swap partition...'
			read -p 'Please enter swap label : ' label
			if sudo parted $device mkpart $label linux-swap; then
				sudo mkswap -L $label ${device}2
				let "STEP++"
			else echo 'Making swap partition failed!'; fi
		else let "STEP++"; fi
	else echo 'Making root partition failed'; fi
fi

#Make filesystem
if [ $STEP -eq 2 ]; then
	read -p 'Please enter filesystem type: ' type
	read -p 'Please enter new volume label: ' label
	if sudo mkfs -t $type -L $label ${device}1; then let "STEP++"; else echo 'Making new filesystem failed!'; fi
fi

#Mount device partition
if [ $STEP -eq 3 ]; then
	read -p 'Mount root partition (y/n) ? ' result
	if [ $result = y ]; then
		read -p 'Enter mount location : ' location
		#Create mount directory if it does not exist
		if [ ! -d $location ]; then sudo mkdir -pv $location; fi
		sudo mount ${device}1 $location
	fi
fi