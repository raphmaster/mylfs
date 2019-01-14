#!/tools/bin/bash

#The script must be run in a chroot environment

#The following environment variables must be set before running the script:
#STEP -> Starting step
#JOBS -> Maximum simultaneous make jobs

#Ensure STEP is set
if [ ! -v STEP ]; then
	echo 'Starting step is not set ! Use environment variable STEP to set starting step before launching script.'
	exit 1
fi

#Ensure JOBS is set
if [ ! -v JOBS ]; then
	echo 'Maximum simultaneous make jobs is not set ! Use environment variable JOBS to set max make jobs before launching script.'
	exit 1
fi

#Create directory tree
if [ $STEP -eq 0 ]; then
	mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
	mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}
	install -dv -m 0750 /root
	install -dv -m 1777 /tmp /var/tmp
	mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
	mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
	mkdir -v  /usr/{,local/}share/{misc,terminfo,zoneinfo}
	mkdir -v  /usr/libexec
	mkdir -pv /usr/{,local/}share/man/man{1..8}
	ln -sv lib /lib64
        ln -sv lib /usr/lib64
        ln -sv lib /usr/local/lib64
	mkdir -v /var/{log,mail,spool}
	ln -sv /run /var/run
	ln -sv /run/lock /var/lock
	mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}
	let "STEP++"
fi

#Create essential files and symbolic links
if [ $STEP -eq 1 ]; then
	ln -sv /tools/bin/{bash,cat,echo,pwd,stty} /bin
	ln -sv /tools/bin/perl /usr/bin
	ln -sv /tools/lib/libgcc_s.so{,.1} /usr/lib
	ln -sv /tools/lib/libstdc++.so{,.6} /usr/lib
	sed 's/tools/usr/' /tools/lib/libstdc++.la > /usr/lib/libstdc++.la
	ln -sv bash /bin/sh
	ln -sv /proc/self/mounts /etc/mtab
	cp -v /alfs/etc/passwd /etc/passwd
	cp -v /alfs/etc/group /etc/group
	touch /var/log/{btmp,lastlog,wtmp}
	chgrp -v utmp /var/log/lastlog
	chmod -v 664  /var/log/lastlog
	chmod -v 600  /var/log/btmp
	let "STEP++"
fi

#linux-4.5 API Headers
if [ $STEP -eq 2 ]; then
	cd /sources
	tar -xvf linux-libre-4.5-gnu.tar.xz
	cd linux-4.5
	make -j $JOBS mrproper
	make -j $JOBS INSTALL_HDR_PATH=dest headers_install
	find dest/include \( -name .install -o -name ..install.cmd \) -delete
	cp -rv dest/include/* /usr/include
	cd ..
	rm -rvf linux-4.5
	let "STEP++"
fi

#man-pages-4.04
if [ $STEP -eq 3 ]; then
	cd /sources
	tar -xvf man-pages-4.04.tar.xz
	cd man-pages-4.04
	make -j $JOBS install
	cd ..
	rm -rvf man-pages-4.04
	let "STEP++"
fi

#glibc-2.23
if [ $STEP -eq 4 ]; then
	cd /sources
	tar -xvf glibc-2.23.tar.xz
	cd glibc-2.23
	patch -Np1 -i ../glibc-2.23-fhs-1.patch
	patch -Np1 -i ../glibc-2.23-upstream_i386_fix-1.patch
	mkdir -v build
	cd build
	../configure \
		--prefix=/usr \
		--disable-profile \
		--enable-kernel=2.6.32 \
		--enable-obsolete-rpc
	make -j $JOBS
	make -j $JOBS check
	read -p 'Is Glibc test suite pass (y/n) ? ' result
	if [ $result = y ]; then
		touch /etc/ld.so.conf
		make -j $JOBS install
		cp -v ../nscd/nscd.conf /etc/nscd.conf
		mkdir -pv /var/cache/nscd
		#Install locales
		mkdir -pv /usr/lib/locale
		localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
		localedef -i de_DE -f ISO-8859-1 de_DE
		localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
		localedef -i de_DE -f UTF-8 de_DE.UTF-8
		localedef -i en_GB -f UTF-8 en_GB.UTF-8
		localedef -i en_HK -f ISO-8859-1 en_HK
		localedef -i en_PH -f ISO-8859-1 en_PH
		localedef -i en_US -f ISO-8859-1 en_US
		localedef -i en_US -f UTF-8 en_US.UTF-8
		localedef -i es_MX -f ISO-8859-1 es_MX
		localedef -i fa_IR -f UTF-8 fa_IR
		localedef -i fr_FR -f ISO-8859-1 fr_FR
		localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
		localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
		localedef -i it_IT -f ISO-8859-1 it_IT
		localedef -i it_IT -f UTF-8 it_IT.UTF-8
		localedef -i ja_JP -f EUC-JP ja_JP
		localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
		localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
		localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
		localedef -i zh_CN -f GB18030 zh_CN.GB18030
		localedef -i en_CA -f UTF-8 en_CA.UTF-8
		localedef -i en_CA -f ISO-8859-1 en_CA
		localedef -i fr_CA -f UTF-8 fr_CA.UTF-8
		localedef -i fr_CA -f ISO-8859-1 fr_CA
		#Glibc defaults nsswitch.conf do not work well in a networked environment
		cp -v /alfs/etc/nsswitch.conf /etc/nsswitch.conf
		#Install timezone data
		tar -xvf ../../tzdata2016a.tar.gz
		ZONEINFO=/usr/share/zoneinfo
		mkdir -pv ${ZONEINFO}/{posix,right}
		for tz in etcetera southamerica northamerica europe africa antarctica asia australasia backward pacificnew systemv
		do
    			zic -L /dev/null   -d $ZONEINFO       -y "sh yearistype.sh" ${tz}
    			zic -L /dev/null   -d ${ZONEINFO}/posix -y "sh yearistype.sh" ${tz}
    			zic -L leapseconds -d ${ZONEINFO}/right -y "sh yearistype.sh" ${tz}
		done
		cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
		tzresult=$(tzselect)
		zic -d $ZONEINFO -p $tzresult
		unset ZONEINFO
		cp -v /usr/share/zoneinfo/$tzresult /etc/localtime
		#Configure dynamic loader
		cp -v /alfs/etc/ld.so.conf /etc/ld.so.conf
		mkdir -pv /etc/ld.so.conf.d
		let "STEP++"
	fi
	cd ../..
	rm -rvf glibc-2.23
fi

#adjust-toolchain
if [ $STEP -eq 5 ]; then
	mv -v /tools/bin/{ld,ld-old}
	mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}
	mv -v /tools/bin/{ld-new,ld}
	ln -sv /tools/bin/ld /tools/$(uname -m)-pc-linux-gnu/bin/ld
	gcc -dumpspecs | sed -e 's@/tools@@g' -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' > `dirname $(gcc --print-libgcc-file-name)`/specs
	echo 'int main(){}' > dummy.c
	cc dummy.c -v -Wl,--verbose &> dummy.log
	readelf -l a.out | grep ': /lib'
	read -p 'Is the above line of the form : [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2] (y/n)? ' result
	if [ $result = y ]; then
		grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
		read -p 'Are the above lines of the form :
/usr/lib64/crt1.o succeeded
/usr/lib64/crti.o succeeded
/usr/lib64/crtn.o succeeded
(y/n) ? ' result
		if [ $result = y ]; then
			grep -B1 '^ /usr/include' dummy.log
			read -p 'Are the above lines of the form :
#include <...> search starts here:
 /usr/include
(y/n) ? ' result
			if [ $result = y ]; then
				grep 'SEARCH.*/usr/lib' dummy.log | sed 's|; |\n|g'
				read -p 'Are the above lines of the form :
