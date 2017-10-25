#!/bin/bash

#The following environment variables must be set before running the script:
#STEP -> Starting step
#LFS -> Filesystem mount location
#JOBS -> Maximum simultaneous make jobs

#Ensure STEP is set
if [ ! -v STEP ]; then
	echo 'Starting step is not set ! Use environment variable STEP to set starting step before launching script.'
	exit 1
fi

#Ensure LFS is set
if [ ! -v LFS ]; then
	echo 'Filesystem mount location is not set ! Use environment variable LFS to set mount location before launching script.'
	exit 1
fi

#Ensure JOBS is set
if [ ! -v JOBS ]; then
	echo 'Maximum simultaneous make jobs is not set ! Use environment variable JOBS to set max make jobs before launching script.'
	exit 1
fi

#Version check of required tools
if [ $STEP -eq 0 ]; then
	if [ -e version-check.sh ]; then 
		./version-check.sh
		read -p 'Is version check successful (no missing tools, versions greater than or equal requirements and symbolic links pointing to the right place) (y/n)? ' result
		if [ $result = y ]; then let "STEP++"; fi
	else echo 'No version-check.sh script file found in current directory!'; fi
fi

#Download packages
if [ $STEP -eq 1 ]; then
	#If sources directory does not exist, create it
	if [ ! -d ${LFS}/sources ]; then sudo mkdir -v ${LFS}/sources; fi
	sudo chown -v --recursive $(logname): ${LFS}/sources
	if [ -e lfs-wget-list ]; then
		echo 'Downloading packages...'
		wget --input-file=lfs-wget-list --continue --directory-prefix=${LFS}/sources
		let "STEP++"
		echo 'Download finished!'
	else echo 'No wget-list file found in current directory!'; fi
fi

#Packages md5 check
if [ $STEP -eq 2 ]; then
	if [ -e lfs-md5sums ]; then
		echo 'Checking downloaded packages...'
		pushd ${LFS}/sources
		md5sum -c $(dirs -l +1)/lfs-md5sums
		popd
		echo 'Packages check finished!'
		read -p 'Is downloaded packages check successfull (y/n)? ' result
		if [ $result = y ]; then let "STEP++"; fi
	else echo 'No md5sums file found in current directory!'; fi
fi

#Final environment set up
if [ $STEP -ge 3 ] && [ $STEP -lt 36 ]; then
	#Create tools directory and symbolic link at root
	if [ ! -d ${LFS}/tools ]; then sudo mkdir -v ${LFS}/tools; fi
	sudo chown -v --recursive $(logname): ${LFS}/tools
	if [ ! -L /tools ]; then sudo ln -sv ${LFS}/tools /; fi
	#TODO: create new environment 
	#exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' STEP=$STEP LFS=$LFS JOBS=$JOBS /bin/bash --norc
	#Shell will always search in PATH when a program is to be run
	set +h
	#Control localization of certain program
	LC_ALL=POSIX
	#Machine description when compiling
	LFS_TGT=$(uname -m)-lfs-linux-gnu
	#New compiled tools will be searched before old ones
	PATH=/tools/bin:$PATH
	export LC_ALL PATH
fi

#binutils-2.26 Pass 1
if [ $STEP -eq 3 ]; then
	cd ${LFS}/sources
	tar -xvf binutils-2.26.tar.bz2
	cd binutils-2.26
	mkdir -v build
	cd build
	../configure --prefix=/tools --with-sysroot=$LFS --with-lib-path=/tools/lib --target=$LFS_TGT --disable-nls --disable-werror
	make -j $JOBS
	if [ ! -d /tools/lib ]; then mkdir -v /tools/lib; fi
	if [ ! -L /tools/lib64 ]; then ln -sv lib /tools/lib64; fi
	make -j $JOBS install
	cd ../..
	rm -rvf binutils-2.26
	let "STEP++"
fi