SEARCH_DIR("/usr/lib")
SEARCH_DIR("/lib");
(y/n) ? ' result
				if [ $result = y ]; then
					grep "/lib.*/libc.so.6 " dummy.log
					read -p 'Is the above line of the form : attempt to open /lib64/libc.so.6 succeeded (y/n) ? ' result
					if [ $result = y ]; then
						grep found dummy.log
						read -p 'Is the above line of the form : found ld-linux-x86-64.so.2 at /lib64/ld-linux-x86-64.so.2 (y/n) ? ' result
						if [ $result = y ]; then
							let "STEP++"
						else echo 'Incorrect dynamic linker!'; fi
					else echo 'Incorrect libc!'; fi
				else echo 'Incorrect search path for the linker!'; fi
			else echo 'Compiler is not searching for the correct header files!'; fi
		else echo 'Wrong setup of start files!'; fi
	else echo 'Compilation and linking test fails!'; fi
	rm -vf dummy.c a.out dummy.log
fi

#zlib-1.2.8
if [ $STEP -eq 6 ]; then
	cd /sources
	tar -xvf zlib-1.2.8.tar.xz
	cd zlib-1.2.8
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	mv -v /usr/lib/libz.so.* /lib
	ln -sfv /lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
	cd ..
	rm -rvf zlib-1.2.8
	let "STEP++"
fi

#file-5.25
if [ $STEP -eq 7 ]; then
	cd /sources
	tar -xvf file-5.25.tar.gz
	cd file-5.25
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf file-5.25
	let "STEP++"
fi

#binutils-2.26
if [ $STEP -eq 8 ]; then
	cd /sources
	tar -xvf binutils-2.26.tar.bz2
	cd binutils-2.26
	expect -c "spawn ls"
	read -p 'Is the above line : spawn ls (y/n) ? ' result
	if [ $result = y ]; then
		patch -Np1 -i ../binutils-2.26-upstream_fix-2.patch
		mkdir -v build
		cd build
		../configure \
			--prefix=/usr \
			--enable-shared \
			--disable-werror
		make -j $JOBS tooldir=/usr
		make -j $JOBS check
		read -p 'Is Binutils check pass (y/n) ? ' result
		if [ $result = y ]; then
			make -j $JOBS tooldir=/usr install
			let "STEP++"
		else echo 'Binutils check failed!'; fi
		cd ..
	else echo 'Environment is not set up for proper PTY operations!'; fi
	cd ..
	rm -rvf binutils-2.26
fi

#gmp-6.1.0
if [ $STEP -eq 9 ]; then
	cd /sources
	tar -xvf gmp-6.1.0.tar.xz
	cd gmp-6.1.0
	./configure \
		--prefix=/usr \
		--enable-cxx \
		--disable-static \
		--docdir=/usr/share/doc/gmp-6.1.0
	make -j $JOBS
	make -j $JOBS html
	make -j $JOBS check 2>&1 | tee gmp-check-log
	awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log
	read -p 'Is GMP check pass (y/n) ? ' result
	if [ $result = y ]; then
		make -j $JOBS install
		make -j $JOBS install-html
		let "STEP++"
	else echo 'GMP check failed!'; fi
	cd ..
	rm -rvf gmp-6.1.0
fi

#mpfr-3.1.3
if [ $STEP -eq 10 ]; then
	cd /sources
	tar -xvf mpfr-3.1.3.tar.xz
	cd mpfr-3.1.3
	patch -Np1 -i ../mpfr-3.1.3-upstream_fixes-2.patch
	./configure \
		--prefix=/usr \
		--disable-static \
		--enable-thread-safe \
		--docdir=/usr/share/doc/mpfr-3.1.3
	make -j $JOBS
	make -j $JOBS html
	make -j $JOBS check
	read -p 'Is MPFR check pass (y/n) ? ' result
	if [ $result = y ]; then
		make -j $JOBS install
		make -j $JOBS install-html
		let "STEP++"
	else echo 'MPFR check failed!'; fi
	cd ..
	rm -rvf mpfr-3.1.3
fi

#mpc-1.0.3
if [ $STEP -eq 11 ]; then
	cd /sources
	tar -xvf mpc-1.0.3.tar.gz
	cd mpc-1.0.3
	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/mpc-1.0.3
	make -j $JOBS
	make -j $JOBS html
	make -j $JOBS install
	make -j $JOBS install-html
	cd ..
	rm -rvf mpc-1.0.3
	let "STEP++"
fi

#gcc-5.3.0
if [ $STEP -eq 12 ]; then
	cd /sources
	tar -xvf gcc-5.3.0.tar.bz2
	cd gcc-5.3.0
	mkdir -v build
	cd build
	SED=sed \
	../configure \
		--prefix=/usr \
		--enable-languages=c,c++ \
		--disable-multilib \
		--disable-bootstrap \
		--with-system-zlib
	make -j $JOBS
	ulimit -s 32768
	make -j $JOBS -k check
	../contrib/test_summary | grep -A7 Summ
	read -p 'Is GCC check pass compared with http://www.linuxfromscratch.org/lfs/build-logs/7.9/i7-5820K/test-logs/082-gcc-5.3.0 (y/n) ? ' result
	if [ $result = y ]; then
		make -j $JOBS install
		ln -sv /usr/bin/cpp /lib
		ln -sv gcc /usr/bin/cc
		install -v -dm755 /usr/lib/bfd-plugins
		ln -sfv /usr/libexec/gcc/$(gcc -dumpmachine)/5.3.0/liblto_plugin.so /usr/lib/bfd-plugins/
		echo 'int main(){}' > dummy.c
		cc dummy.c -v -Wl,--verbose &> dummy.log
		readelf -l a.out | grep ': /lib'
		read -p 'Is the above line of the form [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2] (y/n)? ' result
		if [ $result = y ]; then
			grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
			read -p 'Are the above lines of the form :
/usr/lib64/gcc/x86_64-pc-linux-gnu/5.3.0/../../../crt1.o succeeded
/usr/lib64/gcc/x86_64-pc-linux-gnu/5.3.0/../../../crti.o succeeded
/usr/lib64/gcc/x86_64-pc-linux-gnu/5.3.0/../../../crtn.o succeeded
(y/n) ? ' result
			if [ $result = y ]; then
				grep -B4 '^ /usr/include' dummy.log
				read -p 'Are the above lines of the form :
#include <...> search starts here:
 /usr/lib64/gcc/x86_64-pc-linux-gnu/5.3.0/include
 /usr/local/include
 /usr/lib64/gcc/x86_64-pc-linux-gnu/5.3.0/include-fixed
 /usr/include
(y/n) ? ' result
				if [ $result = y ]; then
					grep 'SEARCH.*/usr/lib' dummy.log | sed 's|; |\n|g'
					read -p 'Are the above lines of the form :
SEARCH_DIR("/usr/x86_64-pc-linux-gnu/lib64")
SEARCH_DIR("/usr/local/lib64")
SEARCH_DIR("/lib64")
SEARCH_DIR("/usr/lib64")
SEARCH_DIR("/usr/x86_64-pc-linux-gnu/lib")
SEARCH_DIR("/usr/local/lib")
SEARCH_DIR("/lib")
SEARCH_DIR("/usr/lib");
(y/n) ? ' result
					if [ $result = y ]; then
						grep "/lib.*/libc.so.6 " dummy.log
						read -p 'Is the above line of the form : attempt to open /lib64/libc.so.6 succeeded (y/n) ? ' result
						if [ $result = y ]; then
							grep found dummy.log
							read -p 'Is the above line of the form : found ld-linux-x86-64.so.2 at /lib64/ld-linux-x86-64.so.2 (y/n) ? ' result
							if [ $result = y ]; then
								mkdir -pv /usr/share/gdb/auto-load/usr/lib
								mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
								let "STEP++"
							else echo 'Incorrect dynamic linker!'; fi
						else echo 'Incorrect libc!'; fi
					else echo 'Linker is not using the correct search paths!'; fi
				else echo 'Compiler is not searching for the correct headers!'; fi
			else echo 'Incorrect start files!'; fi
		else echo 'Compilation and linking test fails!'; fi
		rm -v dummy.c a.out dummy.log
	else echo 'GCC check failed!'; fi
	cd ../..
	rm -rvf gcc-5.3.0
fi