#gcc-5.3.0 Pass 1
if [ $STEP -eq 4 ]; then
	cd ${LFS}/sources
	tar -xvf gcc-5.3.0.tar.bz2
	cd gcc-5.3.0
	tar -xvf ../mpfr-3.1.3.tar.xz
	mv -v mpfr-3.1.3 mpfr
	tar -xvf ../gmp-6.1.0.tar.xz
	mv -v gmp-6.1.0 gmp
	tar -xvf ../mpc-1.0.3.tar.gz
	mv -v mpc-1.0.3 mpc
	for file in $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
	do
		cp -uv $file{,.orig}
		sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' -e 's@/usr@/tools@g' $file.orig > $file
		echo '
		#undef STANDARD_STARTFILE_PREFIX_1
		#undef STANDARD_STARTFILE_PREFIX_2
		#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
		#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
		touch $file.orig
	done
	mkdir -v build
	cd build
	../configure \
		--target=$LFS_TGT \
		--prefix=/tools \
		--with-glibc-version=2.11 \
		--with-sysroot=$LFS \
		--with-newlib \
		--without-headers \
		--with-local-prefix=/tools \
		--with-native-system-header-dir=/tools/include \
		--disable-nls \
		--disable-shared \
		--disable-multilib \
		--disable-decimal-float \
		--disable-threads \
		--disable-libatomic \
		--disable-libgomp \
		--disable-libquadmath \
		--disable-libssp \
		--disable-libvtv \
		--disable-libstdcxx \
		--enable-languages=c,c++
	make -j $JOBS
	make -j $JOBS install
	cd ../..
	rm -rvf gcc-5.3.0
	let "STEP++"
fi