#bzip2-1.0.6
if [ $STEP -eq 13 ]; then
	cd /sources
	tar -xvf bzip2-1.0.6.tar.gz
	cd bzip2-1.0.6
	patch -Np1 -i ../bzip2-1.0.6-install_docs-1.patch
	sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
	sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
	make -j $JOBS -f Makefile-libbz2_so
	make -j $JOBS clean
	make -j $JOBS
	make -j $JOBS PREFIX=/usr install
	cp -v bzip2-shared /bin/bzip2
	cp -av libbz2.so* /lib
	ln -sv /lib/libbz2.so.1.0 /usr/lib/libbz2.so
	rm -v /usr/bin/{bunzip2,bzcat,bzip2}
	ln -sv bzip2 /bin/bunzip2
	ln -sv bzip2 /bin/bzcat
	cd ..
	rm -rvf bzip2-1.0.6
	let "STEP++"
fi

#pkg-config-0.29
if [ $STEP -eq 14 ]; then
	cd /sources
	tar -xvf pkg-config-0.29.tar.gz
	cd pkg-config-0.29
	./configure \
		--prefix=/usr \
		--with-internal-glib \
		--disable-host-tool \
		--docdir=/usr/share/doc/pkg-config-0.29
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf pkg-config-0.29
	let "STEP++"
fi

#ncurses-6.0
if [ $STEP -eq 15 ]; then
	cd /sources
	tar -xvf ncurses-6.0.tar.gz
	cd ncurses-6.0
	sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in
	./configure \
		--prefix=/usr \
		--mandir=/usr/share/man \
		--with-shared \
		--without-debug \
		--without-normal \
		--enable-pc-files \
		--enable-widec
	make -j $JOBS
	make -j $JOBS install
	mv -v /usr/lib/libncursesw.so.6* /lib
	ln -sfv /lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so
	for lib in ncurses form panel menu
	do
		rm -vf /usr/lib/lib${lib}.so
		echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
		ln -sfv ${lib}w.pc /usr/lib/pkgconfig/${lib}.pc
	done
	rm -vf /usr/lib/libcursesw.so
	echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
	ln -sfv libncurses.so /usr/lib/libcurses.so
	cd ..
	rm -rvf ncurses-6.0
	let "STEP++"
fi

#attr-2.4.47
if [ $STEP -eq 16 ]; then
	cd /sources
	tar -xvf attr-2.4.47.src.tar.gz
	cd attr-2.4.47
	sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
	sed -i -e "/SUBDIRS/s|man[25]||g" man/Makefile
	./configure \
		--prefix=/usr \
		--bindir=/bin \
		--disable-static
	make -j $JOBS
	make -j1 tests root-tests
	make -j $JOBS install install-dev install-lib
	chmod -v 755 /usr/lib/libattr.so
	mv -v /usr/lib/libattr.so.* /lib
	ln -sfv /lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so
	cd ..
	rm -rvf attr-2.4.47
	let "STEP++"
fi

#acl-2.2.52
if [ $STEP -eq 17 ]; then
	cd /sources
	tar -xvf acl-2.2.52.src.tar.gz
	cd acl-2.2.52
	sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
	sed -i "s:| sed.*::g" test/{sbits-restore,cp,misc}.test
	sed -i -e "/TABS-1;/a if (x > (TABS-1)) x = (TABS-1);" libacl/__acl_to_any_text.c
	./configure \
		--prefix=/usr \
		--bindir=/bin \
		--disable-static \
		--libexecdir=/usr/lib
	make -j $JOBS
	make -j $JOBS install install-dev install-lib
	chmod -v 755 /usr/lib/libacl.so
	mv -v /usr/lib/libacl.so.* /lib
	ln -sfv /lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so
	cd ..
	rm -rvf acl-2.2.52
	let "STEP++"
fi

#libcap-2.25
if [ $STEP -eq 18 ]; then
	cd /sources
	tar -xvf libcap-2.25.tar.xz
	cd libcap-2.25
	sed -i '/install.*STALIBNAME/d' libcap/Makefile
	make -j $JOBS
	make -j $JOBS RAISE_SETFCAP=no prefix=/usr install
	chmod -v 755 /usr/lib/libcap.so
	mv -v /usr/lib/libcap.so.* /lib
	ln -sfv /lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so
	cd ..
	rm -rvf libcap-2.25
	let "STEP++"
fi

#sed-4.2.2
if [ $STEP -eq 19 ]; then
	cd /sources
	tar -xvf sed-4.2.2.tar.bz2
	cd sed-4.2.2
	./configure \
		--prefix=/usr \
		--bindir=/bin \
		--htmldir=/usr/share/doc/sed-4.2.2
	make -j $JOBS
	make -j $JOBS html
	make -j $JOBS install
	make -j $JOBS -C doc install-html
	cd ..
	rm -rvf sed-4.2.2
	let "STEP++"
fi

#shadow-4.2.1
if [ $STEP -eq 20 ]; then
	cd /sources
	tar -xvf shadow-4.2.1.tar.xz
	cd shadow-4.2.1
	sed -i 's/groups$(EXEEXT) //' src/Makefile.in
	find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;
	find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
	find man -name Makefile.in -exec sed -i 's/passwd\.5 / /' {} \;
	sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' -e 's@/var/spool/mail@/var/mail@' etc/login.defs
	sed -i 's/1000/999/' etc/useradd
	./configure --sysconfdir=/etc --with-group-name-max-length=32
	make -j $JOBS
	make -j $JOBS install
	mv -v /usr/bin/passwd /bin
	pwconv
	grpconv
	passwd root
	cd ..
	rm -rvf shadow-4.2.1
	let "STEP++"
fi

#psmisc-22.21
if [ $STEP -eq 21 ]; then
	cd /sources
	tar -xvf psmisc-22.21.tar.gz
	cd psmisc-22.21
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	mv -v /usr/bin/fuser /bin
	mv -v /usr/bin/killall /bin
	cd ..
	rm -rvf psmisc-22.21
	let "STEP++"
fi

#procps-ng-3.3.11
if [ $STEP -eq 22 ]; then
	cd /sources
	tar -xvf procps-ng-3.3.11.tar.xz
	cd procps-ng-3.3.11
	./configure \
		--prefix=/usr \
		--exec-prefix= \
		--libdir=/usr/lib \
		--docdir=/usr/share/doc/procps-ng-3.3.11 \
		--disable-static \
		--disable-kill
	make -j $JOBS
	make -j $JOBS install
	mv -v /usr/lib/libprocps.so.* /lib
	ln -sfv /lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
	cd ..
	rm -rvf procps-ng-3.3.11
	let "STEP++"
fi

#e2fsprogs-1.42.13
if [ $STEP -eq 23 ]; then
	cd /sources
	tar -xvf e2fsprogs-1.42.13.tar.gz
	cd e2fsprogs-1.42.13
	mkdir -v build
	cd build
	LIBS=-L/tools/lib \
	CFLAGS=-I/tools/include \
	PKG_CONFIG_PATH=/tools/lib/pkgconfig \
	../configure \
		--prefix=/usr \
		--bindir=/bin \
		--with-root-prefix="" \
		--enable-elf-shlibs \
		--disable-libblkid \
		--disable-libuuid \
		--disable-uuidd \
		--disable-fsck
	make -j $JOBS
	make -j $JOBS install
	make -j $JOBS install-libs
	chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
	gunzip -v /usr/share/info/libext2fs.info.gz
	install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
	makeinfo -o doc/com_err.info ../lib/et/com_err.texinfo
	install -v -m644 doc/com_err.info /usr/share/info
	install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
	cd ../..
	rm -rvf e2fsprogs-1.42.13
	let "STEP++"
fi

#iana-etc-2.30
if [ $STEP -eq 24 ]; then
	cd /sources
	tar -xvf iana-etc-2.30.tar.bz2
	cd iana-etc-2.30
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf iana-etc-2.30
	let "STEP++"
fi

#m4-1.4.17
if [ $STEP -eq 25 ]; then
	cd /sources
	tar -xvf m4-1.4.17.tar.xz
	cd m4-1.4.17
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf m4-1.4.17
	let "STEP++"
fi

#bison-3.0.4
if [ $STEP -eq 26 ]; then
	cd /sources
	tar -xvf bison-3.0.4.tar.xz
	cd bison-3.0.4
	./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.0.4
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf bison-3.0.4
	let "STEP++"
fi

#flex-2.6.0
if [ $STEP -eq 27 ]; then
	cd /sources
	tar -xvf flex-2.6.0.tar.xz
	cd flex-2.6.0
	./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.0
	make -j $JOBS
	make -j $JOBS install
	ln -sv flex /usr/bin/lex
	cd ..
	rm -rvf flex-2.6.0
	let "STEP++"
fi

#grep-2.23
if [ $STEP -eq 28 ]; then
	cd /sources
	tar -xvf grep-2.23.tar.xz
	cd grep-2.23
	./configure --prefix=/usr --bindir=/bin
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf grep-2.23
	let "STEP++"
fi

#readline-6.3
if [ $STEP -eq 29 ]; then
	cd /sources
	tar -xvf readline-6.3.tar.gz
	cd readline-6.3
	patch -Np1 -i ../readline-6.3-upstream_fixes-3.patch
	sed -i '/MV.*old/d' Makefile.in
	sed -i '/{OLDSUFF}/c:' support/shlib-install
	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/readline-6.3
	make -j $JOBS SHLIB_LIBS=-lncurses
	make -j $JOBS SHLIB_LIBS=-lncurses install
	mv -v /usr/lib/lib{readline,history}.so.* /lib
	ln -sfv /lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
	ln -sfv /lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
	cd ..
	rm -rvf readline-6.3
	let "STEP++"
fi

#bash-4.3.30
if [ $STEP -eq 30 ]; then
	cd /sources
	tar -xvf bash-4.3.30.tar.gz
	cd bash-4.3.30
	patch -Np1 -i ../bash-4.3.30-upstream_fixes-3.patch
	./configure \
		--prefix=/usr \
		--docdir=/usr/share/doc/bash-4.3.30 \
		--without-bash-malloc \
		--with-installed-readline
	make -j $JOBS
	make -j $JOBS install
	mv -vf /usr/bin/bash /bin
	cd ..
	rm -rvf bash-4.3.30
	let "STEP++"
#Can start using new shell
fi

#bc-1.06.95
if [ $STEP -eq 31 ]; then
	cd /sources
	tar -xvf bc-1.06.95.tar.bz2
	cd bc-1.06.95
	patch -Np1 -i ../bc-1.06.95-memory_leak-1.patch
	./configure \
		--prefix=/usr \
		--with-readline \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf bc-1.06.95
	let "STEP++"
fi

#libtool-2.4.6
if [ $STEP -eq 32 ]; then
	cd /sources
	tar -xvf libtool-2.4.6.tar.xz
	cd libtool-2.4.6
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libtool-2.4.6
	let "STEP++"
fi

#gdbm-1.11
if [ $STEP -eq 33 ]; then
	cd /sources
	tar -xvf gdbm-1.11.tar.gz
	cd gdbm-1.11
	./configure \
		--prefix=/usr \
		--disable-static \
		--enable-libgdbm-compat
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gdbm-1.11
	let "STEP++"
fi