#linux-4.5 API Headers
if [ $STEP -eq 5 ]; then
	cd ${LFS}/sources
	tar -xvf linux-libre-4.5-gnu.tar.xz
	cd linux-4.5
	make -j $JOBS mrproper
	make -j $JOBS INSTALL_HDR_PATH=dest headers_install
	cp -rv dest/include/* /tools/include
	cd ..
	rm -rvf linux-4.5
	let "STEP++"
fi

#glibc-2.23
if [ $STEP -eq 6 ]; then
	cd ${LFS}/sources
	tar -xvf glibc-2.23.tar.xz
	cd glibc-2.23
	patch -Np1 -i ../glibc-2.23-upstream_i386_fix-1.patch
	mkdir -v build
	cd build
	../configure \
		--prefix=/tools \
		--host=$LFS_TGT \
		--build=$(../scripts/config.guess) \
		--disable-profile \
		--enable-kernel=2.6.32 \
		--enable-obsolete-rpc \
		--with-headers=/tools/include \
		libc_cv_forced_unwind=yes \
		libc_cv_ctors_header=yes \
		libc_cv_c_cleanup=yes
	make -j1
	make -j1 install
	cd ../..
	rm -rvf glibc-2.23
	#Compile and link test
	echo 'int main(){}' > dummy.c
	${LFS_TGT}-gcc dummy.c
	readelf -l a.out | grep ': /tools'
	read -p 'Is the above line of the form [Requesting program interpreter: /tools/lib64/ld-linux-x86-64.so.2] (y/n)? ' result
	if [ $result = y ]; then let "STEP++"
	else echo 'Compilation and linking test fails! Automated sequence aborted!'; fi
	rm -vf dummy.c a.out
fi

#libstdc++-5.3.0
if [ $STEP -eq 7 ]; then
	cd ${LFS}/sources
	tar -xvf gcc-5.3.0.tar.bz2
	cd gcc-5.3.0
	mkdir -v build
	cd build
	../libstdc++-v3/configure \
		--host=$LFS_TGT \
		--prefix=/tools \
		--disable-multilib \
		--disable-nls \
		--disable-libstdcxx-threads \
		--disable-libstdcxx-pch \
		--with-gxx-include-dir=/tools/${LFS_TGT}/include/c++/5.3.0
	make -j $JOBS
	make -j $JOBS install
	cd ../..
	rm -rvf gcc-5.3.0
	let "STEP++"
fi

#binutils-2.26 Pass 2
if [ $STEP -eq 8 ]; then
	cd ${LFS}/sources
	tar -xvf binutils-2.26.tar.bz2
	cd binutils-2.26
	mkdir -v build
	cd build
	CC=${LFS_TGT}-gcc \
	AR=${LFS_TGT}-ar \
	RANLIB=${LFS_TGT}-ranlib \
	../configure \
		--prefix=/tools \
		--disable-nls \
		--disable-werror \
		--with-lib-path=/tools/lib \
		--with-sysroot
	make -j $JOBS
	make -j $JOBS install
	make -j $JOBS -C ld clean
	make -j $JOBS -C ld LIB_PATH=/usr/lib:/lib
	cp -v ld/ld-new /tools/bin
	cd ../..
	rm -rvf binutils-2.26
	let "STEP++"
fi

#gcc-5.3.0 Pass 2
if [ $STEP -eq 9 ]; then
	cd ${LFS}/sources
	tar -xvf gcc-5.3.0.tar.bz2
	cd gcc-5.3.0
	cat gcc/limitx.h gcc/glimits.h gcc/limity.h > `dirname $(${LFS_TGT}-gcc -print-libgcc-file-name)`/include-fixed/limits.h
	for file in $(find gcc/config -name linux64.h -o -name linux.h -o -name sysv4.h)
	do
		cp -uv $file{,.orig}
		sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' -e 's@/usr@/tools@g' $file.orig > $file
		echo '
		#undef STANDARD_STARTFILE_PREFIX_1
		#undef STANDARD_STARTFILE_PREFIX_2
		#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
		#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  		touch $file.orig
	done
	tar -xvf ../mpfr-3.1.3.tar.xz
	mv -v mpfr-3.1.3 mpfr
	tar -xf ../gmp-6.1.0.tar.xz
	mv -v gmp-6.1.0 gmp
	tar -xf ../mpc-1.0.3.tar.gz
	mv -v mpc-1.0.3 mpc
	mkdir -v build
	cd build
	CC=${LFS_TGT}-gcc \
	CXX=${LFS_TGT}-g++ \
	AR=${LFS_TGT}-ar \
	RANLIB=${LFS_TGT}-ranlib \
	../configure \
		--prefix=/tools \
		--with-local-prefix=/tools \
		--with-native-system-header-dir=/tools/include \
		--enable-languages=c,c++ \
		--disable-libstdcxx-pch \
		--disable-multilib \
		--disable-bootstrap \
		--disable-libgomp
	make -j $JOBS
	make -j $JOBS install
	cd ../..
	rm -rvf gcc-5.3.0
	ln -sv gcc /tools/bin/cc
	echo 'int main(){}' > dummy.c
	cc dummy.c
	readelf -l a.out | grep ': /tools'
	read -p 'Is the above line of the form [Requesting program interpreter: /tools/lib64/ld-linux-x86-64.so.2] (y/n)? ' result
	if [ $result = y ]; then let "STEP++"
	else echo 'Compilation and linking test fails! Automated sequence aborted!'; fi
	rm -vf dummy.c a.out
fi

#tcl-core-8.6.4
if [ $STEP -eq 10 ]; then
	cd ${LFS}/sources
	tar -xvf tcl-core8.6.4-src.tar.gz
	cd tcl8.6.4
	cd unix
	./configure --prefix=/tools
	make -j $JOBS
	TZ=UTC make -j $JOBS test
	make -j $JOBS install
	chmod -v u+w /tools/lib/libtcl8.6.so
	make -j $JOBS install-private-headers
	ln -sv tclsh8.6 /tools/bin/tclsh
	cd ../..
	rm -rvf tcl8.6.4
	let "STEP++"
fi

#expect-5.45
if [ $STEP -eq 11 ]; then
	cd ${LFS}/sources
	tar -xvf expect5.45.tar.gz
	cd expect5.45
	cp -v configure{,.orig}
	sed 's:/usr/local/bin:/bin:' configure.orig > configure
	./configure \
		--prefix=/tools \
		--with-tcl=/tools/lib \
		--with-tclinclude=/tools/include
	make -j $JOBS
	make -j $JOBS SCRIPTS="" install
	cd ..
	rm -rvf expect5.45
	let "STEP++"
fi

#dejagnu-1.5.3
if [ $STEP -eq 12 ]; then
	cd ${LFS}/sources
	tar -xvf dejagnu-1.5.3.tar.gz
	cd dejagnu-1.5.3
	./configure --prefix=/tools
	make -j $JOBS install
	cd ..
	rm -rvf dejagnu-1.5.3
	let "STEP++"
fi

#check-0.10.0
if [ $STEP -eq 13 ]; then
	cd ${LFS}/sources
	tar -xvf check-0.10.0.tar.gz
	cd check-0.10.0
	PKG_CONFIG= ./configure --prefix=/tools
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf check-0.10.0
	let "STEP++"
fi

#ncurses-6.0
if [ $STEP -eq 14 ]; then
	cd ${LFS}/sources
	tar -xvf ncurses-6.0.tar.gz
	cd ncurses-6.0
	sed -i s/mawk// configure
	./configure \
		--prefix=/tools \
		--with-shared \
		--without-debug \
		--without-ada \
		--enable-widec \
		--enable-overwrite
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf ncurses-6.0
	let "STEP++"
fi

#bash-4.3.30
if [ $STEP -eq 15 ]; then
	cd ${LFS}/sources
	tar -xvf bash-4.3.30.tar.gz
	cd bash-4.3.30
	./configure --prefix=/tools --without-bash-malloc
	make -j $JOBS
	make -j $JOBS install
	ln -sv bash /tools/bin/sh
	cd ..
	rm -rvf bash-4.3.30
	let "STEP++"
fi

#bzip2-1.0.6
if [ $STEP -eq 16 ]; then
	cd ${LFS}/sources
	tar -xvf bzip2-1.0.6.tar.gz
	cd bzip2-1.0.6
	make -j $JOBS
	make -j $JOBS PREFIX=/tools install
	cd ..
	rm -rvf bzip2-1.0.6
	let "STEP++"
fi

#coreutils-8.25
if [ $STEP -eq 17 ]; then
	cd ${LFS}/sources
	tar -xvf coreutils-8.25.tar.xz
	cd coreutils-8.25
	./configure --prefix=/tools --enable-install-program=hostname
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf coreutils-8.25
	let "STEP++"
fi

#diffutils-3.3
if [ $STEP -eq 18 ]; then
	cd ${LFS}/sources
	tar -xvf diffutils-3.3.tar.xz
	cd diffutils-3.3
	./configure --prefix=/tools
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf diffutils-3.3
	let "STEP++"
fi

#file-5.25
if [ $STEP -eq 19 ]; then
	cd ${LFS}/sources
	tar -xvf file-5.25.tar.gz
	cd file-5.25
	./configure --prefix=/tools
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf file-5.25
	let "STEP++"
fi

#findutils-4.6.0
if [ $STEP -eq 20 ]; then
	cd ${LFS}/sources
	tar -xvf findutils-4.6.0.tar.gz
	cd findutils-4.6.0
	./configure --prefix=/tools
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf findutils-4.6.0
	let "STEP++"
fi

#gawk-4.1.3
if [ $STEP -eq 21 ]; then
	cd ${LFS}/sources
	tar -xvf gawk-4.1.3.tar.xz
	cd gawk-4.1.3
	./configure --prefix=/tools
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gawk-4.1.3
	let "STEP++"
fi

#gettext-0.19.7
if [ $STEP -eq 22 ]; then
	cd ${LFS}/sources
	tar -xvf gettext-0.19.7.tar.xz
	cd gettext-0.19.7
	cd gettext-tools
	EMACS="no" ./configure --prefix=/tools --disable-shared
	make -j $JOBS -C gnulib-lib
	make -j $JOBS -C intl pluralx.c
	make -j $JOBS -C src msgfmt
	make -j $JOBS -C src msgmerge
	make -j $JOBS -C src xgettext
	cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin
	cd ../..
	rm -rvf gettext-0.19.7
	let "STEP++"
fi

#grep-2.23
if [ $STEP -eq 23 ]; then
	cd ${LFS}/sources
	tar -xvf grep-2.23.tar.xz
	cd grep-2.23
	./configure --prefix=/tools
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf grep-2.23
	let "STEP++"
fi

#gzip-1.6
if [ $STEP -eq 24 ]; then
	cd ${LFS}/sources
	tar -xvf gzip-1.6.tar.xz
	cd gzip-1.6
	./configure --prefix=/tools
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gzip-1.6
	let "STEP++"
fi

#m4-1.4.17
if [ $STEP -eq 25 ]; then
	cd ${LFS}/sources
	tar -xvf m4-1.4.17.tar.xz
	cd m4-1.4.17
	./configure --prefix=/tools
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf m4-1.4.17
	let "STEP++"
fi

#make-4.1
if [ $STEP -eq 26 ]; then
	cd ${LFS}/sources
	tar -xvf make-4.1.tar.bz2
	cd make-4.1
	./configure --prefix=/tools --without-guile
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf make-4.1
	let "STEP++"
fi

#patch-2.7.5
if [ $STEP -eq 27 ]; then
	cd ${LFS}/sources
	tar -xvf patch-2.7.5.tar.xz
	cd patch-2.7.5
	./configure --prefix=/tools
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf patch-2.7.5
	let "STEP++"
fi

#perl-5.22.1
if [ $STEP -eq 28 ]; then
	cd ${LFS}/sources
	tar -xvf perl-5.22.1.tar.bz2
	cd perl-5.22.1
	sh Configure -des -Dprefix=/tools -Dlibs=-lm
	make -j $JOBS
	cp -v perl cpan/podlators/pod2man /tools/bin
	mkdir -pv /tools/lib/perl5/5.22.1
	cp -Rv lib/* /tools/lib/perl5/5.22.1
	cd ..
	rm -rvf perl-5.22.1
	let "STEP++"
fi

#sed-4.2.2
if [ $STEP -eq 29 ]; then
	cd ${LFS}/sources
	tar -xvf sed-4.2.2.tar.bz2
	cd sed-4.2.2
	./configure --prefix=/tools
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf sed-4.2.2
	let "STEP++"
fi

#tar-1.28
if [ $STEP -eq 30 ]; then
	cd ${LFS}/sources
	tar -xvf tar-1.28.tar.xz
	cd tar-1.28
	./configure --prefix=/tools
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf tar-1.28
	let "STEP++"
fi

#texinfo-6.1
if [ $STEP -eq 31 ]; then
	cd ${LFS}/sources
	tar -xvf texinfo-6.1.tar.xz
	cd texinfo-6.1
	./configure --prefix=/tools
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf texinfo-6.1
	let "STEP++"
fi

#util-linux-2.27.1
if [ $STEP -eq 32 ]; then
	cd ${LFS}/sources
	tar -xvf util-linux-2.27.1.tar.xz
	cd util-linux-2.27.1
	./configure \
		--prefix=/tools \
		--without-python \
		--disable-makeinstall-chown \
		--without-systemdsystemunitdir \
		PKG_CONFIG=""
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf util-linux-2.27.1
	let "STEP++"
fi

#xz-5.2.2
if [ $STEP -eq 33 ]; then
	cd ${LFS}/sources
	tar -xvf xz-5.2.2.tar.xz
	cd xz-5.2.2
	./configure --prefix=/tools
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xz-5.2.2
	let "STEP++"
fi

#Stripping
if [ $STEP -eq 34 ]; then
	strip -v --strip-debug /tools/lib/*
	/usr/bin/strip -v --strip-unneeded /tools/{,s}bin/*
	rm -rvf /tools/{,share}/{info,man,doc}
	let "STEP++"
fi

#Built tools backup and ownership
if [ $STEP -eq 35 ]; then
	read -p 'Do you want to change the ownership of recently built tools to user root (y/n) ? ' result
	if [ $result = y ]; then sudo chown --recursive root: ${LFS}/tools; fi
	read -p 'Do you want to backup your recently built tools (y/n) ? ' result
	if [ $result = y ]; then
		read -p 'Enter backup location : ' location
		if [ -d $location ]; then cd $LFS; tar -Jcvf ${location}/tools.tar.xz tools/*
		else echo 'Invalid backup location! No backup will be performed...'; fi
	fi
	let "STEP++"
fi