#expat-2.1.0
if [ $STEP -eq 34 ]; then
	cd /sources
	tar -xvf expat-2.1.0.tar.gz
	cd expat-2.1.0
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf expat-2.1.0
	let "STEP++"
fi

#inetutils-1.9.4
if [ $STEP -eq 35 ]; then
	cd /sources
	tar -xvf inetutils-1.9.4.tar.xz
	cd inetutils-1.9.4
	./configure \
		--prefix=/usr \
		--localstatedir=/var \
		--disable-logger \
		--disable-whois \
		--disable-rcp \
		--disable-rexec \
		--disable-rlogin \
		--disable-rsh \
		--disable-servers
	make -j $JOBS
	make -j $JOBS install
	mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
	mv -v /usr/bin/ifconfig /sbin
	cd ..
	rm -rvf inetutils-1.9.4
	let "STEP++"
fi

#perl-5.22.1
if [ $STEP -eq 36 ]; then
	cd /sources
	tar -xvf perl-5.22.1.tar.bz2
	cd perl-5.22.1
	read -p 'Please enter your system hostname : ' hostname
	echo $hostname > /etc/hostname
	echo "127.0.0.1 ${hostname}.example.org localhost $hostname" > /etc/hosts
	unset hostname
	export BUILD_ZLIB=False
	export BUILD_BZIP2=0
	sh Configure -des \
		-Dprefix=/usr \
		-Dvendorprefix=/usr \
		-Dman1dir=/usr/share/man/man1 \
		-Dman3dir=/usr/share/man/man3 \
		-Dpager="/usr/bin/less -isR" \
		-Duseshrplib
	make -j $JOBS
	make -j $JOBS install
	unset BUILD_ZLIB BUILD_BZIP2
	cd ..
	rm -rvf perl-5.22.1
	let "STEP++"
fi

#xml-parser-2.44
if [ $STEP -eq 37 ]; then
	cd /sources
	tar -xvf XML-Parser-2.44.tar.gz
	cd XML-Parser-2.44
	perl Makefile.PL
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf XML-Parser-2.44
	let "STEP++"
fi

#autoconf-2.69
if [ $STEP -eq 38 ]; then
	cd /sources
	tar -xvf autoconf-2.69.tar.xz
	cd autoconf-2.69
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf autoconf-2.69
	let "STEP++"
fi

#automake-1.15
if [ $STEP -eq 39 ]; then
	cd /sources
	tar -xvf automake-1.15.tar.xz
	cd automake-1.15
	sed -i 's:/\\\${:/\\\$\\{:' bin/automake.in
	./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.15
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf automake-1.15
	let "STEP++"
fi

#coreutils-8.25
if [ $STEP -eq 40 ]; then
	cd /sources
	tar -xvf coreutils-8.25.tar.xz
	cd coreutils-8.25
	patch -Np1 -i ../coreutils-8.25-i18n-1.patch
	FORCE_UNSAFE_CONFIGURE=1 \
	./configure \
		--prefix=/usr \
		--enable-no-install-program=kill,uptime
	FORCE_UNSAFE_CONFIGURE=1 make -j $JOBS
	make -j $JOBS install
	mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
	mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
	mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
	mv -v /usr/bin/chroot /usr/sbin
	mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
	sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8
	mv -v /usr/bin/{head,sleep,nice,test,[} /bin
	cd ..
	rm -rvf coreutils-8.25
	let "STEP++"
fi

#diffutils-3.3
if [ $STEP -eq 41 ]; then
	cd /sources
	tar -xvf diffutils-3.3.tar.xz
	cd diffutils-3.3
	sed -i 's:= @mkdir_p@:= /bin/mkdir -p:' po/Makefile.in.in
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf diffutils-3.3
	let "STEP++"
fi

#gawk-4.1.3
if [ $STEP -eq 42 ]; then
	cd /sources
	tar -xvf gawk-4.1.3.tar.xz
	cd gawk-4.1.3
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gawk-4.1.3
	let "STEP++"
fi

#findutils-4.6.0
if [ $STEP -eq 43 ]; then
	cd /sources
	tar -xvf findutils-4.6.0.tar.gz
	cd findutils-4.6.0
	./configure --prefix=/usr --localstatedir=/var/lib/locate
	make -j $JOBS
	make -j $JOBS install
	mv -v /usr/bin/find /bin
	sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb
	cd ..
	rm -rvf findutils-4.6.0
	let "STEP++"
fi

#gettext-0.19.7
if [ $STEP -eq 44 ]; then
	cd /sources
	tar -xvf gettext-0.19.7.tar.xz
	cd gettext-0.19.7
	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/gettext-0.19.7
	make -j $JOBS
	make -j $JOBS install
	chmod -v 0755 /usr/lib/preloadable_libintl.so
	cd ..
	rm -rvf gettext-0.19.7
	let "STEP++"
fi

#intltool-0.51.0
if [ $STEP -eq 45 ]; then
	cd /sources
	tar -xvf intltool-0.51.0.tar.gz
	cd intltool-0.51.0
	sed -i 's:\\\${:\\\$\\{:' intltool-update.in
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
	cd ..
	rm -rvf intltool-0.51.0
	let "STEP++"
fi

#gperf-3.0.4
if [ $STEP -eq 46 ]; then
	cd /sources
	tar -xvf gperf-3.0.4.tar.gz
	cd gperf-3.0.4
	./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.0.4
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gperf-3.0.4
	let "STEP++"
fi

#groff-1.22.3
if [ $STEP -eq 47 ]; then
	cd /sources
	tar -xvf groff-1.22.3.tar.gz
	cd groff-1.22.3
	PAGE=letter ./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf groff-1.22.3
	let "STEP++"
fi

#xz-5.2.2
if [ $STEP -eq 48 ]; then
	cd /sources
	tar -xvf xz-5.2.2.tar.xz
	cd xz-5.2.2
	sed -e '/mf\.buffer = NULL/a next->coder->mf.size = 0;' -i src/liblzma/lz/lz_encoder.c
	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/xz-5.2.2
	make -j $JOBS
	make -j $JOBS install
	mv -v /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
	mv -v /usr/lib/liblzma.so.* /lib
	ln -svf /lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
	cd ..
	rm -rvf xz-5.2.2
	let "STEP++"
fi


#grub-2.02~beta2
if [ $STEP -eq 49 ]; then
	cd /sources
	tar -xvf grub-2.02~beta2.tar.xz
	cd grub-2.02~beta2
	./configure \
		--prefix=/usr \
		--sbindir=/sbin \
		--sysconfdir=/etc \
		--disable-grub-emu-usb \
		--disable-efiemu \
		--disable-werror
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf grub-2.02~beta2
	let "STEP++"
fi

#less-481
if [ $STEP -eq 50 ]; then
	cd /sources
	tar -xvf less-481.tar.gz
	cd less-481
	./configure --prefix=/usr --sysconfdir=/etc
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf less-481
	let "STEP++"
fi

#gzip-1.6
if [ $STEP -eq 51 ]; then
	cd /sources
	tar -xvf gzip-1.6.tar.xz
	cd gzip-1.6
	./configure --prefix=/usr --bindir=/bin
	make -j $JOBS
	make -j $JOBS install
	mv -v /bin/{gzexe,uncompress,zcmp,zdiff,zegrep} /usr/bin
	mv -v /bin/{zfgrep,zforce,zgrep,zless,zmore,znew} /usr/bin
	cd ..
	rm -rvf gzip-1.6
	let "STEP++"
fi

#iproute2-4.4.0
if [ $STEP -eq 52 ]; then
	cd /sources
	tar -xvf iproute2-4.4.0.tar.xz
	cd iproute2-4.4.0
	sed -i /ARPD/d Makefile
	sed -i 's/arpd.8//' man/man8/Makefile
	rm -v doc/arpd.sgml
	make -j $JOBS
	make -j $JOBS DOCDIR=/usr/share/doc/iproute2-4.4.0 install
	cd ..
	rm -rvf iproute2-4.4.0
	let "STEP++"
fi

#kbd-2.0.3
if [ $STEP -eq 53 ]; then
	cd /sources
	tar -xvf kbd-2.0.3.tar.xz
	cd kbd-2.0.3
	patch -Np1 -i ../kbd-2.0.3-backspace-1.patch
	sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
	sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
	PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf kbd-2.0.3
	let "STEP++"
fi

#kmod-22
if [ $STEP -eq 54 ]; then
	cd /sources
	tar -xvf kmod-22.tar.xz
	cd kmod-22
	./configure \
		--prefix=/usr \
		--bindir=/bin \
		--sysconfdir=/etc \
		--with-rootlibdir=/lib \
		--with-xz \
		--with-zlib
	make -j $JOBS
	make -j $JOBS install
	for target in depmod insmod lsmod modinfo modprobe rmmod
	do
		ln -sv /bin/kmod /sbin/$target
	done
	ln -sv kmod /bin/lsmod
	cd ..
	rm -rvf kmod-22
	let "STEP++"
fi

#libpipeline-1.4.1
if [ $STEP -eq 55 ]; then
	cd /sources
	tar -xvf libpipeline-1.4.1.tar.gz
	cd libpipeline-1.4.1
	PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libpipeline-1.4.1
	let "STEP++"
fi

#make-4.1
if [ $STEP -eq 56 ]; then
	cd /sources
	tar -xvf make-4.1.tar.bz2
	cd make-4.1
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf make-4.1
	let "STEP++"
fi

#patch-2.7.5
if [ $STEP -eq 57 ]; then
	cd /sources
	tar -xvf patch-2.7.5.tar.xz
	cd patch-2.7.5
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf patch-2.7.5
	let "STEP++"
fi

#sysklogd-1.5.1
if [ $STEP -eq 58 ]; then
	cd /sources
	tar -xvf sysklogd-1.5.1.tar.gz
	cd sysklogd-1.5.1
	sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
	make -j $JOBS
	make -j $JOBS BINDIR=/sbin install
	cp -v /alfs/etc/syslog.conf /etc/syslog.conf
	cd ..
	rm -rvf sysklogd-1.5.1
	let "STEP++"
fi

#sysvinit-2.88dsf
if [ $STEP -eq 59 ]; then
	cd /sources
	tar -xvf sysvinit-2.88dsf.tar.bz2
	cd sysvinit-2.88dsf
	patch -Np1 -i ../sysvinit-2.88dsf-consolidated-1.patch
	make -j $JOBS -C src
	make -j $JOBS -C src install
	cd ..
	rm -rvf sysvinit-2.88dsf
	let "STEP++"
fi

#tar-1.28
if [ $STEP -eq 60 ]; then
	cd /sources
	tar -xvf tar-1.28.tar.xz
	cd tar-1.28
	FORCE_UNSAFE_CONFIGURE=1 ./configure --prefix=/usr  --bindir=/bin
	make -j $JOBS
	make -j $JOBS install
	make -j $JOBS -C doc install-html docdir=/usr/share/doc/tar-1.28
	cd ..
	rm -rvf tar-1.28
	let "STEP++"
fi

#texinfo-6.1
if [ $STEP -eq 61 ]; then
	cd /sources
	tar -xvf texinfo-6.1.tar.xz
	cd texinfo-6.1
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	make -j $JOBS TEXMF=/usr/share/texmf install-tex
	cd ..
	rm -rvf texinfo-6.1
	let "STEP++"
fi

#eudev-3.1.5
if [ $STEP -eq 62 ]; then
	cd /sources
	tar -xvf eudev-3.1.5.tar.gz
	cd eudev-3.1.5
	sed -r -i 's|/usr(/bin/test)|\1|' test/udev-test.pl
	echo 'HAVE_BLKID=1
BLKID_LIBS="-lblkid"
BLKID_CFLAGS="-I/tools/include"' > config.cache
	./configure \
		--prefix=/usr \
		--bindir=/sbin \
		--sbindir=/sbin \
		--libdir=/usr/lib \
		--sysconfdir=/etc \
		--libexecdir=/lib \
		--with-rootprefix= \
		--with-rootlibdir=/lib \
		--enable-manpages \
		--disable-static \
		--config-cache
	LIBRARY_PATH=/tools/lib make -j $JOBS
	mkdir -pv /lib/udev/rules.d
	mkdir -pv /etc/udev/rules.d
	make -j $JOBS LD_LIBRARY_PATH=/tools/lib install
	tar -xvf ../udev-lfs-20140408.tar.bz2
	make -j $JOBS -f udev-lfs-20140408/Makefile.lfs install
	LD_LIBRARY_PATH=/tools/lib udevadm hwdb --update
	cd ..
	rm -rvf eudev-3.1.5
	let "STEP++"
fi

#util-linux-2.27.1
if [ $STEP -eq 63 ]; then
	cd /sources
	tar -xvf util-linux-2.27.1.tar.xz
	cd util-linux-2.27.1
	mkdir -pv /var/lib/hwclock
	./configure \
		ADJTIME_PATH=/var/lib/hwclock/adjtime \
		--docdir=/usr/share/doc/util-linux-2.27.1 \
		--disable-chfn-chsh \
		--disable-login \
		--disable-nologin \
		--disable-su \
		--disable-setpriv \
		--disable-runuser \
		--disable-pylibmount \
		--disable-static \
		--without-python \
		--without-systemd \
		--without-systemdsystemunitdir
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf util-linux-2.27.1
	let "STEP++"
fi

#man-db-2.7.5
if [ $STEP -eq 64 ]; then
	cd /sources
	tar -xvf man-db-2.7.5.tar.xz
	cd man-db-2.7.5
	./configure \
		--prefix=/usr \
		--docdir=/usr/share/doc/man-db-2.7.5 \
		--sysconfdir=/etc \
		--disable-setuid \
		--with-browser=/usr/bin/lynx \
		--with-vgrind=/usr/bin/vgrind \
		--with-grap=/usr/bin/grap
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf man-db-2.7.5
	let "STEP++"
fi

#nano-2.5.2
if [ $STEP -eq 65 ]; then
	cd /sources
	tar -xvf nano-2.5.2.tar.gz
	cd nano-2.5.2
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--enable-utf8 \
		--docdir=/usr/share/doc/nano-2.5.2
	make -j $JOBS
	make -j $JOBS install
	install -v -m644 doc/nanorc.sample /etc
	install -v -m644 doc/texinfo/nano.html /usr/share/doc/nano-2.5.2
	cd ..
	rm -rvf nano-2.5.2
	let "STEP++"
fi

#lfs-bootscripts-20150222
if [ $STEP -eq 66 ]; then
	cd /sources
	tar -xvf lfs-bootscripts-20150222.tar.bz2
	cd lfs-bootscripts-20150222
	make -j $JOBS install
	cd ..
	rm -rvf lfs-bootscripts-20150222
	let "STEP++"
fi

#final-configuration
if [ $STEP -eq 67 ]; then
	#network-configuration
	cp -v /alfs/etc/sysconfig/*.ifconfig.* /etc/sysconfig
	cp -v /alfs/etc/resolv.conf /etc/resolv.conf
	#init-configuration
	cp -v /alfs/etc/inittab /etc/inittab
	#clock-configuration
	cp -v /alfs/etc/sysconfig/clock /etc/sysconfig/clock
	#console-configuration
	cp -v /alfs/etc/sysconfig/console /etc/sysconfig/console
	#main-rc-configuration
	cp -v /alfs/etc/sysconfig/rc.site /etc/sysconfig/rc.site
	#bash-configuration
	cp -v /alfs/etc/inputrc /etc/inputrc
	cp -v /alfs/etc/shells /etc/shells
	cp -v /alfs/etc/profile /etc/profile
	install --directory --mode=0755 --owner=root --group=root /etc/profile.d
	cp -v /alfs/etc/profile.d/* /etc/profile.d
	cp -v /alfs/etc/bashrc /etc/bashrc
	#Enable adding hidden files (starting with ".") to filename expansion
	shopt -s dotglob
	mkdir -pv /etc/skel
	#Only root can view and edit files
	chmod -v 700 /etc/skel
	chmod -v 600 /alfs/etc/skel/*
	cp -v /alfs/etc/skel/* /etc/skel
	cp -v /alfs/etc/skel/* /root
	shopt -u dotglob
	dircolors -p > /etc/dircolors
	clear > /etc/issue
	let "STEP++"
fi
