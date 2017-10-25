#!/bin/bash

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

#Ensure source directory exists
if [ ! -d /sources ]; then
	echo 'Source directory does not exist ! All source packages must be in /sources.'
	exit 1
else
	cd /sources
fi

#random-number-generation
if [ $STEP -eq 0 ]; then
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-random
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#lsb-release-1.4
if [ $STEP -eq 1 ]; then
	tar -xvf lsb-release-1.4.tar.gz
	cd lsb-release-1.4
	sed -i "s|n/a|unavailable|" lsb_release
	./help2man -N --include ./lsb_release.examples --alt_version_key=program_version ./lsb_release > lsb_release.1
	install -v -m 644 lsb_release.1 /usr/share/man/man1/lsb_release.1
	install -v -m 755 lsb_release /usr/bin/lsb_release
	cp -v /alfs/etc/lsb-release /etc/lsb-release
	cd ..
	rm -rvf lsb-release-1.4
	let "STEP++"
fi

#openssl-1.0.2g
if [ $STEP -eq 1 ]; then
	tar -xvf openssl-1.0.2g.tar.gz
	cd openssl-1.0.2g
	./config \
		--prefix=/usr \
		--openssldir=/etc/ssl \
		--libdir=lib \
		shared \
		zlib-dynamic \
		no-rc5 \
		no-idea
	make -j $JOBS depend
	make -j $JOBS
	sed -i 's# libcrypto.a##;s# libssl.a##' Makefile
	make -j $JOBS MANDIR=/usr/share/man MANSUFFIX=ssl install
	install -dv -m755 /usr/share/doc/openssl-1.0.2g
	cp -vfr doc/* /usr/share/doc/openssl-1.0.2g
	cd ..
	rm -rvf openssl-1.0.2g
	let "STEP++"
fi

#berkeley-db-6.1.26
if [ $STEP -eq 2 ]; then
	tar -xvf db-6.1.26.tar.gz
	cd db-6.1.26
	cd build_unix
	../dist/configure \
		--prefix=/usr \
		--enable-compat185 \
		--enable-dbm \
		--disable-static \
		--enable-cxx
	make -j $JOBS
	make -j $JOBS docdir=/usr/share/doc/db-6.1.26 install
	chown -v -R root:root \
		/usr/bin/db_* \
		/usr/include/db{,_185,_cxx}.h \
		/usr/lib/libdb*.{so,la} \
		/usr/share/doc/db-6.1.26
	cd ../..
	rm -rvf db-6.1.26
	let "STEP++"
fi

#libgpg-error-1.21
if [ $STEP -eq 3 ]; then
	tar -xvf libgpg-error-1.21.tar.bz2
	cd libgpg-error-1.21
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	install -v -m644 -D README /usr/share/doc/libgpg-error-1.21/README
	cd ..
	rm -rvf libgpg-error-1.21
	let "STEP++"
fi

#npth-1.2
if [ $STEP -eq 4 ]; then
	tar -xvf npth-1.2.tar.bz2
	cd npth-1.2
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf npth-1.2
	let "STEP++"
fi

#nettle-3.2
if [ $STEP -eq 5 ]; then
	tar -xvf nettle-3.2.tar.gz
	cd nettle-3.2
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	chmod -v 755 /usr/lib/lib{hogweed,nettle}.so
	install -v -m755 -d /usr/share/doc/nettle-3.2
	install -v -m644 nettle.html /usr/share/doc/nettle-3.2
	cd ..
	rm -rvf nettle-3.2
	let "STEP++"
fi

#libtasn1-4.7
if [ $STEP -eq 6 ]; then
	tar -xvf libtasn1-4.7.tar.gz
	cd libtasn1-4.7
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libtasn1-4.7
	let "STEP++"
fi

#libffi-3.2.1
if [ $STEP -eq 7 ]; then
	tar -xvf libffi-3.2.1.tar.gz
	cd libffi-3.2.1
	sed -e '/^includesdir/ s/$(libdir).*$/$(includedir)/' -i include/Makefile.in
	sed -e '/^includedir/ s/=.*$/=@includedir@/' -e 's/^Cflags: -I${includedir}/Cflags:/' -i libffi.pc.in
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libffi-3.2.1
	let "STEP++"
fi

#iptables-1.6.0
if [ $STEP -eq 8 ]; then
	tar -xvf iptables-1.6.0.tar.bz2
	cd iptables-1.6.0
	./configure \
		--prefix=/usr \
		--sbindir=/sbin \
		--disable-nftables \
		--enable-libipq \
		--with-xtlibdir=/lib/xtables
	make -j $JOBS
	make -j $JOBS install
	ln -sfv /sbin/xtables-multi /usr/bin/iptables-xml
	for file in ip4tc ip6tc ipq iptc xtables
	do
		mv -v /usr/lib/lib${file}.so.* /lib
		ln -sfv /lib/$(readlink /usr/lib/lib${file}.so) /usr/lib/lib${file}.so
	done
	cd ..
	rm -rvf iptables-1.6.0
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-iptables
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#linux-pam-1.2.1
if [ $STEP -eq 9 ]; then
	tar -xvf Linux-PAM-1.2.1.tar.bz2
	cd Linux-PAM-1.2.1
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--libdir=/usr/lib \
		--enable-securedir=/lib/security \
		--docdir=/usr/share/doc/Linux-PAM-1.2.1
	make -j $JOBS
	install -v -m755 -d /etc/pam.d
	make -j $JOBS install
	chmod -v 4755 /sbin/unix_chkpwd
	for file in pam pam_misc pamc
	do
		mv -v /usr/lib/lib${file}.so.* /lib
		ln -sfv /lib/$(readlink /usr/lib/lib${file}.so) /usr/lib/lib${file}.so
	done
	cp -v /alfs/etc/pam.d/* /etc/pam.d
	cd ..
	rm -rvf Linux-PAM-1.2.1
	let "STEP++"
fi

#nspr-4.12
if [ $STEP -eq 10 ]; then
	tar -xvf nspr-4.12.tar.gz
	cd nspr-4.12
	cd nspr
	sed -ri 's#^(RELEASE_BINS =).*#\1#' pr/src/misc/Makefile.in
	sed -i 's#$(LIBRARY) ##' config/rules.mk
	./configure \
		--prefix=/usr \
		--with-mozilla \
		--with-pthreads \
		--enable-64bit
	make -j $JOBS
	make -j $JOBS install
	cd ../..
	rm -rvf nspr-4.12
	let "STEP++"
fi

#sqlite-3.11.0
if [ $STEP -eq 11 ]; then
	tar -xvf sqlite-autoconf-3110000.tar.gz
	cd sqlite-autoconf-3110000
	./configure \
		--prefix=/usr \
		--disable-static \
		CFLAGS="-g -O2 -DSQLITE_ENABLE_FTS3=1 \
		-DSQLITE_ENABLE_COLUMN_METADATA=1 \
		-DSQLITE_ENABLE_UNLOCK_NOTIFY=1 \
		-DSQLITE_SECURE_DELETE=1 \
		-DSQLITE_ENABLE_DBSTAT_VTAB=1"
	make -j 1
	make -j 1 install
	cd ..
	rm -rvf sqlite-autoconf-3110000
	let "STEP++"
fi

#pcre-8.38
if [ $STEP -eq 12 ]; then
	tar -xvf pcre-8.38.tar.bz2
	cd pcre-8.38
	./configure \
		--prefix=/usr \
		--docdir=/usr/share/doc/pcre-8.38 \
		--enable-unicode-properties \
		--enable-pcre16 \
		--enable-pcre32 \
		--enable-pcregrep-libz \
		--enable-pcregrep-libbz2 \
		--enable-pcretest-libreadline \
		--disable-static
	make -j $JOBS
	make -j $JOBS install
	mv -v /usr/lib/libpcre.so.* /lib
	ln -sfv /lib/$(readlink /usr/lib/libpcre.so) /usr/lib/libpcre.so
	cd ..
	rm -rvf pcre-8.38
	let "STEP++"
fi

#zip30
if [ $STEP -eq 13 ]; then
	tar -xvf zip30.tgz
	cd zip30
	make -j $JOBS -f unix/Makefile generic_gcc
	make -j $JOBS prefix=/usr MANDIR=/usr/share/man/man1 -f unix/Makefile install
	cd ..
	rm -rvf zip30
	let "STEP++"
fi

#lvm2-2.02.142
if [ $STEP -eq 14 ]; then
	tar -xvf LVM2.2.02.142.tgz
	cd LVM2.2.02.142
	./configure \
		--prefix=/usr \
		--exec-prefix= \
		--enable-applib \
		--enable-cmdlib \
		--enable-pkgconfig \
		--enable-udev_sync \
		--enable-dmeventd \
		--enable-lvmetad
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf LVM2.2.02.142
	let "STEP++"
fi

#iso-codes-3.65
if [ $STEP -eq 15 ]; then
	tar -xvf iso-codes-3.65.tar.xz
	cd iso-codes-3.65
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf iso-codes-3.65
	let "STEP++"
fi

#libtirpc-1.0.1
if [ $STEP -eq 16 ]; then
	tar -xvf libtirpc-1.0.1.tar.bz2
	cd libtirpc-1.0.1
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--disable-static \
		--disable-gssapi
	make -j $JOBS
	make -j $JOBS install
	mv -v /usr/lib/libtirpc.so.* /lib
	ln -sfv /lib/libtirpc.so.3.0.0 /usr/lib/libtirpc.so
	cd ..
	rm -rvf libtirpc-1.0.1
	let "STEP++"
fi

#screen-4.3.1
if [ $STEP -eq 17 ]; then
	tar -xvf screen-4.3.1.tar.gz
	cd screen-4.3.1
	./configure \
		--prefix=/usr \
		--infodir=/usr/share/info \
		--mandir=/usr/share/man \
		--with-socket-dir=/run/screen \
		--with-pty-group=5 \
		--with-sys-screenrc=/etc/screenrc
	sed -i -e "s%/usr/local/etc/screenrc%/etc/screenrc%" {etc,doc}/*
	make -j $JOBS
	make -j $JOBS install
	install -m 644 etc/etcscreenrc /etc/screenrc
	cd ..
	rm -rvf screen-4.3.1
	let "STEP++"
fi

#time-1.7
if [ $STEP -eq 18 ]; then
	tar -xvf time-1.7.tar.gz
	cd time-1.7
	sed -i 's/$(ACLOCAL)//' Makefile.in
	sed -i 's/lu", ptok ((UL) resp->ru.ru_maxrss)/ld", resp->ru.ru_maxrss/' time.c
	./configure --prefix=/usr --infodir=/usr/share/info
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf time-1.7
	let "STEP++"
fi

#unixodbc-2.3.4
if [ $STEP -eq 19 ]; then
	tar -xvf unixODBC-2.3.4.tar.gz
	cd unixODBC-2.3.4
	./configure --prefix=/usr --sysconfdir=/etc/unixODBC
	make -j $JOBS
	make -j $JOBS install
	find doc -name "Makefile*" -delete
	chmod 644 doc/{lst,ProgrammerManual/Tutorial}/*
	install -v -m755 -d /usr/share/doc/unixODBC-2.3.4
	cp -v -R doc/* /usr/share/doc/unixODBC-2.3.4
	cd ..
	rm -rvf unixODBC-2.3.4
	let "STEP++"
fi

#acpid-2.0.26
if [ $STEP -eq 20 ]; then
	tar -xvf acpid-2.0.26.tar.xz
	cd acpid-2.0.26
	./configure --prefix=/usr --docdir=/usr/share/doc/acpid-2.0.26
	make -j $JOBS
	make -j $JOBS install
	install -v -m755 -d /etc/acpi/events
	cp -rv samples /usr/share/doc/acpid-2.0.26
	cd ..
	rm -rvf acpid-2.0.26
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-acpid
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#libpng-1.6.21
if [ $STEP -eq 21 ]; then
	tar -xvf libpng-1.6.21.tar.xz
	cd libpng-1.6.21
	gzip -cd ../libpng-1.6.21-apng.patch.gz | patch -p0
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	mkdir -v /usr/share/doc/libpng-1.6.21
	cp -v README libpng-manual.txt /usr/share/doc/libpng-1.6.21
	cd ..
	rm -rvf libpng-1.6.21
fi

#which-2.21
if [ $STEP -eq 22 ]; then
	tar -xvf which-2.21.tar.gz
	cd which-2.21
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf which-2.21
	let "STEP++"
fi

#icu-56.1
if [ $STEP -eq 23 ]; then
	tar -xvf icu4c-56_1-src.tgz
	cd icu
	cd source
	CC=gcc CXX=g++ ./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ../..
	rm -rvf icu
	let "STEP++"
fi

#util-macros-1.19.0
if [ $STEP -eq 24 ]; then
	tar -xvf util-macros-1.19.0.tar.bz2
	cd util-macros-1.19.0
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--disable-static
    	make -j $JOBS install
	cd ..
	rm -rvf util-macros-1.19.0
	let "STEP++"
fi

#lcms-2.7
if [ $STEP -eq 25 ]; then
	tar -xvf lcms2-2.7.tar.gz
	cd lcms2-2.7
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf lcms2-2.7
	let "STEP++"
fi

#libusb-1.0.20
if [ $STEP -eq 26 ]; then
	tar -xvf libusb-1.0.20.tar.bz2
	cd libusb-1.0.20
	./configure --prefix=/usr --disable-static
	make -j1
	make -j1 install
	cd ..
	rm -rvf libusb-1.0.20
	let "STEP++"
fi

#cpio-2.12
if [ $STEP -eq 27 ]; then
	tar -xvf cpio-2.12.tar.bz2
	cd cpio-2.12
	./configure \
		--prefix=/usr \
		--bindir=/bin \
		--enable-mt \
		--with-rmt=/usr/libexec/rmt
	make -j $JOBS
	makeinfo --html -o doc/html doc/cpio.texi
	makeinfo --html --no-split -o doc/cpio.html doc/cpio.texi
	makeinfo --plaintext -o doc/cpio.txt doc/cpio.texi
	make -j $JOBS install
	install -v -m755 -d /usr/share/doc/cpio-2.12/html
	install -v -m644 doc/html/* /usr/share/doc/cpio-2.12/html
	install -v -m644 doc/cpio.{html,txt} /usr/share/doc/cpio-2.12
	cd ..
	rm -rvf cpio-2.12
	let "STEP++"
fi

#gpm-1.20.7
if [ $STEP -eq 28 ]; then
	tar -xvf gpm-1.20.7.tar.bz2
	cd gpm-1.20.7
	./autogen.sh
	./configure --prefix=/usr --sysconfdir=/etc
	make -j $JOBS
	make -j $JOBS install
	install-info --dir-file=/usr/share/info/dir /usr/share/info/gpm.info
	ln -sfv libgpm.so.2.1.0 /usr/lib/libgpm.so
	install -v -m644 conf/gpm-root.conf /etc
	install -v -m755 -d /usr/share/doc/gpm-1.20.7/support
	install -v -m644 doc/support/* /usr/share/doc/gpm-1.20.7/support
	install -v -m644 doc/{FAQ,HACK_GPM,README*} /usr/share/doc/gpm-1.20.7
	cp -v /alfs/etc/sysconfig/mouse /etc/sysconfig/mouse
	cd ..
	rm -rvf gpm-1.20.7
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-gpm
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#popt-1.16
if [ $STEP -eq 29 ]; then
	tar -xvf popt-1.16.tar.gz
	cd popt-1.16
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf popt-1.16
	let "STEP++"
fi

#pciutils-3.4.1
if [ $STEP -eq 30 ]; then
	tar -xvf pciutils-3.4.1.tar.xz
	cd pciutils-3.4.1
	make -j $JOBS \
		PREFIX=/usr \
		SHAREDIR=/usr/share/hwdata \
		SHARED=yes
    	make -j $JOBS \
		PREFIX=/usr \
		SHAREDIR=/usr/share/hwdata \
		SHARED=yes \
		install install-lib
	chmod -v 755 /usr/lib/libpci.so
	echo '@ 1d update-pciids' >> /etc/fcrontab
	#fcrontab /etc/fcrontab systab (Cannot be run because fcron is not installed already, but it will be run by other package installations later)
	cd ..
	rm -rvf pciutils-3.4.1
	let "STEP++"
fi

#pm-utils-1.4.1
if [ $STEP -eq 31 ]; then
	tar -xvf pm-utils-1.4.1.tar.gz
	cd pm-utils-1.4.1
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--docdir=/usr/share/doc/pm-utils-1.4.1
	make -j $JOBS
	make -j $JOBS install
	install -v -m644 man/*.1 /usr/share/man/man1
	install -v -m644 man/*.8 /usr/share/man/man8
	ln -sv pm-action.8 /usr/share/man/man8/pm-suspend.8
	ln -sv pm-action.8 /usr/share/man/man8/pm-hibernate.8
	ln -sv pm-action.8 /usr/share/man/man8/pm-suspend-hybrid.8
	cd ..
	rm -rvf pm-utils-1.4.1
	let "STEP++"
fi

#sgml-common-0.6.3
if [ $STEP -eq 32 ]; then
	tar -xvf sgml-common-0.6.3.tgz
	cd sgml-common-0.6.3
	patch -Np1 -i ../sgml-common-0.6.3-manpage-1.patch
	autoreconf -f -i
	./configure --prefix=/usr --sysconfdir=/etc
	make -j $JOBS
	make -j $JOBS docdir=/usr/share/doc install
	install-catalog --add /etc/sgml/sgml-ent.cat /usr/share/sgml/sgml-iso-entities-8879.1986/catalog
	install-catalog --add /etc/sgml/sgml-docbook.cat /etc/sgml/sgml-ent.cat
	cd ..
	rm -rvf sgml-common-0.6.3
	let "STEP++"
fi

#unzip60
if [ $STEP -eq 33 ]; then
	tar -xvf unzip60.tar.gz
	cd unzip60
	make -j $JOBS -f unix/Makefile generic
	make -j $JOBS \
		prefix=/usr \
		MANDIR=/usr/share/man/man1 \
		-f unix/Makefile install
	cd ..
	rm -rvf unzip60
	let "STEP++"
fi

#libatasmart-0.19
if [ $STEP -eq 34 ]; then
	tar -xvf libatasmart-0.19.tar.xz
	cd libatasmart-0.19
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS docdir=/usr/share/doc/libatasmart-0.19 install
	cd ..
	rm -rvf libatasmart-0.19
	let "STEP++"
fi

#unrar-5.3.11
if [ $STEP -eq 35 ]; then
	tar -xvf unrarsrc-5.3.11.tar.gz
	cd unrar
	make -j $JOBS -f makefile
	install -v -m755 unrar /usr/bin
	cd ..
	rm -rvf unrar
	let "STEP++"
fi

#libarchive-3.1.2
if [ $STEP -eq 36 ]; then
	tar -xvf libarchive-3.1.2.tar.gz
	cd libarchive-3.1.2
	patch -Np1 -i ../libarchive-3.1.2-upstream_fixes-1.patch
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libarchive-3.1.2
	let "STEP++"
fi

#elfutils-0.165
if [ $STEP -eq 37 ]; then
	tar -xvf elfutils-0.165.tar.bz2
	cd elfutils-0.165
	./configure --prefix=/usr --program-prefix="eu-"
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf elfutils-0.165
	let "STEP++"
fi

#npapi-sdk-0.27.2
if [ $STEP -eq 38 ]; then
	tar -xvf npapi-sdk-0.27.2.tar.bz2
	cd npapi-sdk-0.27.2
	./configure --prefix=/usr
	make -j $JOBS install
	cd ..
	rm -rvf npapi-sdk-0.27.2
	let "STEP++"
fi

#module-build-0.4216
if [ $STEP -eq 39 ]; then
	tar -xvf Module-Build-0.4216.tar.gz
	cd Module-Build-0.4216
	perl Makefile.PL
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf Module-Build-0.4216
	let "STEP++"
fi

#uri-1.71
if [ $STEP -eq 40 ]; then
	tar -xvf URI-1.71.tar.gz
	cd URI-1.71
	perl Makefile.PL
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf URI-1.71
	let "STEP++"
fi

#pixman-0.34.0
if [ $STEP -eq 41 ]; then
	tar -xvf pixman-0.34.0.tar.gz
	cd pixman-0.34.0
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf pixman-0.34.0
	let "STEP++"
fi

#yasm-1.3.0
if [ $STEP -eq 42 ]; then
	tar -xvf yasm-1.3.0.tar.gz
	cd yasm-1.3.0
	sed -i 's#) ytasm.*#)#' Makefile.in
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf yasm-1.3.0
	let "STEP++"
fi

#tiff-4.0.6
if [ $STEP -eq 43 ]; then
	tar -xvf tiff-4.0.6.tar.gz
	cd tiff-4.0.6
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf tiff-4.0.6
	let "STEP++"
fi

#hicolor-icon-theme-0.15
if [ $STEP -eq 44 ]; then
	tar -xvf hicolor-icon-theme-0.15.tar.xz
	cd hicolor-icon-theme-0.15
	./configure --prefix=/usr
	make -j $JOBS install
	cd ..
	rm -rvf hicolor-icon-theme-0.15
	let "STEP++"
fi

#ruby-2.3.0
if [ $STEP -eq 45 ]; then
	tar -xvf ruby-2.3.0.tar.xz
	cd ruby-2.3.0
	./configure \
		--prefix=/usr \
		--enable-shared \
		--docdir=/usr/share/doc/ruby-2.3.0 \
		--disable-install-doc
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf ruby-2.3.0
	let "STEP++"
fi

#dhcpcd-6.10.1
if [ $STEP -eq 46 ]; then
	tar -xvf dhcpcd-6.10.1.tar.xz
	cd dhcpcd-6.10.1
	./configure --libexecdir=/lib/dhcpcd --dbdir=/var/lib/dhcpcd
	make -j $JOBS
	make -j $JOBS install
	cp -v /alfs/etc/sysconfig/*.ifconfig.example /etc/sysconfig
	cp -v /alfs/etc/resolv.conf /etc/resolv.conf
	cd ..
	rm -rvf dhcpcd-6.10.1
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-service-dhcpcd
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#bridge-utils-1.5
if [ $STEP -eq 47 ]; then
	tar -xvf bridge-utils-1.5.tar.gz
	cd bridge-utils-1.5
	patch -Np1 -i ../bridge-utils-1.5-linux_3.8_fix-1.patch
	autoconf -o configure configure.in
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cp -v /alfs/etc/sysconfig/bridge.ifconfig.example /etc/sysconfig/bridge.ifconfig.example
	cd ..
	rm -rvf bridge-utils-1.5
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-service-bridge
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#net-tools-cvs-20101030
if [ $STEP -eq 48 ]; then
	tar -xvf net-tools-CVS_20101030.tar.gz
	cd net-tools-CVS_20101030
	patch -Np1 -i ../net-tools-CVS_20101030-remove_dups-1.patch
	yes "" | make config
	make -j $JOBS
	make -j $JOBS update
	cd ..
	rm -rvf net-tools-CVS_20101030
	let "STEP++"
fi

#rclone-v1.28
if [ $STEP -eq 49 ]; then
	unzip rclone-v1.28-linux-amd64.zip
	cd rclone-v1.28-linux-amd64
	cp -v rclone /usr/bin/
	chown root:root /usr/bin/rclone
	chmod 755 /usr/bin/rclone
	mkdir -pv /usr/share/man/man1
	cp -v rclone.1 /usr/share/man/man1/
	mandb
	cd ..
	rm -rvf rclone-v1.28-linux-amd64
	let "STEP++"
fi

#wireless-tools-29
if [ $STEP -eq 50 ]; then
	tar -xvf wireless_tools.29.tar.gz
	cd wireless_tools.29
	make -j $JOBS
	make -j $JOBS PREFIX=/usr INSTALL_MAN=/usr/share/man install
	cd ..
	rm -rvf wireless_tools.29
	let "STEP++"
fi

#libnl-3.2.27
if [ $STEP -eq 51 ]; then
	tar -xvf libnl-3.2.27.tar.gz
	cd libnl-3.2.27
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libnl-3.2.27
	let "STEP++"
fi

#adwaita-icon-theme-3.18.0
if [ $STEP -eq 52 ]; then
	tar -xvf adwaita-icon-theme-3.18.0.tar.xz
	cd adwaita-icon-theme-3.18.0
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf adwaita-icon-theme-3.18.0
	let "STEP++"
fi

#libdaemon-0.14
if [ $STEP -eq 53 ]; then
	tar -xvf libdaemon-0.14.tar.gz
	cd libdaemon-0.14
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS docdir=/usr/share/doc/libdaemon-0.14 install
	cd ..
	rm -rvf libdaemon-0.14
	let "STEP++"
fi

#bind-9.10.3-p3
if [ $STEP -eq 54 ]; then
	tar -xvf bind-9.10.3-P3.tar.gz
	cd bind-9.10.3-P3
	./configure --prefix=/usr
	make -j $JOBS -C lib/dns
	make -j $JOBS -C lib/isc
	make -j $JOBS -C lib/bind9
	make -j $JOBS -C lib/isccfg
	make -j $JOBS -C lib/lwres
	make -j $JOBS -C bin/dig
	make -j $JOBS -C bin/dig install
	cd ..
	rm -rvf bind-9.10.3-P3
	let "STEP++"
fi

#libpcap-1.7.4
if [ $STEP -eq 55 ]; then
	tar -xvf libpcap-1.7.4.tar.gz
	cd libpcap-1.7.4
	patch -Np1 -i ../libpcap-1.7.4-enable_bluetooth-1.patch
	./configure --prefix=/usr
	make -j $JOBS
	sed -i '/INSTALL_DATA.*libpcap.a\|RANLIB.*libpcap.a/ s/^/#/' Makefile
	make -j $JOBS install
	cd ..
	rm -rvf libpcap-1.7.4
	let "STEP++"
fi

#liblinear-2.1
if [ $STEP -eq 56 ]; then
	tar -xvf liblinear-2.1.tar.gz
	cd liblinear-2.1
	make -j $JOBS lib
	install -vm644 linear.h /usr/include
	install -vm755 liblinear.so.3 /usr/lib
	ln -sfv liblinear.so.3 /usr/lib/liblinear.so
	cd ..
	rm -rvf liblinear-2.1
	let "STEP++"
fi

#traceroute-2.0.21
if [ $STEP -eq 57 ]; then
	tar -xvf traceroute-2.0.21.tar.gz
	cd traceroute-2.0.21
	make -j $JOBS
	make -j $JOBS prefix=/usr install
	mv -v /usr/bin/traceroute /bin
	ln -svf traceroute /bin/traceroute6
	ln -svf traceroute.8 /usr/share/man/man8/traceroute6.8
	rm -fv /usr/share/man/man1/traceroute.1
	cd ..
	rm -rvf traceroute-2.0.21
	let "STEP++"
fi

#whois-5.2.11
if [ $STEP -eq 58 ]; then
	tar -xvf whois_5.2.11.tar.xz
	cd whois-5.2.11
	make -j $JOBS
	make -j $JOBS prefix=/usr install-whois
	make -j $JOBS prefix=/usr install-mkpasswd
	make -j $JOBS prefix=/usr install-pos
	cd ..
	rm -rvf whois-5.2.11
	let "STEP++"
fi

#mtdev-1.1.5
if [ $STEP -eq 59 ]; then
	tar -xvf mtdev-1.1.5.tar.bz2
	cd mtdev-1.1.5
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf mtdev-1.1.5
	let "STEP++"
fi

#sdl-1.2.15
if [ $STEP -eq 60 ]; then
	tar -xvf SDL-1.2.15.tar.gz
	cd SDL-1.2.15
	sed -e '/_XData32/s:register long:register _Xconst long:' -i src/video/x11/SDL_x11sym.h
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	install -v -m755 -d /usr/share/doc/SDL-1.2.15/html
	install -v -m644 docs/html/*.html /usr/share/doc/SDL-1.2.15/html
	cd ..
	rm -rvf SDL-1.2.15
	let "STEP++"
fi

#lxde-icon-theme-0.5.1
if [ $STEP -eq 61 ]; then
	tar -xvf lxde-icon-theme-0.5.1.tar.xz
	cd lxde-icon-theme-0.5.1
	./configure --prefix=/usr
	make -j $JOBS install
	cd ..
	rm -rvf lxde-icon-theme-0.5.1
	let "STEP++"
fi

#libogg-1.3.2
if [ $STEP -eq 62 ]; then
	tar -xvf libogg-1.3.2.tar.xz
	cd libogg-1.3.2
	./configure \
		--prefix=/usr \
		--disable-static \
		--docdir=/usr/share/doc/libogg-1.3.2
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libogg-1.3.2
	let "STEP++"
fi

#alsa-lib-1.1.0
if [ $STEP -eq 63 ]; then
	tar -xvf alsa-lib-1.1.0.tar.bz2
	cd alsa-lib-1.1.0
	./configure
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf alsa-lib-1.1.0
	let "STEP++"
fi

#flac-1.3.1
if [ $STEP -eq 64 ]; then
	tar -xvf flac-1.3.1.tar.xz
	cd flac-1.3.1
	./configure --prefix=/usr --disable-thorough-tests
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf flac-1.3.1
	let "STEP++"
fi

#libexif-0.6.21
if [ $STEP -eq 65 ]; then
	tar -xvf libexif-0.6.21.tar.bz2
	cd libexif-0.6.21
	./configure \
		--prefix=/usr \
		--with-doc-dir=/usr/share/doc/libexif-0.6.21 \
		--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libexif-0.6.21
	let "STEP++"
fi

#apr-1.5.2
if [ $STEP -eq 66 ]; then
	tar -xvf apr-1.5.2.tar.bz2
	cd apr-1.5.2
	./configure \
		--prefix=/usr \
		--disable-static \
		--with-installbuilddir=/usr/share/apr-1/build
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf apr-1.5.2
	let "STEP++"
fi

#ijs-0.35
if [ $STEP -eq 67 ]; then
	tar -xvf ijs-0.35.tar.bz2
	cd ijs-0.35
	./configure \
		--prefix=/usr \
		--mandir=/usr/share/man \
		--enable-shared \
		--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf ijs-0.35
	let "STEP++"
fi

#openjpeg-1.5.2
if [ $STEP -eq 68 ]; then
	tar -xvf openjpeg-1.5.2.tar.gz
	cd openjpeg-1.5.2
	autoreconf -f -i
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf openjpeg-1.5.2
	let "STEP++"
fi

#libatomic-7.4.2
if [ $STEP -eq 69 ]; then
	tar -xvf libatomic_ops-7.4.2.tar.gz
	cd libatomic_ops-7.4.2
	sed -i 's#pkgdata#doc#' doc/Makefile.am
	autoreconf -fi
	./configure \
		--prefix=/usr \
		--enable-shared  \
		--disable-static \
		--docdir=/usr/share/doc/libatomic_ops-7.4.2
	make -j $JOBS
	make -j $JOBS install
	mv -v /usr/share/libatomic_ops/* /usr/share/doc/libatomic_ops-7.4.2
	rm -rvf /usr/share/libatomic_ops
	cd ..
	rm -rvf libatomic_ops-7.4.2
	let "STEP++"
fi

#postgresql-9.5.1
if [ $STEP -eq 70 ]; then
	tar -xvf postgresql-9.5.1.tar.bz2
	cd postgresql-9.5.1
	sed -i '/DEFAULT_PGSOCKET_DIR/s@/tmp@/run/postgresql@' src/include/pg_config_manual.h
	./configure \
		--prefix=/usr \
		--enable-thread-safety \
		--docdir=/usr/share/doc/postgresql-9.5.1
	make -j $JOBS
	make -j $JOBS install
	make -j $JOBS install-docs
	install -v -dm700 /srv/pgsql/data
	install -v -dm755 /run/postgresql
	groupadd -g 41 postgres
	useradd -c "PostgreSQL Server" -g postgres -d /srv/pgsql/data -u 41 postgres
	chown -Rv postgres:postgres /srv/pgsql /run/postgresql
	su - postgres -c '/usr/bin/initdb -D /srv/pgsql/data'
	cd ..
	rm -rvf postgresql-9.5.1
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-postgresql
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#babl-0.1.14
if [ $STEP -eq 71 ]; then
	tar -xvf babl-0.1.14.tar.bz2
	cd babl-0.1.14
	./configure --prefix=/usr --disable-docs
	make -j $JOBS
	make -j $JOBS install
	install -v -m755 -d /usr/share/gtk-doc/html/babl/graphics
	install -v -m644 docs/*.{css,html} /usr/share/gtk-doc/html/babl
	install -v -m644 docs/graphics/*.{html,png,svg} /usr/share/gtk-doc/html/babl/graphics
	cd ..
	rm -rvf babl-0.1.14
	let "STEP++"
fi

#lynx-2.8.8rel.2
if [ $STEP -eq 72 ]; then
	tar -xvf lynx2.8.8rel.2.tar.bz2
	cd lynx2-8-8
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc/lynx \
		--datadir=/usr/share/doc/lynx-2.8.8rel.2 \
		--with-zlib \
		--with-bzlib \
		--with-screen=ncursesw \
		--enable-locale-charset
	make -j $JOBS
	make -j $JOBS install-full
	chgrp -v -R root /usr/share/doc/lynx-2.8.8rel.2/lynx_doc
	sed -e '/#LOCALE/a LOCALE_CHARSET:TRUE' -i /etc/lynx/lynx.cfg
	sed -e '/#DEFAULT_ED/a DEFAULT_EDITOR:nano' -i /etc/lynx/lynx.cfg
	cd ..
	rm -rvf lynx2-8-8
	let "STEP++"
fi

#sane-1.0.25
if [ $STEP -eq 73 ]; then
	tar -xvf sane-backends-1.0.25.tar.gz
	cd sane-backends-1.0.25
	groupadd -g 70 scanner
	usermod -aG scanner root
	su -c './configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--with-group=scanner \
		--with-docdir=/usr/share/doc/sane-backend-1.0.25 \
		--enable-libusb_1_0'
   	export JOBS
	su -c 'make -j $JOBS'
	export -n JOBS
	rm -v /var/lock #make install fails when /var/lock file already exists
	make -j $JOBS install
	install -m 644 -v tools/udev/libsane.rules /etc/udev/rules.d/65-scanner.rules
	chgrp -v scanner /var/lock/sane
	cd ..
	rm -rvf sane-backends-1.0.25
	let "STEP++"
fi

#cifs-utils-6.4
if [ $STEP -eq 74 ]; then
	tar -xvf cifs-utils-6.4.tar.bz2
	cd cifs-utils-6.4
	./configure \
		--prefix=/usr \
		--disable-pam \
		--disable-systemd
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf cifs-utils-6.4
	let "STEP++"
fi

#libsigc++-2.6.2
if [ $STEP -eq 75 ]; then
	tar -xvf libsigc++-2.6.2.tar.xz
	cd libsigc++-2.6.2
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libsigc++-2.6.2
	let "STEP++"
fi

#-------------------------------------------------------
#Next packages need at least one package installed above
#-------------------------------------------------------

#certdata
#rebuilded openssl in order for make-ca.sh script to be successfull
if [ $STEP -eq 76 ]; then
	cd /alfs/certs
	cp -v make-cert.pl /usr/bin
	chmod +x /usr/bin/make-cert.pl
	cp -v make-ca.sh /usr/bin
	chmod +x /usr/bin/make-ca.sh
	cp -v remove-expired-certs.sh /usr/sbin
	chmod u+x /usr/sbin/remove-expired-certs.sh
	cp -v update-certs.sh /usr/bin/update-certs.sh
	chmod +x /usr/bin/update-certs.sh
	cd /sources
	make-ca.sh
	SSLDIR=/etc/ssl
	remove-expired-certs.sh certs
	install -d ${SSLDIR}/certs
	cp -v certs/*.pem ${SSLDIR}/certs
	c_rehash
	install BLFS-ca-bundle*.crt ${SSLDIR}/ca-bundle.crt
	ln -sfv ../ca-bundle.crt ${SSLDIR}/certs/ca-certificates.crt
	unset SSLDIR
	rm -rvf certs BLFS-ca-bundle*
	echo '@ 1d update-certs.sh' >> /etc/fcrontab
	#fcrontab /etc/fcrontab systab (Cannot be run because fcron is not installed already, but it will be run by other package installations later)
	let "STEP++"
fi

#cyrus-sasl-2.1.26
if [ $STEP -eq 77 ]; then
	tar -xvf cyrus-sasl-2.1.26.tar.gz
	cd cyrus-sasl-2.1.26
	patch -Np1 -i ../cyrus-sasl-2.1.26-fixes-3.patch
	autoreconf -fi
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--enable-auth-sasldb \
		--with-dbpath=/var/lib/sasl/sasldb2 \
		--with-saslauthd=/var/run/saslauthd
	make -j $JOBS
	make -j $JOBS install
	install -v -dm755 /usr/share/doc/cyrus-sasl-2.1.26
	install -v -m644 doc/{*.{html,txt,fig},ONEWS,TODO} saslauthd/LDAP_SASLAUTHD /usr/share/doc/cyrus-sasl-2.1.26
	install -v -dm700 /var/lib/sasl
	cd ..
	rm -rvf cyrus-sasl-2.1.26
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-saslauthd
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#libassuan-2.4.2
if [ $STEP -eq 78 ]; then
	tar -xvf libassuan-2.4.2.tar.bz2
	cd libassuan-2.4.2
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libassuan-2.4.2
	let "STEP++"
fi

#libgcrypt-1.6.5
if [ $STEP -eq 79 ]; then
	tar -xvf libgcrypt-1.6.5.tar.bz2
	cd libgcrypt-1.6.5
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	install -v -dm755 /usr/share/doc/libgcrypt-1.6.5
	install -v -m644 README doc/{README.apichanges,fips*,libgcrypt*} /usr/share/doc/libgcrypt-1.6.5
	cd ..
	rm -rvf libgcrypt-1.6.5
	let "STEP++"
fi

#libksba-1.3.3
if [ $STEP -eq 80 ]; then
	tar -xvf libksba-1.3.3.tar.bz2
	cd libksba-1.3.3
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libksba-1.3.3
	let "STEP++"
fi

#nss-3.23
if [ $STEP -eq 81 ]; then
	tar -xvf nss-3.23.tar.gz
	cd nss-3.23
	patch -Np1 -i ../nss-3.23-standalone-1.patch
	cd nss
	make -j1 \
		BUILD_OPT=1 \
		NSPR_INCLUDE_DIR=/usr/include/nspr \
		USE_SYSTEM_ZLIB=1 \
		ZLIB_LIBS=-lz \
		USE_64=1 \
		NSS_USE_SYSTEM_SQLITE=1
	cd ../dist
	install -v -m755 Linux*/lib/*.so /usr/lib
	install -v -m644 Linux*/lib/{*.chk,libcrmf.a} /usr/lib
	install -v -m755 -d /usr/include/nss
	cp -v -RL {public,private}/nss/* /usr/include/nss
	chmod -v 644 /usr/include/nss/*
	install -v -m755 Linux*/bin/{certutil,nss-config,pk12util} /usr/bin
	install -v -m644 Linux*/lib/pkgconfig/nss.pc /usr/lib/pkgconfig
	cd ../..
	rm -rvf nss-3.23
	let "STEP++"
fi

#openssh-7.1p2
if [ $STEP -eq 82 ]; then
	tar -xvf openssh-7.1p2.tar.gz
	cd openssh-7.1p2
	install -v -m700 -d /var/lib/sshd
	chown -v root:sys /var/lib/sshd
	groupadd -g 50 sshd
	useradd \
		-c 'sshd PrivSep' \
		-d /var/lib/sshd \
		-g sshd \
		-s /bin/false \
		-u 50 sshd
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc/ssh \
		--with-md5-passwords \
		--with-privsep-path=/var/lib/sshd \
		--with-pam \
		--with-xauth=/usr/bin/xauth
	make -j $JOBS
	make -j $JOBS install
	install -v -m755 contrib/ssh-copy-id /usr/bin
	install -v -m644 contrib/ssh-copy-id.1 /usr/share/man/man1
	install -v -m755 -d /usr/share/doc/openssh-7.1p2
	install -v -m644 INSTALL LICENCE OVERVIEW README* /usr/share/doc/openssh-7.1p2
	sed 's@d/login@d/sshd@g' /etc/pam.d/login > /etc/pam.d/sshd
	chmod 644 /etc/pam.d/sshd
	echo "UsePAM yes" >> /etc/ssh/sshd_config
	cd ..
	rm -rvf openssh-7.1p2
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-sshd
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#python-2.7.11
if [ $STEP -eq 83 ]; then
	tar -xvf Python-2.7.11.tar.xz
	cd Python-2.7.11
	./configure \
		--prefix=/usr \
		--enable-shared \
		--with-system-expat \
		--with-system-ffi \
		--enable-unicode=ucs4
	make -j $JOBS
	make -j $JOBS install
	chmod -v 755 /usr/lib/libpython2.7.so.1.0
	cd ..
	rm -rvf Python-2.7.11
	let "STEP++"
fi

#python-3.5.1
if [ $STEP -eq 84 ]; then
	tar -xvf Python-3.5.1.tar.xz
	cd Python-3.5.1
	CXX="/usr/bin/g++" \
	./configure \
		--prefix=/usr \
		--enable-shared \
		--with-system-expat \
		--with-system-ffi \
		--without-ensurepip
	make -j $JOBS
	make -j $JOBS install
	chmod -v 755 /usr/lib/libpython3.5m.so
	chmod -v 755 /usr/lib/libpython3.so
	cd ..
	rm -rvf Python-3.5.1
	let "STEP++"
fi

#shadow-4.2.1
if [ $STEP -eq 85 ]; then
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
	install -v -m644 /etc/login.defs /etc/login.defs.orig
	for FUNCTION in FAIL_DELAY \
		FAILLOG_ENAB \
		LASTLOG_ENAB \
		MAIL_CHECK_ENAB \
		OBSCURE_CHECKS_ENAB \
		PORTTIME_CHECKS_ENAB \
		QUOTAS_ENAB \
		CONSOLE MOTD_FILE \
		FTMP_FILE NOLOGINS_FILE \
		ENV_HZ PASS_MIN_LEN \
		SU_WHEEL_ONLY \
		CRACKLIB_DICTPATH \
		PASS_CHANGE_TRIES \
		PASS_ALWAYS_WARN \
		CHFN_AUTH ENCRYPT_METHOD \
		ENVIRON_FILE
	do
		sed -i "s/^${FUNCTION}/# &/" /etc/login.defs
	done
	cp -v /alfs/etc/pam.d/* /etc/pam.d
	for PROGRAM in chfn \
		chgpasswd \
		chpasswd \
		chsh \
		groupadd \
		groupdel \
		groupmems \
		groupmod \
		newusers \
		useradd \
		userdel \
		usermod
	do
		install -v -m644 /etc/pam.d/chage /etc/pam.d/${PROGRAM}
		sed -i "s/chage/${PROGRAM}/" /etc/pam.d/${PROGRAM}
	done
	[ -f /etc/login.access ] && mv -v /etc/login.access{,.NOUSE}
	[ -f /etc/limits ] && mv -v /etc/limits{,.NOUSE}
	cd ..
	rm -rvf shadow-4.2.1
	let "STEP++"
fi

#sudo-1.8.15
if [ $STEP -eq 86 ]; then
	tar -xvf sudo-1.8.15.tar.gz
	cd sudo-1.8.15
	./configure \
		--prefix=/usr \
		--libexecdir=/usr/lib \
		--with-secure-path \
		--with-all-insults \
		--with-env-editor \
		--docdir=/usr/share/doc/sudo-1.8.15 \
		--with-passprompt="[sudo] password for %p" \
		--disable-static
	make -j $JOBS
	make -j $JOBS install
	ln -sfv libsudo_util.so.0.0.0 /usr/lib/sudo/libsudo_util.so.0
	cp -v /alfs/etc/pam.d/sudo /etc/pam.d/sudo
	chmod 644 /etc/pam.d/sudo
	cd ..
	rm -rvf sudo-1.8.15
	let "STEP++"
fi

#parted-3.2
if [ $STEP -eq 87 ]; then
	tar -xvf parted-3.2.tar.xz
	cd parted-3.2
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS -C doc html
	makeinfo --html -o doc/html doc/parted.texi
	makeinfo --plaintext -o doc/parted.txt doc/parted.texi
	make -j $JOBS install
	install -v -m755 -d /usr/share/doc/parted-3.2/html
	install -v -m644 doc/html/* /usr/share/doc/parted-3.2/html
	install -v -m644 doc/{FAT,API,parted.{txt,html}} /usr/share/doc/parted-3.2
	cd ..
	rm -rvf parted-3.2
	let "STEP++"
fi

#lsof-4.89
if [ $STEP -eq 88 ]; then
	tar -xvf lsof_4.89.tar.bz2
	cd lsof_4.89
	tar -xvf lsof_4.89_src.tar
	cd lsof_4.89_src
	./Configure -n linux
	make -j $JOBS CFGL="-L./lib -ltirpc"
	install -v -m0755 -o root -g root lsof /usr/bin
	install -v lsof.8 /usr/share/man/man8
	cd ../..
	rm -rvf lsof_4.89
	let "STEP++"
fi

#freetype-2.6.3
if [ $STEP -eq 89 ]; then
	tar -xvf freetype-2.6.3.tar.bz2
	cd freetype-2.6.3
	sed -e "/AUX.*.gxvalid/s@^# @@" -e "/AUX.*.otvalid/s@^# @@" -i modules.cfg
	sed -r -e 's:.*(#.*SUBPIXEL.*) .*:\1:' -i include/freetype/config/ftoption.h
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	install -v -m755 -d /usr/share/doc/freetype-2.6.3
	cp -v -R docs/* /usr/share/doc/freetype-2.6.3
	cd ..
	rm -rvf freetype-2.6.3
	let "STEP++"
fi

#xorg-protocol-headers
if [ $STEP -eq 38 ]; then
	for package in bigreqsproto-1.1.2.tar.bz2 \
		compositeproto-0.4.2.tar.bz2 \
		damageproto-1.2.1.tar.bz2 \
		dmxproto-2.3.1.tar.bz2 \
		dri2proto-2.8.tar.bz2 \
		dri3proto-1.0.tar.bz2 \
		fixesproto-5.0.tar.bz2 \
		fontsproto-2.1.3.tar.bz2 \
		glproto-1.4.17.tar.bz2 \
		inputproto-2.3.1.tar.bz2 \
		kbproto-1.0.7.tar.bz2 \
		presentproto-1.0.tar.bz2 \
		randrproto-1.5.0.tar.bz2 \
		recordproto-1.14.2.tar.bz2 \
		renderproto-0.11.1.tar.bz2 \
		resourceproto-1.2.0.tar.bz2 \
		scrnsaverproto-1.2.2.tar.bz2 \
		videoproto-2.3.2.tar.bz2 \
		xcmiscproto-1.2.2.tar.bz2 \
		xextproto-7.3.0.tar.bz2 \
		xf86bigfontproto-1.2.0.tar.bz2 \
		xf86dgaproto-2.1.tar.bz2 \
		xf86driproto-2.1.1.tar.bz2 \
		xf86vidmodeproto-2.3.1.tar.bz2 \
		xineramaproto-1.2.1.tar.bz2 \
		xproto-7.0.28.tar.bz2
	do
		packagedir=${package%.tar.bz2}
		tar -xvf $package
		pushd $packagedir
		./configure \
			--prefix=/usr \
			--sysconfdir=/etc \
	    		--localstatedir=/var \
	    		--disable-static
		make -j $JOBS install
		popd
		rm -rvf $packagedir
	done
	let "STEP++"
fi

#usbutils-008
if [ $STEP -eq 77 ]; then
	tar -xvf usbutils-008.tar.xz
	cd usbutils-008
	sed -i '/^usbids/ s:usb.ids:hwdata/&:' lsusb.py
	./configure --prefix=/usr --datadir=/usr/share/hwdata
	make -j $JOBS
	make -j $JOBS install
	install -dm755 /usr/share/hwdata/
	#wget http://www.linux-usb.org/usb.ids -O /usr/share/hwdata/usb.ids (Cannot be run because wget is not already installed, but it will be run by fcron daily after its installation)
	echo '@ 1d wget http://www.linux-usb.org/usb.ids -O /usr/share/hwdata/usb.ids' >> /etc/fcrontab
	#fcrontab /etc/fcrontab systab (Cannot be run because fcron is not installed already, but it will be run by other package installations later)
	cd ..
	rm -rvf usbutils-008
	let "STEP++"
fi

#fcron-3.2.0
if [ $STEP -eq 51 ]; then
	tar -xvf fcron-3.2.0.src.tar.gz
	cd fcron-3.2.0
	echo 'cron.* -/var/log/cron.log' >> /etc/syslog.conf
	/etc/rc.d/init.d/sysklogd reload
	groupadd -g 22 fcron
	useradd -d /dev/null -c "Fcron User" -g fcron -s /bin/false -u 22 fcron
	./configure \
		--prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --without-sendmail \
        --with-boot-install=no \
        --with-systemdsystemunitdir=no \
        --with-editor=/usr/bin/nano
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf fcron-3.2.0
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-fcron
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#lm-sensors-3.4.0
if [ $STEP -eq 55 ]; then
	tar -xvf lm_sensors-3.4.0.tar.bz2
	cd lm_sensors-3.4.0
	make -j $JOBS PREFIX=/usr BUILD_STATIC_LIB=0 MANDIR=/usr/share/man
	make -j $JOBS PREFIX=/usr BUILD_STATIC_LIB=0 MANDIR=/usr/share/man install
	install -v -m755 -d /usr/share/doc/lm_sensors-3.4.0
	cp -rv README INSTALL doc/* /usr/share/doc/lm_sensors-3.4.0
	cd ..
	rm -rvf lm_sensors-3.4.0
	let "STEP++"
fi

#test-mockmodule-0.11
if [ $STEP -eq 84 ]; then
	tar -xvf Test-MockModule-0.11.tar.gz
	cd Test-MockModule-0.11
	perl Build.PL
	./Build
	./Build install
	cd ..
	rm -rvf Test-MockModule-0.11
	let "STEP++"
fi

#libjpeg-turbo-1.4.2
if [ $STEP -eq 55 ]; then
	tar -xvf libjpeg-turbo-1.4.2.tar.gz
	cd libjpeg-turbo-1.4.2
	sed -i -e '/^docdir/ s:$:/libjpeg-turbo-1.4.2:' Makefile.in
	./configure \
		--prefix=/usr \
        --mandir=/usr/share/man \
        --with-jpeg8 \
        --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libjpeg-turbo-1.4.2
	let "STEP++"
fi

#ntp-4.2.8p6
if [ $STEP -eq 94 ]; then
	tar -xvf ntp-4.2.8p6.tar.gz
	cd ntp-4.2.8p6
	groupadd -g 87 ntp
	useradd -c "Network Time Protocol" -d /var/lib/ntp -u 87 -g ntp -s /bin/false ntp
	./configure \
		--prefix=/usr \
        --bindir=/usr/sbin \
        --sysconfdir=/etc \
        --enable-linuxcaps \
        --with-lineeditlibs=readline \
        --docdir=/usr/share/doc/ntp-4.2.8p6
	make -j $JOBS
	make -j $JOBS install
	install -v -o ntp -g ntp -d /var/lib/ntp
	cp -v alfs/etc/ntp.conf /etc/ntp.conf
	echo '@ 3w update-leap' >> /etc/fcrontab
	cd ..
	rm -rvf ntp-4.2.8p6
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-ntpd
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#rsync-3.1.2
if [ $STEP -eq 95 ]; then
	tar -xvf rsync-3.1.2.tar.gz
	cd rsync-3.1.2
	groupadd -g 48 rsyncd
	useradd -c "rsyncd Daemon" -d /home/rsync -g rsyncd -s /bin/false -u 48 rsyncd
	./configure --prefix=/usr --without-included-zlib
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf rsync-3.1.2
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-rsyncd
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#wpa-supplicant-2.5
if [ $STEP -eq 99 ]; then
	tar -xvf wpa_supplicant-2.5.tar.gz
	cd wpa_supplicant-2.5
	echo 'CONFIG_BACKEND=file
CONFIG_CTRL_IFACE=y
CONFIG_DEBUG_FILE=y
CONFIG_DEBUG_SYSLOG=y
CONFIG_DEBUG_SYSLOG_FACILITY=LOG_DAEMON
CONFIG_DRIVER_NL80211=y
CONFIG_DRIVER_WEXT=y
CONFIG_DRIVER_WIRED=y
CONFIG_EAP_GTC=y
CONFIG_EAP_LEAP=y
CONFIG_EAP_MD5=y
CONFIG_EAP_MSCHAPV2=y
CONFIG_EAP_OTP=y
CONFIG_EAP_PEAP=y
CONFIG_EAP_TLS=y
CONFIG_EAP_TTLS=y
CONFIG_IEEE8021X_EAPOL=y
CONFIG_IPV6=y
CONFIG_LIBNL32=y
CONFIG_PEERKEY=y
CONFIG_PKCS12=y
CONFIG_READLINE=y
CONFIG_SMARTCARD=y
CONFIG_WPS=y
CFLAGS += -I/usr/include/libnl3' > wpa_supplicant/.config
	cd wpa_supplicant
	make -j $JOBS BINDIR=/sbin LIBDIR=/lib
	install -v -m755 wpa_{cli,passphrase,supplicant} /sbin/
	install -v -m644 doc/docbook/wpa_supplicant.conf.5 /usr/share/man/man5/
	install -v -m644 doc/docbook/wpa_{cli,passphrase,supplicant}.8 /usr/share/man/man8/
	cp -v /alfs/etc/sysconfig/wpa.*.ifconfig.example /etc/sysconfig
	cd ../..
	rm -rvf wpa_supplicant-2.5
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-service-wpa
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#nmap-7.01
if [ $STEP -eq 95 ]; then
	tar -xvf nmap-7.01.tar.bz2
	cd nmap-7.01
	./configure --prefix=/usr --with-liblua=included
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf nmap-7.01
	let "STEP++"
fi

#xbitmaps-1.1.1
if [ $STEP -eq 95 ]; then
	tar -xvf xbitmaps-1.1.1.tar.bz2
	cd xbitmaps-1.1.1
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
    	--localstatedir=/var \
    	--disable-static
    make -j $JOBS install
	cd ..
	rm -rvf xbitmaps-1.1.1
	let "STEP++"
fi

#libvorbis-1.3.5
if [ $STEP -eq 95 ]; then
	tar -xvf libvorbis-1.3.5.tar.xz
	cd libvorbis-1.3.5
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	install -v -m644 doc/Vorbis* /usr/share/doc/libvorbis-1.3.5
	cd ..
	rm -rvf libvorbis-1.3.5
	let "STEP++"
fi

#libvpx-1.5.0
if [ $STEP -eq 95 ]; then
	tar -xvf libvpx-1.5.0.tar.bz2
	cd libvpx-1.5.0
	sed -i 's/cp -p/cp/' build/make/Makefile
	mkdir libvpx-build
	cd libvpx-build
	../configure \
		--prefix=/usr \
         --enable-shared \
         --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ../..
	rm -rvf libvpx-1.5.0
	let "STEP++"
fi

#aspell-0.60.6.1
if [ $STEP -eq 95 ]; then
	tar -xvf aspell-0.60.6.1.tar.gz
	cd aspell-0.60.6.1
	./configure --prefix=/usr
	make -j $JOBS
	make install &&
	ln -svfn aspell-0.60 /usr/lib/aspell
	install -v -m755 -d /usr/share/doc/aspell-0.60.6.1/aspell{,-dev}.html
	install -v -m644 manual/aspell.html/* /usr/share/doc/aspell-0.60.6.1/aspell.html
	install -v -m644 manual/aspell-dev.html/* /usr/share/doc/aspell-0.60.6.1/aspell-dev.html
	install -v -m 755 scripts/ispell /usr/bin/
	install -v -m 755 scripts/spell /usr/bin/
	cd ..
	rm -rvf aspell-0.60.6.1
	tar -xvf aspell6-en-2016.01.19-0.tar.bz2
	cd aspell6-en-2016.01.19-0
	./configure
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf aspell6-en-2016.01.19-0
	let "STEP++"
fi

#boost-1.60.0
if [ $STEP -eq 95 ]; then
	tar -xvf boost_1_60_0.tar.bz2
	cd boost_1_60_0
	sed -e '/using python/ s@;@: /usr/include/python${PYTHON_VERSION/3*/${PYTHON_VERSION}m} ;@' -i bootstrap.sh
	sed -e '1 i#ifndef Q_MOC_RUN' -e '$ a#endif' -i boost/type_traits/detail/has_binary_operator.hpp
	./bootstrap.sh --prefix=/usr
	./b2 -j $JOBS stage threading=multi link=shared
	./b2 -j $JOBS install threading=multi link=shared
	cd ..
	rm -rvf boost_1_60_0
	let "STEP++"
fi

#qpdf-6.0.0
if [ $STEP -eq 95 ]; then
	tar -xvf qpdf-6.0.0.tar.gz
	cd qpdf-6.0.0
	./configure \
		--prefix=/usr \
        --disable-static \
        --docdir=/usr/share/doc/qpdf-6.0.0
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf qpdf-6.0.0
	let "STEP++"
fi

#neon-0.30.1
if [ $STEP -eq 95 ]; then
	tar -xvf neon-0.30.1.tar.gz
	cd neon-0.30.1
	./configure \
		--prefix=/usr \
        --with-ssl \
        --enable-shared \
        --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf neon-0.30.1
	let "STEP++"
fi

#apr-util-1.5.4
if [ $STEP -eq 95 ]; then
	tar -xvf apr-util-1.5.4.tar.bz2
	cd apr-util-1.5.4
	./configure \
		--prefix=/usr \
        --with-apr=/usr \
        --with-gdbm=/usr \
        --with-openssl=/usr \
        --with-crypto
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf apr-util-1.5.4
	let "STEP++"
fi

#libevent-2.0.22
if [ $STEP -eq 95 ]; then
	tar -xvf libevent-2.0.22-stable.tar.gz
	cd libevent-2.0.22-stable
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libevent-2.0.22-stable
	let "STEP++"
fi

#-------------------------------------------------------
#Next packages need at least one package installed above
#-------------------------------------------------------

#pinentry-0.9.7
if [ $STEP -eq 10 ]; then
	tar -xvf pinentry-0.9.7.tar.bz2
	cd pinentry-0.9.7
	./configure \
		--prefix=/usr \
		--disable-pinentry-qt5 \
		--enable-pinentry-qt=no
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf pinentry-0.9.7
	let "STEP++"
fi

#p11-kit-0.23.2
if [ $STEP -eq 15 ]; then
	tar -xvf p11-kit-0.23.2.tar.gz
	cd p11-kit-0.23.2
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf p11-kit-0.23.2
	let "STEP++"
fi

#glib-2.46.2
if [ $STEP -eq 26 ]; then
	tar -xvf glib-2.46.2.tar.xz
	cd glib-2.46.2
	./configure \
		--prefix=/usr \
		--with-pcre=system \
		--with-python=/usr/bin/python3
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf glib-2.46.2
	let "STEP++"
fi

#libxml2-2.9.3
if [ $STEP -eq 41 ]; then
	tar -xvf libxml2-2.9.3.tar.gz
	cd libxml2-2.9.3
	./configure \
		--prefix=/usr \
		--disable-static \
		--with-history \
		--with-python=/usr/bin/python3
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libxml2-2.9.3
	let "STEP++"
fi

#mozjs17.0.0
if [ $STEP -eq 29 ]; then
	tar -xvf mozjs17.0.0.tar.gz
	cd mozjs17.0.0
	cd js/src
	sed -i 's/(defined\((@TEMPLATE_FILE)\))/\1/' config/milestone.pl
	./configure \
		--prefix=/usr \
        --enable-readline \
        --enable-threadsafe \
        --with-system-ffi \
        --with-system-nspr
	make -j $JOBS
	make -j $JOBS install
	find /usr/include/js-17.0/ /usr/lib/libmozjs-17.0.a /usr/lib/pkgconfig/mozjs-17.0.pc -type f -exec chmod -v 644 {} \;
	cd ../../..
	rm -rvf mozjs17.0.0
	let "STEP++"
fi

#openldap-2.4.44
if [ $STEP -eq 46 ]; then
	tar -xvf openldap-2.4.44.tgz
	cd openldap-2.4.44
	groupadd -g 83 ldap
	useradd  -c "OpenLDAP Daemon Owner" -d /var/lib/openldap -u 83 -g ldap -s /bin/false ldap
	patch -Np1 -i ../openldap-2.4.44-consolidated-2.patch
	autoconf
	./configure \
		--prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --libexecdir=/usr/lib \
        --disable-static \
        --disable-debug \
        --with-tls=openssl \
        --with-cyrus-sasl \
        --enable-dynamic \
        --enable-crypt \
        --enable-spasswd \
        --enable-slapd \
        --enable-modules \
        --enable-backends=mod \
        --disable-ndb \
        --disable-sql \
        --disable-shell \
        --disable-bdb \
        --disable-hdb \
        --enable-overlays=mod
	make -j $JOBS depend
	make -j $JOBS
	make -j $JOBS install
	install -v -dm700 -o ldap -g ldap /var/lib/openldap
	install -v -dm700 -o ldap -g ldap /etc/openldap/slapd.d
	chmod -v 640 /etc/openldap/slapd.{conf,ldif}
	chown -v root:ldap /etc/openldap/slapd.{conf,ldif}
	install -v -dm755 /usr/share/doc/openldap-2.4.44
	cp -vfr doc/{drafts,rfc,guide} /usr/share/doc/openldap-2.4.44
	cd ..
	rm -rvf openldap-2.4.44
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-slapd
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#libxau-1.0.8
if [ $STEP -eq 29 ]; then
	tar -xvf libXau-1.0.8.tar.bz2
	cd libXau-1.0.8
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
    	--localstatedir=/var \
    	--disable-static
    make -j $JOBS
    make -j $JOBS install
	cd ..
	rm -rvf libXau-1.0.8
	let "STEP++"
fi

#xcb-proto-1.11
if [ $STEP -eq 29 ]; then
	tar -xvf xcb-proto-1.11.tar.bz2
	cd xcb-proto-1.11
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
    	--localstatedir=/var \
    	--disable-static
    make -j $JOBS install
	cd ..
	rm -rvf xcb-proto-1.11
	let "STEP++"
fi

#libxdmcp-1.1.2
if [ $STEP -eq 29 ]; then
	tar -xvf libXdmcp-1.1.2.tar.bz2
	cd libXdmcp-1.1.2
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
    	--localstatedir=/var \
    	--disable-static
    make -j $JOBS
    make -j $JOBS install
	cd ..
	rm -rvf libXdmcp-1.1.2
	let "STEP++"
fi

#curl-7.47.1
if [ $STEP -eq 67 ]; then
	tar -xvf curl-7.47.1.tar.lzma
	cd curl-7.47.1
	./configure \
		--prefix=/usr \
        --disable-static \
        --enable-threaded-resolver
	make -j $JOBS
	make -j $JOBS install
	cp -av docs docs-save
	rm -rvf docs/examples/.deps
	find docs \( -name Makefile\* -o -name \*.1 -o -name \*.3 \) -exec rm {} \;
	install -v -d -m755 /usr/share/doc/curl-7.47.1
	cp -v -R docs/* /usr/share/doc/curl-7.47.1
	rm -rvf docs
	mv -iv docs-save doc
	cd ..
	rm -rvf curl-7.47.1
	let "STEP++"
fi

#llvm-3.7.1
if [ $STEP -eq 81 ]; then
	tar -xvf llvm-3.7.1.src.tar.xz
	cd llvm-3.7.1.src
	sed -e "s:/docs/llvm:/share/doc/llvm-3.7.1:" -i Makefile.config.in
	mkdir -v build
	cd build
	CC=gcc CXX=g++ \
	../configure \
		--prefix=/usr \
        --datarootdir=/usr/share \
        --sysconfdir=/etc \
        --enable-libffi \
        --enable-optimized \
        --enable-shared \
        --enable-targets=x86_64,r600 \
        --disable-assertions \
        --docdir=/usr/share/doc/llvm-3.7.1
	make -j $JOBS
	make -j $JOBS install
	for file in /usr/lib/lib{clang,LLVM,LTO}*.a
	do
		test -f $file && chmod -v 644 $file
	done
	unset file
	cd ../..
	rm -rvf llvm-3.7.1.src
	let "STEP++"
fi

#archive-zip-1.56
if [ $STEP -eq 85 ]; then
	tar -xvf Archive-Zip-1.56.tar.gz
	cd Archive-Zip-1.56
	perl Makefile.PL
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf Archive-Zip-1.56
	let "STEP++"
fi

#scons-2.4.1
if [ $STEP -eq 88 ]; then
	tar -xvf scons-2.4.1.tar.gz
	cd scons-2.4.1
	python setup.py install \
		--prefix=/usr \
        --standard-lib \
        --optimize=1 \
        --install-data=/usr/share
	cd ..
	rm -rvf scons-2.4.1
	let "STEP++"
fi

#libevdev-1.4.6
if [ $STEP -eq 88 ]; then
	tar -xvf libevdev-1.4.6.tar.xz
	cd libevdev-1.4.6
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
    	--localstatedir=/var \
    	--disable-static
    make -j $JOBS
    make -j $JOBS install
	cd ..
	rm -rvf libevdev-1.4.6
	let "STEP++"
fi

#libtheora-1.1.1
if [ $STEP -eq 88 ]; then
	tar -xvf libtheora-1.1.1.tar.xz
	cd libtheora-1.1.1
	sed -i 's/png_\(sizeof\)/\1/g' examples/png2theora.c
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libtheora-1.1.1
	let "STEP++"
fi

#gnupg-2.1.11
if [ $STEP -eq 11 ]; then
	tar -xvf gnupg-2.1.11.tar.bz2
	cd gnupg-2.1.11
	./configure \
		--prefix=/usr \
        --enable-symcryptrun \
        --docdir=/usr/share/doc/gnupg-2.1.11
	make -j $JOBS
	makeinfo --html --no-split -o doc/gnupg_nochunks.html doc/gnupg.texi
	makeinfo --plaintext -o doc/gnupg.txt doc/gnupg.texi
	make -j $JOBS install
	install -v -m755 -d /usr/share/doc/gnupg-2.1.11/html
	install -v -m644 doc/gnupg_nochunks.html /usr/share/doc/gnupg-2.1.11/html/gnupg.html
	install -v -m644 doc/*.texi doc/gnupg.txt /usr/share/doc/gnupg-2.1.11
	for f in gpg gpgv
	do
  		ln -svf ${f}2.1 /usr/share/man/man1/${f}.1
  		ln -svf ${f}2 /usr/bin/$f
	done
	unset f
	cd ..
	rm -rvf gnupg-2.1.11
	let "STEP++"
fi

#libwebp-0.5.0
if [ $STEP -eq 11 ]; then
	tar -xvf libwebp-0.5.0.tar.gz
	cd libwebp-0.5.0
	./configure \
		--prefix=/usr \
        --enable-libwebpmux \
        --enable-libwebpdemux \
        --enable-libwebpdecoder \
        --enable-libwebpextras \
        --enable-swap-16bit-csp \
        --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libwebp-0.5.0
	let "STEP++"
fi

#-------------------------------------------------------
#Next packages need at least one package installed above
#-------------------------------------------------------

#gnutls-3.4.9
if [ $STEP -eq 16 ]; then
	tar -xvf gnutls-3.4.9.tar.xz
	cd gnutls-3.4.9
	./configure --prefix=/usr --with-default-trust-store-file=/etc/ssl/ca-bundle.crt
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gnutls-3.4.9
	let "STEP++"
fi

#shared-mime-info-1.5
if [ $STEP -eq 42 ]; then
	tar -xvf shared-mime-info-1.5.tar.xz
	cd shared-mime-info-1.5
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf shared-mime-info-1.5
	let "STEP++"
fi

#desktop-file-utils-0.22
if [ $STEP -eq 35 ]; then
	tar -xvf desktop-file-utils-0.22.tar.xz
	cd desktop-file-utils-0.22
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf desktop-file-utils-0.22
	let "STEP++"
fi

#sendmail-8.15.2
if [ $STEP -eq 47 ]; then
	tar -xvf sendmail.8.15.2.tar.gz
	cd sendmail-8.15.2
	groupadd -g 26 smmsp
	useradd -c "Sendmail Daemon" -g smmsp -d /dev/null -s /bin/false -u 26 smmsp
	chmod -v 1777 /var/mail
	install -v -m700 -d /var/spool/mqueue
	echo "APPENDDEF(\`confENVDEF',\`-DSTARTTLS -DSASL -DLDAPMAP')
APPENDDEF(\`confLIBS', \`-lssl -lcrypto -lsasl2 -lldap -llber -ldb')
APPENDDEF(\`confINCDIRS', \`-I/usr/include/sasl')
define(\`confMANGRP',\`root')
define(\`confMANOWN',\`root')
define(\`confSBINGRP',\`root')
define(\`confUBINGRP',\`root')
define(\`confUBINOWN',\`root')" >> devtools/Site/site.config.m4
	sed -i 's|/usr/man/man|/usr/share/man/man|' devtools/OS/Linux
	cd sendmail
	sh Build
	cd ../cf/cf
	cp generic-linux.mc sendmail.mc
	sh Build sendmail.cf
	install -v -d -m755 /etc/mail &&
	sh Build install-cf
	cd ../..
	sh Build install
	install -v -m644 cf/cf/{submit,sendmail}.mc /etc/mail
	cp -v -R cf/* /etc/mail
	install -v -m755 -d /usr/share/doc/sendmail-8.15.2/{cf,sendmail}
	install -v -m644 CACerts FAQ KNOWNBUGS LICENSE PGPKEYS README RELEASE_NOTES /usr/share/doc/sendmail-8.15.2
	install -v -m644 sendmail/{README,SECURITY,TRACEFLAGS,TUNING} /usr/share/doc/sendmail-8.15.2/sendmail
	install -v -m644 cf/README /usr/share/doc/sendmail-8.15.2/cf
	for manpage in sendmail editmap mailstats makemap praliases smrsh
	do
    	install -v -m644 $manpage/$manpage.8 /usr/share/man/man8
	done
	install -v -m644 sendmail/aliases.5 /usr/share/man/man5
	install -v -m644 sendmail/mailq.1 /usr/share/man/man1
	install -v -m644 sendmail/newaliases.1 /usr/share/man/man1
	install -v -m644 vacation/vacation.1 /usr/share/man/man1
	cat /etc/hostname > /etc/mail/local-host-names
	echo 'postmaster: root
MAILER-DAEMON: root' > /etc/mail/aliases
	newaliases
	cd /etc/mail
	m4 m4/cf.m4 sendmail.mc > sendmail.cf
	cd /sources
	rm -rvf sendmail-8.15.2
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-sendmail
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#harfbuzz-1.1.3
if [ $STEP -eq 74 ]; then
	tar -xvf harfbuzz-1.1.3.tar.bz2
	cd harfbuzz-1.1.3
	./configure --prefix=/usr --with-gobject
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf harfbuzz-1.1.3
	let "STEP++"
fi

#libxcb-1.11.1
if [ $STEP -eq 88 ]; then
	tar -xvf libxcb-1.11.1.tar.bz2
	cd libxcb-1.11.1
	sed -i "s/pthread-stubs//" configure
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
    	--localstatedir=/var \
    	--disable-static \
    	--enable-xinput \
        --without-doxygen \
        --docdir='${datadir}'/doc/libxcb-1.11.1
    make -j $JOBS
    make -j $JOBS install
	cd ..
	rm -rvf libxcb-1.11.1
	let "STEP++"
fi

#gobject-introspection-1.46.0
if [ $STEP -eq 30 ]; then
	tar -xvf gobject-introspection-1.46.0.tar.xz
	cd gobject-introspection-1.46.0
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gobject-introspection-1.46.0
	let "STEP++"
fi

#libgudev-230
if [ $STEP -eq 73 ]; then
	tar -xvf libgudev-230.tar.xz
	cd libgudev-230
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libgudev-230
	let "STEP++"
fi

#vala-0.28.1
if [ $STEP -eq 89 ]; then
	tar -xvf vala-0.28.1.tar.xz
	cd vala-0.28.1
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf vala-0.28.1
	let "STEP++"
fi

#libxslt-1.1.28
if [ $STEP -eq 64 ]; then
	tar -xvf libxslt-1.1.28.tar.gz
	cd libxslt-1.1.28
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libxslt-1.1.28
	let "STEP++"
fi

#docbook-xml-4.5
if [ $STEP -eq 62 ]; then
	mkdir -v docbook-xml-4.5
	cd docbook-xml-4.5
	unzip ../docbook-xml-4.5.zip
	install -v -d -m755 /usr/share/xml/docbook/xml-dtd-4.5
	install -v -d -m755 /etc/xml
	chown -R root:root .
	cp -v -af docbook.cat *.dtd ent/ *.mod /usr/share/xml/docbook/xml-dtd-4.5
	if [ ! -d /etc/xml ]; then install -v -m755 -d /etc/xml; fi
	if [ ! -e /etc/xml/docbook ]; then
    	xmlcatalog --noout --create /etc/xml/docbook
    fi
	xmlcatalog --noout --add "public" "-//OASIS//DTD DocBook XML V4.5//EN" "http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd" /etc/xml/docbook
	xmlcatalog --noout --add "public" "-//OASIS//DTD DocBook XML CALS Table Model V4.5//EN" "file:///usr/share/xml/docbook/xml-dtd-4.5/calstblx.dtd" /etc/xml/docbook
	xmlcatalog --noout --add "public" "-//OASIS//DTD XML Exchange Table Model 19990315//EN" "file:///usr/share/xml/docbook/xml-dtd-4.5/soextblx.dtd" /etc/xml/docbook
	xmlcatalog --noout --add "public" "-//OASIS//ELEMENTS DocBook XML Information Pool V4.5//EN" "file:///usr/share/xml/docbook/xml-dtd-4.5/dbpoolx.mod" /etc/xml/docbook
	xmlcatalog --noout --add "public" "-//OASIS//ELEMENTS DocBook XML Document Hierarchy V4.5//EN" "file:///usr/share/xml/docbook/xml-dtd-4.5/dbhierx.mod" /etc/xml/docbook
	xmlcatalog --noout --add "public" "-//OASIS//ELEMENTS DocBook XML HTML Tables V4.5//EN" "file:///usr/share/xml/docbook/xml-dtd-4.5/htmltblx.mod" /etc/xml/docbook
	xmlcatalog --noout --add "public" "-//OASIS//ENTITIES DocBook XML Notations V4.5//EN" "file:///usr/share/xml/docbook/xml-dtd-4.5/dbnotnx.mod" /etc/xml/docbook
	xmlcatalog --noout --add "public" "-//OASIS//ENTITIES DocBook XML Character Entities V4.5//EN" "file:///usr/share/xml/docbook/xml-dtd-4.5/dbcentx.mod" /etc/xml/docbook
	xmlcatalog --noout --add "public" "-//OASIS//ENTITIES DocBook XML Additional General Entities V4.5//EN" "file:///usr/share/xml/docbook/xml-dtd-4.5/dbgenent.mod" /etc/xml/docbook
	xmlcatalog --noout --add "rewriteSystem" "http://www.oasis-open.org/docbook/xml/4.5" "file:///usr/share/xml/docbook/xml-dtd-4.5" /etc/xml/docbook
	xmlcatalog --noout --add "rewriteURI" "http://www.oasis-open.org/docbook/xml/4.5" "file:///usr/share/xml/docbook/xml-dtd-4.5" /etc/xml/docbook
	if [ ! -e /etc/xml/catalog ]; then
    	xmlcatalog --noout --create /etc/xml/catalog
    fi
	xmlcatalog --noout --add "delegatePublic" "-//OASIS//ENTITIES DocBook XML" "file:///etc/xml/docbook" /etc/xml/catalog
	xmlcatalog --noout --add "delegatePublic" "-//OASIS//DTD DocBook XML" "file:///etc/xml/docbook" /etc/xml/catalog
	xmlcatalog --noout --add "delegateSystem" "http://www.oasis-open.org/docbook/" "file:///etc/xml/docbook" /etc/xml/catalog
	xmlcatalog --noout --add "delegateURI" "http://www.oasis-open.org/docbook/" "file:///etc/xml/docbook" /etc/xml/catalog
	for DTDVERSION in 4.1.2 4.2 4.3 4.4
	do
  		xmlcatalog --noout --add "public" "-//OASIS//DTD DocBook XML V$DTDVERSION//EN" "http://www.oasis-open.org/docbook/xml/$DTDVERSION/docbookx.dtd" /etc/xml/docbook
  		xmlcatalog --noout --add "rewriteSystem" "http://www.oasis-open.org/docbook/xml/$DTDVERSION" "file:///usr/share/xml/docbook/xml-dtd-4.5" /etc/xml/docbook
  		xmlcatalog --noout --add "rewriteURI" "http://www.oasis-open.org/docbook/xml/$DTDVERSION" "file:///usr/share/xml/docbook/xml-dtd-4.5" /etc/xml/docbook
  		xmlcatalog --noout --add "delegateSystem" "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" "file:///etc/xml/docbook" /etc/xml/catalog
  		xmlcatalog --noout --add "delegateURI" "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" "file:///etc/xml/docbook" /etc/xml/catalog
	done
	cd ..
	rm -rvf docbook-xml-4.5
	let "STEP++"
fi

#docbook-xsl-1.79.1
if [ $STEP -eq 63 ]; then
	tar -xvf docbook-xsl-1.79.1.tar.bz2
	cd docbook-xsl-1.79.1
	install -v -m755 -d /usr/share/xml/docbook/xsl-stylesheets-1.79.1
	cp -v -R VERSION assembly common eclipse epub epub3 extensions fo \
         highlighting html htmlhelp images javahelp lib manpages params \
         profiling roundtrip slides template tests tools webhelp website \
         xhtml xhtml-1_1 xhtml5 /usr/share/xml/docbook/xsl-stylesheets-1.79.1
	ln -sv VERSION /usr/share/xml/docbook/xsl-stylesheets-1.79.1/VERSION.xsl
	install -v -m644 -D README /usr/share/doc/docbook-xsl-1.79.1/README.txt
	install -v -m644 RELEASE-NOTES* NEWS* /usr/share/doc/docbook-xsl-1.79.1
	if [ ! -d /etc/xml ]; then install -v -m755 -d /etc/xml; fi
	if [ ! -f /etc/xml/catalog ]; then
    	xmlcatalog --noout --create /etc/xml/catalog
	fi
	xmlcatalog --noout --add "rewriteSystem" "http://docbook.sourceforge.net/release/xsl/1.79.1" "/usr/share/xml/docbook/xsl-stylesheets-1.79.1" /etc/xml/catalog
	xmlcatalog --noout --add "rewriteURI" "http://docbook.sourceforge.net/release/xsl/1.79.1" "/usr/share/xml/docbook/xsl-stylesheets-1.79.1" /etc/xml/catalog
	xmlcatalog --noout --add "rewriteSystem" "http://docbook.sourceforge.net/release/xsl/current" "/usr/share/xml/docbook/xsl-stylesheets-1.79.1" /etc/xml/catalog
	xmlcatalog --noout --add "rewriteURI" "http://docbook.sourceforge.net/release/xsl/current" "/usr/share/xml/docbook/xsl-stylesheets-1.79.1" /etc/xml/catalog
	cd ..
	rm -rvf docbook-xsl-1.79.1
	let "STEP++"
fi

#cmake-3.4.3
if [ $STEP -eq 79 ]; then
	tar -xvf cmake-3.4.3.tar.gz
	cd cmake-3.4.3
	./bootstrap \
		--prefix=/usr \
        --system-libs \
        --mandir=/share/man \
        --no-system-jsoncpp \
        --docdir=/share/doc/cmake-3.4.3
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf cmake-3.4.3
	let "STEP++"
fi

#libinput-1.1.8
if [ $STEP -eq 88 ]; then
	tar -xvf libinput-1.1.8.tar.xz
	cd libinput-1.1.8
	./configure \
		--prefix=/usr \
        --disable-static \
        --with-udev-dir=/lib/udev
    make -j $JOBS
    make -j $JOBS install
	cd ..
	rm -rvf libinput-1.1.8
	let "STEP++"
fi

#libxfce4util-4.12.1
if [ $STEP -eq 88 ]; then
	tar -xvf libxfce4util-4.12.1.tar.bz2
	cd libxfce4util-4.12.1
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libxfce4util-4.12.1
	let "STEP++"
fi

#libcroco-0.6.11
if [ $STEP -eq 88 ]; then
	tar -xvf libcroco-0.6.11.tar.xz
	cd libcroco-0.6.11
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libcroco-0.6.11
	let "STEP++"
fi

#polkit-0.113
if [ $STEP -eq 31 ]; then
	tar -xvf polkit-0.113.tar.gz
	cd polkit-0.113
	groupadd -fg 27 polkitd
	useradd -c "PolicyKit Daemon Owner" -d /etc/polkit-1 -u 27 -g polkitd -s /bin/false polkitd
	./configure \
		--prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --enable-libsystemd-login=no
	make -j $JOBS
	make -j $JOBS install
	cp -v /alfs/pam.d/polkit-1 /etc/pam.d/polkit-1
	cd ..
	rm -rvf polkit-0.113
	let "STEP++"
fi

#enchant-1.6.0
if [ $STEP -eq 31 ]; then
	tar -xvf enchant-1.6.0.tar.gz
	cd enchant-1.6.0
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	ln -svfn ../../lib/aspell /usr/share/enchant/aspell
	cd ..
	rm -rvf enchant-1.6.0
	let "STEP++"
fi

#serf-1.3.8
if [ $STEP -eq 31 ]; then
	tar -xvf serf-1.3.8.tar.bz2
	cd serf-1.3.8
	sed -i "/Append/s:RPATH=libdir,::" SConstruct
	sed -i "/Default/s:lib_static,::" SConstruct
	sed -i "/Alias/s:install_static,::" SConstruct
	scons PREFIX=/usr
	scons PREFIX=/usr install
	cd ..
	rm -rvf serf-1.3.8
	let "STEP++"
fi

#gegl-0.2.0
if [ $STEP -eq 31 ]; then
	tar -xvf gegl-0.2.0.tar.bz2
	cd gegl-0.2.0
	patch -Np1 -i ../gegl-0.2.0-ffmpeg2-1.patch
	./configure --prefix=/usr
	LC_ALL=en_US make -j $JOBS
	make -j $JOBS install
	install -v -m644 docs/*.{css,html} /usr/share/gtk-doc/html/gegl
	install -d -v -m755 /usr/share/gtk-doc/html/gegl/images
	install -v -m644 docs/images/* /usr/share/gtk-doc/html/gegl/images
	cd ..
	rm -rvf gegl-0.2.0
	let "STEP++"
fi

#glibmm-2.46.3
if [ $STEP -eq 31 ]; then
	tar -xvf glibmm-2.46.3.tar.xz
	cd glibmm-2.46.3
	sed -e '/^libdocdir =/ s/$(book_name)/glibmm-2.46.3/' -i docs/Makefile.in
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf glibmm-2.46.3
	let "STEP++"
fi

#-------------------------------------------------------
#Next packages need at least one package installed above
#-------------------------------------------------------

#procmail-3.22
if [ $STEP -eq 48 ]; then
	tar -xvf procmail-3.22.tar.gz
	cd procmail-3.22
	sed -i 's/getline/get_line/' src/*.[ch]
	make -j $JOBS LOCKINGTEST=/tmp MANDIR=/usr/share/man install
	make -j $JOBS install-suid
	cd ..
	rm -rvf procmail-3.22
	let "STEP++"
fi

#at-3.1.18
if [ $STEP -eq 49 ]; then
	mkdir -v at-3.1.18
	cd at-3.1.18
	tar -xvf ../at_3.1.18.orig.tar.gz
	groupadd -g 17 atd
	useradd -d /dev/null -c "atd daemon" -g atd -s /bin/false -u 17 atd
	mkdir -pv /var/spool/cron
	sed -i '/docdir/s/=.*/= @docdir@/' Makefile.in
	./configure \
		--with-daemon_username=atd \
        	--with-daemon_groupname=atd \
        	SENDMAIL=/usr/sbin/sendmail
	make -j $JOBS
	make -j $JOBS install docdir=/usr/share/doc/at-3.1.18 atdocdir=/usr/share/doc/at-3.1.18 
	cd ..
	rm -rvf at-3.1.18
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-atd
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#freetype-2.6.3
if [ $STEP -eq 38 ]; then
	tar -xvf freetype-2.6.3.tar.bz2
	cd freetype-2.6.3
	sed -e "/AUX.*.gxvalid/s@^# @@" -e "/AUX.*.otvalid/s@^# @@" -i modules.cfg
	sed -r -e 's:.*(#.*SUBPIXEL.*) .*:\1:' -i include/freetype/config/ftoption.h
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	install -v -m755 -d /usr/share/doc/freetype-2.6.3
	cp -v -R docs/* /usr/share/doc/freetype-2.6.3
	cd ..
	rm -rvf freetype-2.6.3
	let "STEP++"
fi

#libgusb-0.2.8
if [ $STEP -eq 38 ]; then
	tar -xvf libgusb-0.2.8.tar.xz
	cd libgusb-0.2.8
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libgusb-0.2.8
	let "STEP++"
fi

#raptor2-2.0.15
if [ $STEP -eq 69 ]; then
	tar -xvf raptor2-2.0.15.tar.gz
	cd raptor2-2.0.15
	./configure \
		--prefix=/usr \
		--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf raptor2-2.0.15
	let "STEP++"
fi

#atk-2.18.0
if [ $STEP -eq 69 ]; then
	tar -xvf atk-2.18.0.tar.xz
	cd atk-2.18.0
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf atk-2.18.0
	let "STEP++"
fi

#wget-1.17.1
if [ $STEP -eq 58 ]; then
	tar -xvf wget-1.17.1.tar.xz
	cd wget-1.17.1
	./configure --prefix=/usr --sysconfdir=/etc
	make -j $JOBS
	make -j $JOBS install
	echo 'ca-directory=/etc/ssl/certs' >> /etc/wgetrc
	cd ..
	rm -rvf wget-1.17.1
	let "STEP++"
fi

#samba-4.3.4
if [ $STEP -eq 96 ]; then
	tar -xvf samba-4.3.4.tar.gz
	cd samba-4.3.4
	./configure \
    		--prefix=/usr \
    		--sysconfdir=/etc \
    		--localstatedir=/var \
    		--with-piddir=/run/samba \
    		--with-pammodulesdir=/lib/security \
    		--without-systemd \
    		--enable-fhs
	make -j $JOBS
	make -j $JOBS install
	mv -v /usr/lib/libnss_win{s,bind}.so* /lib
	ln -svf lib/libnss_winbind.so.2 /usr/lib/libnss_winbind.so
	ln -svf lib/libnss_wins.so.2 /usr/lib/libnss_wins.so
	install -v -m644 examples/smb.conf.default /etc/samba
	mkdir -pv /etc/openldap/schema
	install -v -m644 examples/LDAP/README /etc/openldap/schema/README.LDAP
	install -v -m644 examples/LDAP/samba* /etc/openldap/schema
	install -v -m755 examples/LDAP/{get*,ol*} /etc/openldap/schema
	groupadd -g 99 nogroup
	useradd -c "Unprivileged Nobody" -d /dev/null -g nogroup -s /bin/false -u 99 nobody
	cd ..
	rm -rvf samba-4.3.4
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-samba
	make -j $JOBS install-winbindd
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#xcb-util-0.4.0
if [ $STEP -eq 96 ]; then
	tar -xvf xcb-util-0.4.0.tar.bz2
	cd xcb-util-0.4.0
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xcb-util-0.4.0
	let "STEP++"
fi

#xcb-util-keysyms-0.4.0
if [ $STEP -eq 96 ]; then
	tar -xvf xcb-util-keysyms-0.4.0.tar.bz2
	cd xcb-util-keysyms-0.4.0
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xcb-util-keysyms-0.4.0
	let "STEP++"
fi

#xcb-util-renderutil-0.3.9
if [ $STEP -eq 96 ]; then
	tar -xvf xcb-util-renderutil-0.3.9.tar.bz2
	cd xcb-util-renderutil-0.3.9
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xcb-util-renderutil-0.3.9
	let "STEP++"
fi

#xcb-util-wm-0.4.1
if [ $STEP -eq 96 ]; then
	tar -xvf xcb-util-wm-0.4.1.tar.bz2
	cd xcb-util-wm-0.4.1
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xcb-util-wm-0.4.1
	let "STEP++"
fi

#gstreamer-1.6.3
if [ $STEP -eq 96 ]; then
	tar -xvf gstreamer-1.6.3.tar.xz
	cd gstreamer-1.6.3
	./configure \
		--prefix=/usr \
	        --with-package-name="GStreamer 1.6.3 BLFS" \
	        --with-package-origin="http://www.linuxfromscratch.org/blfs/view/svn/"
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gstreamer-1.6.3
	let "STEP++"
fi

#gsettings-desktop-schemas-3.18.1
if [ $STEP -eq 96 ]; then
	tar -xvf gsettings-desktop-schemas-3.18.1.tar.xz
	cd gsettings-desktop-schemas-3.18.1
	sed -i -r 's:"(/system):"/org/gnome\1:g' schemas/*.in
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gsettings-desktop-schemas-3.18.1
	let "STEP++"
fi

#libsecret-0.18.4
if [ $STEP -eq 96 ]; then
	tar -xvf libsecret-0.18.4.tar.xz
	cd libsecret-0.18.4
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libsecret-0.18.4
	let "STEP++"
fi

#taglib-1.10
if [ $STEP -eq 96 ]; then
	tar -xvf taglib-1.10.tar.gz
	cd taglib-1.10
	mkdir -v build
	cd build
	cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release ..
	make -j $JOBS
	make -j $JOBS install
	cd ../..
	rm -rvf taglib-1.10
	let "STEP++"
fi

#clucene-2.3.3.4
if [ $STEP -eq 96 ]; then
	tar -xvf clucene-core-2.3.3.4.tar.gz
	cd clucene-core-2.3.3.4
	patch -Np1 -i ../clucene-2.3.3.4-contribs_lib-1.patch
	mkdir build
	cd build
	cmake -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_CONTRIBS_LIB=ON ..
	make -j $JOBS
	make -j $JOBS install
	cd ../..
	rm -rvf clucene-core-2.3.3.4
	let "STEP++"
fi

#graphite2-1.3.5
if [ $STEP -eq 96 ]; then
	tar -xvf graphite2-1.3.5.tgz
	cd graphite2-1.3.5
	mkdir build
	cd build
	cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_VERBOSE_MAKEFILE=ON -Wno-dev ..
	make -j $JOBS
	make -j $JOBS install
	cd ../..
	rm -rvf graphite2-1.3.5
	let "STEP++"
fi

#xmlto-0.0.28
if [ $STEP -eq 65 ]; then
	tar -xvf xmlto-0.0.28.tar.bz2
	cd xmlto-0.0.28
	LINKS="/usr/bin/links" ./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xmlto-0.0.28
	let "STEP++"
fi

#udisks-2.1.6
if [ $STEP -eq 74 ]; then
	tar -xvf udisks-2.1.6.tar.bz2
	cd udisks-2.1.6
	./configure \
		--prefix=/usr \
        	--sysconfdir=/etc \
        	--localstatedir=/var \
        	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf udisks-2.1.6
	let "STEP++"
fi

#-------------------------------------------------------
#Next packages need at least one package installed above
#-------------------------------------------------------

#fontconfig-2.11.1
if [ $STEP -eq 74 ]; then
	tar -xvf fontconfig-2.11.1.tar.bz2
	cd fontconfig-2.11.1
	./configure \
		--prefix=/usr \
            	--sysconfdir=/etc \
            	--localstatedir=/var \
            	--disable-docs \
            	--docdir=/usr/share/doc/fontconfig-2.11.1
	make -j $JOBS
	make -j $JOBS install
	install -v -dm755 /usr/share/{man/man{3,5},doc/fontconfig-2.11.1/fontconfig-devel}
	install -v -m644 fc-*/*.1 /usr/share/man/man1
	install -v -m644 doc/*.3 /usr/share/man/man3
	install -v -m644 doc/fonts-conf.5 /usr/share/man/man5
	install -v -m644 doc/fontconfig-devel/* /usr/share/doc/fontconfig-2.11.1/fontconfig-devel
	install -v -m644 doc/*.{pdf,sgml,txt,html} /usr/share/doc/fontconfig-2.11.1
	cd ..
	rm -rvf fontconfig-2.11.1
	let "STEP++"
fi

#rasqal-0.9.33
if [ $STEP -eq 70 ]; then
	tar -xvf rasqal-0.9.33.tar.gz
	cd rasqal-0.9.33
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf rasqal-0.9.33
	let "STEP++"
fi

#xcb-util-image-0.4.0
if [ $STEP -eq 96 ]; then
	tar -xvf xcb-util-image-0.4.0.tar.bz2
	cd xcb-util-image-0.4.0
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xcb-util-image-0.4.0
	let "STEP++"
fi

#xcb-util-cursor-0.1.2
if [ $STEP -eq 96 ]; then
	tar -xvf xcb-util-cursor-0.1.2.tar.bz2
	cd xcb-util-cursor-0.1.2
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xcb-util-cursor-0.1.2
	let "STEP++"
fi

#glib-networking-2.46.1
if [ $STEP -eq 96 ]; then
	tar -xvf glib-networking-2.46.1.tar.xz
	cd glib-networking-2.46.1
	./configure \
		--prefix=/usr \
            	--with-ca-certificates=/etc/ssl/ca-bundle.crt \
            	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf glib-networking-2.46.1
	let "STEP++"
fi

#ghostscript-9.18
if [ $STEP -eq 96 ]; then
	tar -xvf ghostscript-9.18.tar.bz2
	cd ghostscript-9.18
	sed -i 's/ZLIBDIR=src/ZLIBDIR=$includedir/' configure.ac configure
	rm -rvf freetype lcms2 jpeg libpng
	rm -rvf zlib
	./configure \
		--prefix=/usr \
            	--disable-compile-inits \
            	--enable-dynamic \
            	--with-system-libtiff
	make -j $JOBS
	make -j $JOBS install
	ln -sfvn ../ghostscript/9.18/doc /usr/share/doc/ghostscript-9.18
	cd ..
	rm -rvf ghostscript-9.18
	let "STEP++"
fi

#xdg-utils-1.1.1
if [ $STEP -eq 96 ]; then
	tar -xvf xdg-utils-1.1.1.tar.gz
	cd xdg-utils-1.1.1
	./configure --prefix=/usr --mandir=/usr/share/man
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xdg-utils-1.1.1
	let "STEP++"
fi

#atkmm-2.24.2
if [ $STEP -eq 96 ]; then
	tar -xvf atkmm-2.24.2.tar.xz
	cd atkmm-2.24.2
	sed -e '/^libdocdir =/ s/$(book_name)/atkmm-2.24.2/' -i doc/Makefile.in
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf atkmm-2.24.2
	let "STEP++"
fi

#-------------------------------------------------------
#Next packages need at least one package installed above
#-------------------------------------------------------

#xorg-libraries
if [ $STEP -eq 96 ]; then
	for package in xtrans-1.3.5.tar.bz2 \
		libX11-1.6.3.tar.bz2 \
		libXext-1.3.3.tar.bz2 \
		libFS-1.0.7.tar.bz2 \
		libICE-1.0.9.tar.bz2 \
		libSM-1.2.2.tar.bz2 \
		libXScrnSaver-1.2.2.tar.bz2 \
		libXt-1.1.5.tar.bz2 \
		libXmu-1.1.2.tar.bz2 \
		libXpm-3.5.11.tar.bz2 \
		libXaw-1.0.13.tar.bz2 \
		libXfixes-5.0.1.tar.bz2 \
		libXcomposite-0.4.4.tar.bz2 \
		libXrender-0.9.9.tar.bz2 \
		libXcursor-1.1.14.tar.bz2 \
		libXdamage-1.1.4.tar.bz2 \
		libfontenc-1.1.3.tar.bz2 \
		libXfont-1.5.1.tar.bz2 \
		libXft-2.3.2.tar.bz2 \
		libXi-1.7.6.tar.bz2 \
		libXinerama-1.1.3.tar.bz2 \
		libXrandr-1.5.0.tar.bz2 \
		libXres-1.0.7.tar.bz2 \
		libXtst-1.2.2.tar.bz2 \
		libXv-1.0.10.tar.bz2 \
		libXvMC-1.0.9.tar.bz2 \
		libXxf86dga-1.1.4.tar.bz2 \
		libXxf86vm-1.1.4.tar.bz2 \
		libdmx-1.1.3.tar.bz2 \
		libpciaccess-0.13.4.tar.bz2 \
		libxkbfile-1.0.9.tar.bz2 \
		libxshmfence-1.2.tar.bz2
	do
		packagedir=${package%.tar.bz2}
		tar -xvf $package
		pushd $packagedir
		case $packagedir in
  			libXfont-[0-9]* )
				./configure \
					--prefix=/usr \
					--sysconfdir=/etc \
	    				--localstatedir=/var \
	    				--disable-static \
	    				--disable-devel-docs
			;;
			libXt-[0-9]* )
				./configure \
					--prefix=/usr \
					--sysconfdir=/etc \
	    				--localstatedir=/var \
	    				--disable-static \
					--with-appdefaultdir=/etc/X11/app-defaults
			;;
			* )
				./configure \
					--prefix=/usr \
					--sysconfdir=/etc \
	    				--localstatedir=/var \
	    				--disable-static
			;;
		esac
		make -j $JOBS
		make -j $JOBS install
		popd
		rm -rvf $packagedir
		/sbin/ldconfig
	done
	let "STEP++"
fi

#redland-1.0.17
if [ $STEP -eq 71 ]; then
	tar -xvf redland-1.0.17.tar.gz
	cd redland-1.0.17
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf redland-1.0.17
	let "STEP++"
fi

#libsoup-2.52.2
if [ $STEP -eq 71 ]; then
	tar -xvf libsoup-2.52.2.tar.xz
	cd libsoup-2.52.2
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libsoup-2.52.2
	let "STEP++"
fi

#-------------------------------------------------------
#Next packages need at least one package installed above
#-------------------------------------------------------

#dbus-1.10.6
if [ $STEP -eq 71 ]; then
	tar -xvf dbus-1.10.6.tar.gz
	cd dbus-1.10.6
	groupadd -g 18 messagebus
	useradd -c "D-Bus Message Daemon User" -d /var/run/dbus -u 18 -g messagebus -s /bin/false messagebus
	./configure \
		--prefix=/usr \
        	--sysconfdir=/etc \
            	--localstatedir=/var \
            	--disable-doxygen-docs \
            	--disable-xml-docs \
            	--disable-static \
            	--disable-systemd \
            	--without-systemdsystemunitdir \
            	--with-console-auth-dir=/run/console/ \
            	--docdir=/usr/share/doc/dbus-1.10.6
	make -j $JOBS
	make -j $JOBS install
	dbus-uuidgen --ensure
	cd ..
	rm -rvf dbus-1.10.6
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-dbus
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#cairo-1.14.6
if [ $STEP -eq 71 ]; then
	tar -xvf cairo-1.14.6.tar.xz
	cd cairo-1.14.6
	./configure \
		--prefix=/usr \
            	--disable-static \
            	--enable-tee
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf cairo-1.14.6
	let "STEP++"
fi

#gdk-pixbuf-2.32.3
if [ $STEP -eq 71 ]; then
	tar -xvf gdk-pixbuf-2.32.3.tar.xz
	cd gdk-pixbuf-2.32.3
	./configure --prefix=/usr --with-x11
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gdk-pixbuf-2.32.3
	let "STEP++"
fi

#libdrm-2.4.66
if [ $STEP -eq 71 ]; then
	tar -xvf libdrm-2.4.66.tar.bz2
	cd libdrm-2.4.66
	sed -i "/pthread-stubs/d" configure.ac
	autoreconf -fiv
	./configure --prefix=/usr --enable-udev
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libdrm-2.4.66
	let "STEP++"
fi

#libvdpau-1.1.1
if [ $STEP -eq 71 ]; then
	tar -xvf libvdpau-1.1.1.tar.bz2
	cd libvdpau-1.1.1
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static \
	    	--docdir=/usr/share/doc/libvdpau-1.1.1
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libvdpau-1.1.1
	let "STEP++"
fi

#xkeyboard-config-2.17
if [ $STEP -eq 71 ]; then
	tar -xvf xkeyboard-config-2.17.tar.bz2
	cd xkeyboard-config-2.17
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static \
	    	--with-xkb-rules-symlink=xorg
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xkeyboard-config-2.17
	let "STEP++"
fi

#startup-notification-0.12
if [ $STEP -eq 71 ]; then
	tar -xvf startup-notification-0.12.tar.gz
	cd startup-notification-0.12
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	install -v -m644 -D doc/startup-notification.txt /usr/share/doc/startup-notification-0.12/startup-notification.txt
	cd ..
	rm -rvf startup-notification-0.12
	let "STEP++"
fi

#libxklavier-5.4
if [ $STEP -eq 71 ]; then
	tar -xvf libxklavier-5.4.tar.bz2
	cd libxklavier-5.4
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libxklavier-5.4
	let "STEP++"
fi

#gst-plugins-base-1.6.3
if [ $STEP -eq 71 ]; then
	tar -xvf gst-plugins-base-1.6.3.tar.xz
	cd gst-plugins-base-1.6.3
	./configure \
		--prefix=/usr \
            	--with-package-name="GStreamer Base Plugins 1.6.3 BLFS" \
            	--with-package-origin="http://www.linuxfromscratch.org/blfs/view/svn/"
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gst-plugins-base-1.6.3
	let "STEP++"
fi

#-------------------------------------------------------
#Next packages need at least one package installed above
#-------------------------------------------------------

#colord-1.2.12
if [ $STEP -eq 71 ]; then
	tar -xvf colord-1.2.12.tar.xz
	cd colord-1.2.12
	groupadd -g 71 colord
	useradd -c "Color Daemon Owner" -d /var/lib/colord -u 71 -g colord -s /bin/false colord
	./configure \
		--prefix=/usr \
            	--sysconfdir=/etc \
            	--localstatedir=/var \
            	--with-daemon-user=colord \
            	--enable-vala \
            	--enable-systemd-login=no \
            	--disable-argyllcms-sensor \
            	--disable-bash-completion \
            	--disable-static \
            	--with-systemdsystemunitdir=no
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf colord-1.2.12
	let "STEP++"
fi

#dbus-glib-0.106
if [ $STEP -eq 71 ]; then
	tar -xvf dbus-glib-0.106.tar.gz
	cd dbus-glib-0.106
	./configure \
		--prefix=/usr \
            	--sysconfdir=/etc \
            	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf dbus-glib-0.106
	let "STEP++"
fi

#py2cairo-1.10.0
if [ $STEP -eq 71 ]; then
	tar -xvf py2cairo-1.10.0.tar.bz2
	cd py2cairo-1.10.0
	./waf configure --prefix=/usr
	./waf build
	./waf install
	cd ..
	rm -rvf py2cairo-1.10.0
	let "STEP++"
fi

#at-spi2-core-2.18.3
if [ $STEP -eq 71 ]; then
	tar -xvf at-spi2-core-2.18.3.tar.xz
	cd at-spi2-core-2.18.3
	./configure --prefix=/usr --sysconfdir=/etc
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf at-spi2-core-2.18.3
	let "STEP++"
fi

#mesa-11.1.2
if [ $STEP -eq 71 ]; then
	tar -xvf mesa-11.1.2.tar.xz
	cd mesa-11.1.2
	GLL_DRV="nouveau,r300,r600,radeonsi,svga,swrast"
	./autogen.sh \
		CFLAGS='-O2' \
		CXXFLAGS='-O2' \
            	--prefix=/usr \
            	--sysconfdir=/etc \
            	--enable-texture-float \
            	--enable-gles1 \
            	--enable-gles2 \
            	--enable-osmesa \
            	--enable-xa \
            	--enable-gbm \
            	--enable-glx-tls \
            	--with-egl-platforms="drm,x11" \
            	--with-gallium-drivers=$GLL_DRV
        unset GLL_DRV
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf mesa-11.1.2
	let "STEP++"
fi

#gst-plugins-good-1.6.3
if [ $STEP -eq 71 ]; then
	tar -xvf gst-plugins-good-1.6.3.tar.xz
	cd gst-plugins-good-1.6.3
	sed -e '/smgradio/ {
a \  \/* Radionomy Hot40Music shoutcast stream *\/
a \  g_object_set (src, "location",
a \      "http://streaming.radionomy.com:80/Hot40Music", NULL);
}' -e '/Virgin/,/smgradio/d' -i tests/check/elements/souphttpsrc.c
	./configure \
		--prefix=/usr \
            	--with-package-name="GStreamer Good Plugins 1.6.3 BLFS" \
            	--with-package-origin="http://www.linuxfromscratch.org/blfs/view/svn/"
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gst-plugins-good-1.6.3
	let "STEP++"
fi

#poppler-0.41.0
if [ $STEP -eq 71 ]; then
	tar -xvf poppler-0.41.0.tar.xz
	cd poppler-0.41.0
	./configure \
		--prefix=/usr \
            	--sysconfdir=/etc \
            	--disable-static \
            	--enable-build-type=release \
            	--enable-cmyk \
            	--enable-xpdf-headers \
            	--with-testdatadir=${PWD}/testfiles \
            	--disable-poppler-qt4 \
            	--disable-poppler-qt5
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf poppler-0.41.0
	let "STEP++"
fi

#cairomm-1.12.0
if [ $STEP -eq 71 ]; then
	tar -xvf cairomm-1.12.0.tar.gz
	cd cairomm-1.12.0
	sed -e '/^libdocdir =/ s/$(book_name)/cairomm-1.12.0/' -i docs/Makefile.in
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf cairomm-1.12.0
	let "STEP++"
fi

#pango-1.38.1
if [ $STEP -eq 71 ]; then
	tar -xvf pango-1.38.1.tar.xz
	cd pango-1.38.1
	./configure --prefix=/usr --sysconfdir=/etc
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf pango-1.38.1
	let "STEP++"
fi

#-------------------------------------------------------
#Next packages need at least one package installed above
#-------------------------------------------------------

#upower-0.9.23
if [ $STEP -eq 71 ]; then
	tar -xvf upower-0.9.23.tar.xz
	cd upower-0.9.23
	./configure \
		--prefix=/usr \
            	--sysconfdir=/etc \
            	--localstatedir=/var \
            	--enable-deprecated \
            	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf upower-0.9.23
	let "STEP++"
fi

#dbus-python-1.2.0
if [ $STEP -eq 71 ]; then
	tar -xvf dbus-python-1.2.0.tar.gz
	cd dbus-python-1.2.0
	mkdir python2
	pushd python2
	PYTHON=/usr/bin/python \
	../configure --prefix=/usr --docdir=/usr/share/doc/dbus-python-1.2.0
	make -j $JOBS
	popd
	mkdir python3
	pushd python3
	PYTHON=/usr/bin/python3 \
	../configure --prefix=/usr --docdir=/usr/share/doc/dbus-python-1.2.0
	make -j $JOBS
	popd
	make -j $JOBS -C python2 install
	make -j $JOBS -C python3 install
	cd ..
	rm -rvf dbus-python-1.2.0
	let "STEP++"
fi

#pygobject-2.28.6
if [ $STEP -eq 71 ]; then
	tar -xvf pygobject-2.28.6.tar.xz
	cd pygobject-2.28.6
	patch -Np1 -i ../pygobject-2.28.6-fixes-1.patch
	./configure --prefix=/usr --disable-introspection
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf pygobject-2.28.6
	let "STEP++"
fi

#at-spi2-atk-2.18.1
if [ $STEP -eq 71 ]; then
	tar -xvf at-spi2-atk-2.18.1.tar.xz
	cd at-spi2-atk-2.18.1
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf at-spi2-atk-2.18.1
	let "STEP++"
fi

#libepoxy-1.3.1
if [ $STEP -eq 71 ]; then
	tar -xvf libepoxy-1.3.1.tar.bz2
	cd libepoxy-1.3.1
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libepoxy-1.3.1
	let "STEP++"
fi

#xorg-applications
if [ $STEP -eq 38 ]; then
	for package in bdftopcf-1.0.5.tar.bz2 \
		iceauth-1.0.7.tar.bz2 \
		luit-1.1.1.tar.bz2 \
		mkfontdir-1.0.7.tar.bz2 \
		mkfontscale-1.1.2.tar.bz2 \
		sessreg-1.1.0.tar.bz2 \
		setxkbmap-1.3.1.tar.bz2 \
		smproxy-1.0.6.tar.bz2 \
		x11perf-1.6.0.tar.bz2 \
		xauth-1.0.9.tar.bz2 \
		xbacklight-1.2.1.tar.bz2 \
		xcmsdb-1.0.5.tar.bz2 \
		xcursorgen-1.0.6.tar.bz2 \
		xdpyinfo-1.3.2.tar.bz2 \
		xdriinfo-1.0.5.tar.bz2 \
		xev-1.2.2.tar.bz2 \
		xgamma-1.0.6.tar.bz2 \
		xhost-1.0.7.tar.bz2 \
		xinput-1.6.2.tar.bz2 \
		xkbcomp-1.3.1.tar.bz2 \
		xkbevd-1.1.4.tar.bz2 \
		xkbutils-1.0.4.tar.bz2 \
		xkill-1.0.4.tar.bz2 \
		xlsatoms-1.1.2.tar.bz2 \
		xlsclients-1.1.3.tar.bz2 \
		xmessage-1.0.4.tar.bz2 \
		xmodmap-1.0.9.tar.bz2 \
		xpr-1.0.4.tar.bz2 \
		xprop-1.2.2.tar.bz2 \
		xrandr-1.4.3.tar.bz2 \
		xrdb-1.1.0.tar.bz2 \
		xrefresh-1.0.5.tar.bz2 \
		xset-1.2.3.tar.bz2 \
		xsetroot-1.1.1.tar.bz2 \
		xvinfo-1.1.3.tar.bz2 \
		xwd-1.0.6.tar.bz2 \
		xwininfo-1.1.3.tar.bz2 \
		xwud-1.0.4.tar.bz2
	do
		packagedir=${package%.tar.bz2}
  		tar -xvf $package
  		pushd $packagedir
  		case $packagedir in
    			luit-[0-9]* )
      				line1="#ifdef _XOPEN_SOURCE"
      				line2="#  undef _XOPEN_SOURCE"
      				line3="#  define _XOPEN_SOURCE 600"
      				line4="#endif"
      				sed -i -e "s@#ifdef HAVE_CONFIG_H@$line1\n$line2\n$line3\n$line4\n\n&@" sys.c
      				unset line1 line2 line3 line4
    			;;
    			sessreg-* )
      				sed -e 's/\$(CPP) \$(DEFS)/$(CPP) -P $(DEFS)/' -i man/Makefile.in
    			;;
  		esac
		./configure \
			--prefix=/usr \
			--sysconfdir=/etc \
	    		--localstatedir=/var \
	    		--disable-static
  		make -j $JOBS
  		make -j $JOBS install
  		popd
  		rm -rvf $packagedir
	done
	rm -vf /usr/bin/xkeystone
	let "STEP++"
fi

#libva-1.6.2
if [ $STEP -eq 71 ]; then
	tar -xvf libva-1.6.2.tar.bz2
	cd libva-1.6.2
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libva-1.6.2
	tar -xvf libva-intel-driver-1.6.2.tar.bz2
	cd libva-intel-driver-1.6.2
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libva-intel-driver-1.6.2
	let "STEP++"
fi

#xfconf-4.12.0
if [ $STEP -eq 71 ]; then
	tar -xvf xfconf-4.12.0.tar.bz2
	cd xfconf-4.12.0
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xfconf-4.12.0
	let "STEP++"
fi

#tumbler-0.1.31
if [ $STEP -eq 71 ]; then
	tar -xvf tumbler-0.1.31.tar.bz2
	cd tumbler-0.1.31
	./configure --prefix=/usr --sysconfdir=/etc
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf tumbler-0.1.31
	let "STEP++"
fi

#cups-2.1.3
if [ $STEP -eq 71 ]; then
	tar -xvf cups-2.1.3-source.tar.bz2
	cd cups-2.1.3
	useradd -c "Print Service User" -d /var/spool/cups -g lp -s /bin/false -u 9 lp
	groupadd -g 19 lpadmin
	sed -i 's:555:755:g;s:444:644:g' Makedefs.in
	sed -i '/MAN.EXT/s:.gz::g' configure config-scripts/cups-manpages.m4
	sed -i '/LIBGCRYPTCONFIG/d' config-scripts/cups-ssl.m4
	aclocal  -I config-scripts
	autoconf -I config-scripts
	CC=gcc \
	./configure \
		--libdir=/usr/lib \
            	--disable-systemd \
            	--with-rcdir=/tmp/cupsinit \
            	--with-system-groups=lpadmin \
            	--with-docdir=/usr/share/cups/doc-2.1.3
	make -j $JOBS
	make -j $JOBS install
	rm -rvf /tmp/cupsinit
	ln -svnf ../cups/doc-2.1.3 /usr/share/doc/cups-2.1.3
	echo "ServerName /var/run/cups/cups.sock" > /etc/cups/client.conf
	cp -v /alfs/etc/pam.d/cups /etc/pam.d/cups
	cd ..
	rm -rvf cups-2.1.3
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-cups
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#glu-9.0.0
if [ $STEP -eq 71 ]; then
	tar -xvf glu-9.0.0.tar.bz2
	cd glu-9.0.0
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf glu-9.0.0
	let "STEP++"
fi

#pangomm-2.38.1
if [ $STEP -eq 71 ]; then
	tar -xvf pangomm-2.38.1.tar.xz
	cd pangomm-2.38.1
	sed -e '/^libdocdir =/ s/$(book_name)/pangomm-2.38.1/' -i docs/Makefile.in
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf pangomm-2.38.1
	let "STEP++"
fi

#consolekit2-1.0.1
if [ $STEP -eq 71 ]; then
	tar -xvf ConsoleKit2-1.0.1.tar.bz2
	cd ConsoleKit2-1.0.1
	./configure \
		--prefix=/usr \
            	--sysconfdir=/etc \
            	--localstatedir=/var \
            	--enable-udev-acl \
            	--enable-pam-module \
            	--enable-polkit \
            	--with-xinitrc-dir=/etc/X11/app-defaults/xinitrc.d \
            	--docdir=/usr/share/doc/ConsoleKit-1.0.1 \
            	--with-systemdsystemunitdir=no
	make -j $JOBS
	make -j $JOBS install
	mv -v /etc/X11/app-defaults/xinitrc.d/90-consolekit{,.sh}
	echo '#!/bin/sh
TAGDIR=/var/run/console
[ -n "$CK_SESSION_USER_UID" ] || exit 1
[ "$CK_SESSION_IS_LOCAL" = "true" ] || exit 0
TAGFILE="$TAGDIR/`getent passwd $CK_SESSION_USER_UID | cut -f 1 -d:`"
if [ "$1" = "session_added" ]; then
    mkdir -p "$TAGDIR"
    echo "$CK_SESSION_ID" >> "$TAGFILE"
fi
if [ "$1" = "session_removed" ] && [ -e "$TAGFILE" ]; then
    sed -i "\%^$CK_SESSION_ID\$%d" "$TAGFILE"
    [ -s "$TAGFILE" ] || rm -f "$TAGFILE"
fi' > /usr/lib/ConsoleKit/run-session.d/pam-foreground-compat.ck
	chmod -v 755 /usr/lib/ConsoleKit/run-session.d/pam-foreground-compat.ck
	cd ..
	rm -rvf ConsoleKit2-1.0.1
	let "STEP++"
fi

#gtk+-2.24.29
if [ $STEP -eq 71 ]; then
	tar -xvf gtk+-2.24.29.tar.xz
	cd gtk+-2.24.29
	sed -e 's#l \(gtk-.*\).sgml#& -o \1#' -i docs/{faq,tutorial}/Makefile.in
	./configure --prefix=/usr --sysconfdir=/etc
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gtk+-2.24.29
	let "STEP++"
fi

#-------------------------------------------------------
#Next packages need at least one package installed above
#-------------------------------------------------------

#gtk+-3.18.7
if [ $STEP -eq 71 ]; then
	tar -xvf gtk+-3.18.7.tar.xz
	cd gtk+-3.18.7
	./configure \
		--prefix=/usr \
            	--sysconfdir=/etc \
            	--enable-broadway-backend \
            	--enable-x11-backend \
            	--disable-wayland-backend
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gtk+-3.18.7
	let "STEP++"
fi

#xcursor-themes-1.0.4
if [ $STEP -eq 71 ]; then
	tar -xvf xcursor-themes-1.0.4.tar.bz2
	cd xcursor-themes-1.0.4
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xcursor-themes-1.0.4
	let "STEP++"
fi

#libxfce4ui-4.12.1
if [ $STEP -eq 71 ]; then
	tar -xvf libxfce4ui-4.12.1.tar.bz2
	cd libxfce4ui-4.12.1
	./configure --prefix=/usr --sysconfdir=/etc
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libxfce4ui-4.12.1
	let "STEP++"
fi

#cups-filters-1.8.2
if [ $STEP -eq 71 ]; then
	tar -xvf cups-filters-1.8.2.tar.xz
	cd cups-filters-1.8.2
	./configure \
        	--prefix=/usr \
        	--sysconfdir=/etc \
        	--localstatedir=/var \
        	--without-rcdir \
        	--disable-static \
        	--with-gs-path=/usr/bin/gs \
        	--with-pdftops-path=/usr/bin/gs \
        	--docdir=/usr/share/doc/cups-filters-1.8.2
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf cups-filters-1.8.2
	let "STEP++"
fi

#libglade-2.6.4
if [ $STEP -eq 71 ]; then
	tar -xvf libglade-2.6.4.tar.bz2
	cd libglade-2.6.4
	sed -i '/DG_DISABLE_DEPRECATED/d' glade/Makefile.in
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libglade-2.6.4
	let "STEP++"
fi

#vte-0.28.2
if [ $STEP -eq 71 ]; then
	tar -xvf vte-0.28.2.tar.xz
	cd vte-0.28.2
	./configure \
		--prefix=/usr \
	        --libexecdir=/usr/lib/vte \
	        --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf vte-0.28.2
	let "STEP++"
fi

#xsane-0.999
if [ $STEP -eq 71 ]; then
	tar -xvf xsane-0.999.tar.gz
	cd xsane-0.999
	sed -i -e 's/png_ptr->jmpbuf/png_jmpbuf(png_ptr)/' src/xsane-save.c
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS xsanedocdir=/usr/share/doc/xsane-0.999 install
	ln -v -s ../../doc/xsane-0.999 /usr/share/sane/xsane/doc
	cd ..
	rm -rvf xsane-0.999
	let "STEP++"
fi

#epdfview-0.1.8
if [ $STEP -eq 71 ]; then
	tar -xvf epdfview-0.1.8.tar.bz2
	cd epdfview-0.1.8
	patch -Np1 -i ../epdfview-0.1.8-fixes-2.patch
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	for size in 24 32 48; do
  		ln -svf /usr/epdfview/pixmaps/icon_epdfview-$size.png /usr/share/icons/hicolor/${size}x${size}/apps
	done
	unset size
	update-desktop-database
	gtk-update-icon-cache -t -f --include-image-data /usr/share/icons/hicolor
	cd ..
	rm -rvf epdfview-0.1.8
	let "STEP++"
fi

#libwnck-2.30.7
if [ $STEP -eq 71 ]; then
	tar -xvf libwnck-2.30.7.tar.xz
	cd libwnck-2.30.7
	./configure \
		--prefix=/usr \
            	--disable-static \
            	--program-suffix=-1
	make -j $JOBS GETTEXT_PACKAGE=libwnck-1
	make -j $JOBS GETTEXT_PACKAGE=libwnck-1 install
	cd ..
	rm -rvf libwnck-2.30.7
	let "STEP++"
fi

#-------------------------------------------------------
#Next packages need at least one package installed above
#-------------------------------------------------------

#avahi-0.6.31
if [ $STEP -eq 71 ]; then
	tar -xvf avahi-0.6.31.tar.gz
	cd avahi-0.6.31
	groupadd -fg 84 avahi
	useradd -c "Avahi Daemon Owner" -d /var/run/avahi-daemon -u 84 -g avahi -s /bin/false avahi
	groupadd -fg 86 netdev
	sed -i 's/\(CFLAGS=.*\)-Werror \(.*\)/\1\2/' configure
	sed -e 's/-DG_DISABLE_DEPRECATED=1//' -e '/-DGDK_DISABLE_DEPRECATED/d' -i avahi-ui/Makefile.in
	./configure \
		--prefix=/usr \
            	--sysconfdir=/etc \
            	--localstatedir=/var \
            	--disable-static \
            	--disable-mono \
            	--disable-monodoc \
            	--disable-python \
            	--disable-qt3 \
            	--disable-qt4 \
            	--enable-core-docs \
            	--with-distro=none \
            	--with-systemdsystemunitdir=no
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf avahi-0.6.31
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-avahi
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#xorg-fonts
if [ $STEP -eq 38 ]; then
	for package in font-util-1.3.1.tar.bz2 \
		encodings-1.0.4.tar.bz2 \
		font-adobe-100dpi-1.0.3.tar.bz2 \
		font-adobe-75dpi-1.0.3.tar.bz2 \
		font-adobe-utopia-100dpi-1.0.4.tar.bz2 \
		font-adobe-utopia-75dpi-1.0.4.tar.bz2 \
		font-adobe-utopia-type1-1.0.4.tar.bz2 \
		font-alias-1.0.3.tar.bz2 \
		font-arabic-misc-1.0.3.tar.bz2 \
		font-bh-100dpi-1.0.3.tar.bz2 \
		font-bh-75dpi-1.0.3.tar.bz2 \
		font-bh-lucidatypewriter-100dpi-1.0.3.tar.bz2 \
		font-bh-lucidatypewriter-75dpi-1.0.3.tar.bz2 \
		font-bh-ttf-1.0.3.tar.bz2 \
		font-bh-type1-1.0.3.tar.bz2 \
		font-bitstream-100dpi-1.0.3.tar.bz2 \
		font-bitstream-75dpi-1.0.3.tar.bz2 \
		font-bitstream-type1-1.0.3.tar.bz2 \
		font-cronyx-cyrillic-1.0.3.tar.bz2 \
		font-cursor-misc-1.0.3.tar.bz2 \
		font-daewoo-misc-1.0.3.tar.bz2 \
		font-dec-misc-1.0.3.tar.bz2 \
		font-ibm-type1-1.0.3.tar.bz2 \
		font-isas-misc-1.0.3.tar.bz2 \
		font-jis-misc-1.0.3.tar.bz2 \
		font-micro-misc-1.0.3.tar.bz2 \
		font-misc-cyrillic-1.0.3.tar.bz2 \
		font-misc-ethiopic-1.0.3.tar.bz2 \
		font-misc-meltho-1.0.3.tar.bz2 \
		font-misc-misc-1.1.2.tar.bz2 \
		font-mutt-misc-1.0.3.tar.bz2 \
		font-schumacher-misc-1.1.2.tar.bz2 \
		font-screen-cyrillic-1.0.4.tar.bz2 \
		font-sony-misc-1.0.3.tar.bz2 \
		font-sun-misc-1.0.3.tar.bz2 \
		font-winitzki-cyrillic-1.0.3.ar.bz2 \
		font-xfree86-type1-1.0.4.tar.bz2
	do
		packagedir=${package%.tar.bz2}
		tar -xvf $package
		pushd $packagedir
		./configure \
			--prefix=/usr \
			--sysconfdir=/etc \
	    		--localstatedir=/var \
	    		--disable-static
		make -j $JOBS
		make -j $JOBS install
		popd
		rm -rvf $packagedir
	done
	install -v -d -m755 /usr/share/fonts
	ln -svfn /usr/share/fonts/X11/OTF /usr/share/fonts/X11-OTF
	ln -svfn /usr/share/fonts/X11/TTF /usr/share/fonts/X11-TTF
	let "STEP++"
fi

#exo-0.10.7
if [ $STEP -eq 71 ]; then
	tar -xvf exo-0.10.7.tar.bz2
	cd exo-0.10.7
	./configure --prefix=/usr --sysconfdir=/etc
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf exo-0.10.7
	let "STEP++"
fi

#garcon-0.5.0
if [ $STEP -eq 71 ]; then
	tar -xvf garcon-0.5.0.tar.bz2
	cd garcon-0.5.0
	./configure --prefix=/usr --sysconfdir=/etc
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf garcon-0.5.0
	let "STEP++"
fi

#gtk-xfce-engine-3.2.0
if [ $STEP -eq 71 ]; then
	tar -xvf gtk-xfce-engine-3.2.0.tar.bz2
	cd gtk-xfce-engine-3.2.0
	./configure --prefix=/usr --enable-gtk3
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gtk-xfce-engine-3.2.0
	let "STEP++"
fi

#librsvg-2.40.13
if [ $STEP -eq 71 ]; then
	tar -xvf librsvg-2.40.13.tar.xz
	cd librsvg-2.40.13
	./configure \
		--prefix=/usr \
            	--enable-vala \
            	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf librsvg-2.40.13
	let "STEP++"
fi

#libnotify-0.7.6
if [ $STEP -eq 71 ]; then
	tar -xvf libnotify-0.7.6.tar.xz
	cd libnotify-0.7.6
	./configure --prefix=/usr --disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libnotify-0.7.6
	let "STEP++"
fi

#libcanberra-0.30
if [ $STEP -eq 71 ]; then
	tar -xvf libcanberra-0.30.tar.xz
	cd libcanberra-0.30
	./configure --prefix=/usr --disable-oss
	make -j $JOBS
	make -j $JOBS docdir=/usr/share/doc/libcanberra-0.30 install
	cd ..
	rm -rvf libcanberra-0.30
	let "STEP++"
fi

#gvfs-1.26.2
if [ $STEP -eq 71 ]; then
	tar -xvf gvfs-1.26.2.tar.xz
	cd gvfs-1.26.2
	./configure \
		--prefix=/usr \
            	--sysconfdir=/etc \
            	--disable-gphoto2
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gvfs-1.26.2
	let "STEP++"
fi

#gcr-3.18.0
if [ $STEP -eq 71 ]; then
	tar -xvf gcr-3.18.0.tar.xz
	cd gcr-3.18.0
	sed -i -r 's:"(/desktop):"/org/gnome\1:' schema/*.xml
	./configure --prefix=/usr --sysconfdir=/etc
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gcr-3.18.0
	let "STEP++"
fi

#polkit-gnome-0.105
if [ $STEP -eq 71 ]; then
	tar -xvf polkit-gnome-0.105.tar.xz
	cd polkit-gnome-0.105
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	mkdir -pv /etc/xdg/autostart
	echo '[Desktop Entry]
Name=PolicyKit Authentication Agent
Comment=PolicyKit Authentication Agent
Exec=/usr/libexec/polkit-gnome-authentication-agent-1
Terminal=false
Type=Application
Categories=
NoDisplay=true
OnlyShowIn=GNOME;XFCE;Unity;
AutostartCondition=GNOME3 unless-session gnome' > /etc/xdg/autostart/polkit-gnome-authentication-agent-1.desktop
	cd ..
	rm -rvf polkit-gnome-0.105
	let "STEP++"
fi

#xfwm4-4.12.3
if [ $STEP -eq 71 ]; then
	tar -xvf xfwm4-4.12.3.tar.bz2
	cd xfwm4-4.12.3
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xfwm4-4.12.3
	let "STEP++"
fi

#gconf-3.2.6
if [ $STEP -eq 71 ]; then
	tar -xvf GConf-3.2.6.tar.xz
	cd GConf-3.2.6
	./configure \
		--prefix=/usr \
            	--sysconfdir=/etc \
            	--disable-orbit \
            	--disable-static
	make -j $JOBS
	make -j $JOBS install
	ln -sv gconf.xml.defaults /etc/gconf/gconf.xml.system
	cd ..
	rm -rvf GConf-3.2.6
	let "STEP++"
fi

#gtksourceview-3.18.2
if [ $STEP -eq 71 ]; then
	tar -xvf gtksourceview-3.18.2.tar.xz
	cd gtksourceview-3.18.2
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gtksourceview-3.18.2
	let "STEP++"
fi

#xfce4-terminal-0.6.3
if [ $STEP -eq 71 ]; then
	tar -xvf xfce4-terminal-0.6.3.tar.bz2
	cd xfce4-terminal-0.6.3
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xfce4-terminal-0.6.3
	let "STEP++"
fi

#ristretto-0.8.0
if [ $STEP -eq 71 ]; then
	tar -xvf ristretto-0.8.0.tar.bz2
	cd ristretto-0.8.0
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf ristretto-0.8.0
	let "STEP++"
fi

#libreoffice-5.1.0.3
if [ $STEP -eq 71 ]; then
	tar -xvf libreoffice-5.1.0.3.tar.xz --no-overwrite-dir
	cd libreoffice-5.1.0.3
	install -dm755 external/tarballs
	ln -sv ../../../libreoffice-dictionaries-5.1.0.3.tar.xz external/tarballs/
	ln -sv ../../../libreoffice-help-5.1.0.3.tar.xz external/tarballs/
	ln -sv ../../../libreoffice-translations-5.1.0.3.tar.xz external/tarballs/
	sed -e "/gzip -f/d" -e "s|.1.gz|.1|g" -i bin/distro-install-desktop-integration
	sed -e "/distro-install-file-lists/d" -i Makefile.in
	sed -i "s#isnan#std::&#g" xmloff/source/draw/ximp3dscene.cxx
	chmod -v +x bin/unpack-sources
	./autogen.sh \
		--prefix=/usr \
             	--sysconfdir=/etc \
             	--with-vendor=BLFS \
             	--with-lang='en-US fr' \
             	--with-help \
             	--with-myspell-dicts \
             	--with-alloc=system \
             	--without-java \
             	--without-system-dicts \
             	--disable-dconf \
             	--disable-odk \
             	--enable-release-build=yes \
             	--enable-python=system \
             	--with-system-apr \
             	--with-system-boost=yes \
             	--with-system-cairo \
             	--with-system-clucene \
             	--with-system-curl \
             	--with-system-expat \
             	--with-system-graphite \
             	--with-system-harfbuzz \
             	--with-system-icu \
             	--with-system-jpeg \
             	--with-system-lcms2 \
             	--with-system-libatomic_ops \
             	--with-system-libpng \
             	--with-system-libxml \
             	--with-system-neon \
             	--with-system-npapi-headers \
             	--with-system-nss \
             	--with-system-odbc \
             	--with-system-openldap \
             	--with-system-openssl \
             	--with-system-poppler \
             	--with-system-postgresql \
             	--with-system-redland \
             	--with-system-serf \
             	--with-system-zlib \
             	--with-parallelism=$JOBS
	make -j $JOBS build
	make -j $JOBS distro-pack-install
	install -v -m755 -d /usr/share/appdata
	install -v -m644 sysui/desktop/appstream-appdata/*.xml /usr/share/appdata
	update-desktop-database
	cd ..
	rm -rvf libreoffice-5.1.0.3
	let "STEP++"
fi

#transmission-2.84
if [ $STEP -eq 71 ]; then
	tar -xvf transmission-2.84.tar.xz
	cd transmission-2.84
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf transmission-2.84
	let "STEP++"
fi

#xarchiver-0.5.4
if [ $STEP -eq 71 ]; then
	tar -xvf xarchiver-0.5.4.tar.bz2
	cd xarchiver-0.5.4
	patch -Np1 -i ../xarchiver-0.5.4-fixes-1.patch
	./autogen.sh \
		--prefix=/usr \
	        --libexecdir=/usr/lib/xfce4 \
	        --docdir=/usr/share/doc/xarchiver-0.5.4
	make -j $JOBS
	make -j $JOBS DOCDIR=/usr/share/doc/xarchiver-0.5.4 install
	update-desktop-database
	gtk-update-icon-cache -t -f --include-image-data /usr/share/icons/hicolor
	cd ..
	rm -rvf xarchiver-0.5.4
	let "STEP++"
fi

#glade-3.20.0
if [ $STEP -eq 71 ]; then
	tar -xvf glade-3.20.0.tar.xz
	cd glade-3.20.0
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--runstatedir=/run
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf glade-3.20.0
	let "STEP++"
fi

#gtkmm-3.18.0
if [ $STEP -eq 71 ]; then
	tar -xvf gtkmm-3.18.0.tar.xz
	cd gtkmm-3.18.0
	sed -e '/^libdocdir =/ s/$(book_name)/gtkmm-3.18.0/' -i docs/Makefile.in
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gtkmm-3.18.0
	let "STEP++"
fi

#libwnck-3.14.1
if [ $STEP -eq 71 ]; then
	tar -xvf libwnck-3.14.1.tar.xz
	cd libwnck-3.14.1
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf libwnck-3.14.1
	let "STEP++"
fi

#pygtk-2.24.0
if [ $STEP -eq 71 ]; then
	tar -xvf pygtk-2.24.0.tar.bz2
	cd pygtk-2.24.0
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf pygtk-2.24.0
	let "STEP++"
fi

#lxdm-0.5.3
if [ $STEP -eq 71 ]; then
	tar -xvf lxdm-0.5.3.tar.xz
	cd lxdm-0.5.3
	cp -v /alfs/etc/pam.d/lxdm pam/lxdm
	sed -i 's:sysconfig/i18n:profile.d/i18n.sh:g' data/lxdm.in
	sed -i 's:/etc/xprofile:/etc/profile:g' data/Xsession
	sed -e 's/^bg/#&/' -e '/reset=1/ s/# //' -e 's/logou$/logout/' -e "/arg=/a arg=/usr/bin/X" -i data/lxdm.conf.in
	./configure \
		--prefix=/usr \
	        --sysconfdir=/etc \
	        --with-pam  \
	        --with-systemdsystemunitdir=no
	make -j $JOBS
	make -j $JOBS install
	sed -i '/^# session/ a\session=/usr/bin/startxfce4' /etc/lxdm/lxdm.conf
	sed -i '/initdefault/ s/3/5/' /etc/inittab
	cd ..
	rm -rvf lxdm-0.5.3
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-lxdm
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#-------------------------------------------------------
#Next packages need at least one package installed above
#-------------------------------------------------------

#xorg-server-1.18.1
if [ $STEP -eq 71 ]; then
	tar -xvf xorg-server-1.18.1.tar.bz2
	cd xorg-server-1.18.1
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static \
           	--enable-glamor \
           	--enable-install-setuid \
           	--enable-suid-wrapper \
           	--disable-systemd-logind \
           	--with-xkb-output=/var/lib/xkb \
           	--enable-kdrive \
           	--enable-dmx
	make -j $JOBS
	make -j $JOBS install
	mkdir -pv /etc/X11/xorg.conf.d
	echo '/tmp/.ICE-unix dir 1777 root root
/tmp/.X11-unix dir 1777 root root' >> /etc/sysconfig/createfiles
	cd ..
	rm -rvf xorg-server-1.18.1
	let "STEP++"
fi

#xfce4-panel-4.12.0
if [ $STEP -eq 71 ]; then
	tar -xvf xfce4-panel-4.12.0.tar.bz2
	cd xfce4-panel-4.12.0
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--enable-gtk3
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xfce4-panel-4.12.0
	let "STEP++"
fi

#xfce4-notifyd-0.2.4
if [ $STEP -eq 71 ]; then
	tar -xvf xfce4-notifyd-0.2.4.tar.bz2
	cd xfce4-notifyd-0.2.4
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xfce4-notifyd-0.2.4
	let "STEP++"
fi

#gnome-keyring-3.18.3
if [ $STEP -eq 71 ]; then
	tar -xvf gnome-keyring-3.18.3.tar.xz
	cd gnome-keyring-3.18.3
	sed -i -r 's:"(/desktop):"/org/gnome\1:' schema/*.xml
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--with-pam-dir=/lib/security
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gnome-keyring-3.18.3
	let "STEP++"
fi

#xfce4-appfinder-4.12.0
if [ $STEP -eq 71 ]; then
	tar -xvf xfce4-appfinder-4.12.0.tar.bz2
	cd xfce4-appfinder-4.12.0
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xfce4-appfinder-4.12.0
	let "STEP++"
fi

#xfce4-settings-4.12.0
if [ $STEP -eq 71 ]; then
	tar -xvf xfce4-settings-4.12.0.tar.bz2
	cd xfce4-settings-4.12.0
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--enable-sound-settings \
		--enable-pluggable-dialogs
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xfce4-settings-4.12.0
	let "STEP++"
fi

#xfce4-session-4.12.1
if [ $STEP -eq 71 ]; then
	tar -xvf xfce4-session-4.12.1.tar.bz2
	cd xfce4-session-4.12.1
	./configure \
		--prefix=/usr \
	        --sysconfdir=/etc \
	        --disable-legacy-sm
	make -j $JOBS
	make -j $JOBS install
	update-desktop-database
	update-mime-database
	cd ..
	rm -rvf xfce4-session-4.12.1
	let "STEP++"
fi

#geoclue-0.12.0
if [ $STEP -eq 71 ]; then
	tar -xvf geoclue-0.12.0.tar.gz
	cd geoclue-0.12.0
	sed -i "s@ -Werror@@" configure
	sed -i "s@libnm_glib@libnm-glib@g" configure
	sed -i "s@geoclue/libgeoclue.la@& -lgthread-2.0@g" providers/skyhook/Makefile.in
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf geoclue-0.12.0
	let "STEP++"
fi

#parole-0.8.1
if [ $STEP -eq 71 ]; then
	tar -xvf parole-0.8.1.tar.bz2
	cd parole-0.8.1
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf parole-0.8.1
	let "STEP++"
fi

#mousepad-0.4.0
if [ $STEP -eq 71 ]; then
	tar -xvf mousepad-0.4.0.tar.bz2
	cd mousepad-0.4.0
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf mousepad-0.4.0
	let "STEP++"
fi

#gigolo-0.4.2
if [ $STEP -eq 71 ]; then
	tar -xvf gigolo-0.4.2.tar.bz2
	cd gigolo-0.4.2
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--runstatedir=/run
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gigolo-0.4.2
	let "STEP++"
fi

#xfce4-taskmanager-1.1.0
if [ $STEP -eq 71 ]; then
	tar -xvf xfce4-taskmanager-1.1.0.tar.bz2
	cd xfce4-taskmanager-1.1.0
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--runstatedir=/run \
		--enable-gtk3
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xfce4-taskmanager-1.1.0
	let "STEP++"
fi

#wicd-1.7.4
if [ $STEP -eq 71 ]; then
	tar -xvf wicd-1.7.4.tar.gz
	cd wicd-1.7.4
	sed -e "/wpath.logrotate\|wpath.systemd/d" -e "/detection failed/ a\ self.init=\'init\/default\/wicd\'" -i.orig setup.py
	rm -v po/*.po
	python setup.py configure \
		--no-install-kde \
                --no-install-init \
                --no-install-gnome-shell-extensions \
                --docdir=/usr/share/doc/wicd-1.7.4
	python setup.py install
	cd ..
	rm -rvf wicd-1.7.4
	tar -xvf blfs-bootscripts-20150924.tar.bz2
	cd blfs-bootscripts-20150924
	make -j $JOBS install-wicd
	cd ..
	rm -rvf blfs-bootscripts-20150924
	let "STEP++"
fi

#gimp-2.8.16
if [ $STEP -eq 71 ]; then
	tar -xvf gimp-2.8.16.tar.bz2
	cd gimp-2.8.16
	./configure \
		--prefix=/usr \
	        --sysconfdir=/etc \
	        --without-gvfs
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf gimp-2.8.16
	let "STEP++"
fi

#-------------------------------------------------------
#Next packages need at least one package installed above
#-------------------------------------------------------

#xf86-input-evdev-2.10.1
if [ $STEP -eq 71 ]; then
	tar -xvf xf86-input-evdev-2.10.1.tar.bz2
	cd xf86-input-evdev-2.10.1
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xf86-input-evdev-2.10.1
	let "STEP++"
fi

#xf86-input-synaptics-1.8.3
if [ $STEP -eq 71 ]; then
	tar -xvf xf86-input-synaptics-1.8.3.tar.bz2
	cd xf86-input-synaptics-1.8.3
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xf86-input-synaptics-1.8.3
	let "STEP++"
fi

#xf86-video-ati-7.6.1
if [ $STEP -eq 71 ]; then
	tar -xvf xf86-video-ati-7.6.1.tar.bz2
	cd xf86-video-ati-7.6.1
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xf86-video-ati-7.6.1
	let "STEP++"
fi

#xf86-video-fbdev-0.4.4
if [ $STEP -eq 71 ]; then
	tar -xvf xf86-video-fbdev-0.4.4.tar.bz2
	cd xf86-video-fbdev-0.4.4
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xf86-video-fbdev-0.4.4
	let "STEP++"
fi

#xf86-video-intel-0340718
if [ $STEP -eq 71 ]; then
	tar -xvf xf86-video-intel-0340718.tar.xz
	cd xf86-video-intel
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static \
	    	--enable-kms-only \
	    	--enable-uxa
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xf86-video-intel
	let "STEP++"
fi

#xf86-video-nouveau-1.0.12
if [ $STEP -eq 71 ]; then
	tar -xvf xf86-video-nouveau-1.0.12.tar.bz2
	cd xf86-video-nouveau-1.0.12
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xf86-video-nouveau-1.0.12
	let "STEP++"
fi

#xf86-video-vmware-13.1.10
if [ $STEP -eq 71 ]; then
	tar -xvf xf86-video-vmware-13.1.10.tar.bz2
	cd xf86-video-vmware-13.1.10
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
	    	--localstatedir=/var \
	    	--disable-static
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xf86-video-vmware-13.1.10
	let "STEP++"
fi

#xfce4-xkb-plugin-0.7.1
if [ $STEP -eq 71 ]; then
	tar -xvf xfce4-xkb-plugin-0.7.1.tar.bz2
	cd xfce4-xkb-plugin-0.7.1
	sed -e 's|xfce4/panel-plugins|xfce4/panel/plugins|' -i panel-plugin/{Makefile.in,xkb-plugin.desktop.in.in}
	./configure \
		--prefix=/usr \
		--libexecdir=/usr/lib \
		--disable-debug
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xfce4-xkb-plugin-0.7.1
	let "STEP++"
fi

#thunar-1.6.10
if [ $STEP -eq 71 ]; then
	tar -xvf Thunar-1.6.10.tar.bz2
	cd Thunar-1.6.10
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc \
		--docdir=/usr/share/doc/Thunar-1.6.10
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf Thunar-1.6.10
	let "STEP++"
fi

#xfce4-power-manager-1.4.4
if [ $STEP -eq 71 ]; then
	tar -xvf xfce4-power-manager-1.4.4.tar.bz2
	cd xfce4-power-manager-1.4.4
	./configure \
		--prefix=/usr \
		--sysconfdir=/etc
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xfce4-power-manager-1.4.4
	let "STEP++"
fi

#webkitgtk-2.4.9
if [ $STEP -eq 71 ]; then
	tar -xvf webkitgtk-2.4.9.tar.xz
	cd webkitgtk-2.4.9
	sed -e '/generate-gtkdoc --rebase/s:^:# :' -i GNUmakefile.in
	mkdir -pv build-3
	cp -av Documentation build-3
	cd build-3
	../configure --prefix=/usr --enable-introspection
	make -j $JOBS
	make -j $JOBS install
	cd ../..
	rm -rvf webkitgtk-2.4.9
	let "STEP++"
fi

#xfce4-calculator-plugin-0.5.1
if [ $STEP -eq 71 ]; then
	tar -xvf xfce4-calculator-plugin-0.5.1.tar.bz2
	cd xfce4-calculator-plugin-0.5.1
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xfce4-calculator-plugin-0.5.1
	let "STEP++"
fi

#xfce4-genmon-plugin-3.4.0
if [ $STEP -eq 71 ]; then
	tar -xvf xfce4-genmon-plugin-3.4.0.tar.bz2
	cd xfce4-genmon-plugin-3.4
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xfce4-genmon-plugin-3.4
	let "STEP++"
fi

#xfce4-timer-plugin-1.6.0
if [ $STEP -eq 71 ]; then
	tar -xvf xfce4-timer-plugin-1.6.0.tar.bz2
	cd xfce4-timer-plugin-1.6.0
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xfce4-timer-plugin-1.6.0
	let "STEP++"
fi

#xfce4-screenshooter-1.8.2
if [ $STEP -eq 71 ]; then
	tar -xvf xfce4-screenshooter-1.8.2.tar.bz2
	cd xfce4-screenshooter-1.8.2
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xfce4-screenshooter-1.8.2
	let "STEP++"
fi

#-------------------------------------------------------
#Next packages need at least one package installed above
#-------------------------------------------------------

#qemu-2.5.0
if [ $STEP -eq 71 ]; then
	tar -xvf qemu-2.5.0.tar.bz2
	cd qemu-2.5.0
	mkdir -pv build
	cd build
	./configure \
		--prefix=/usr \
             	--sysconfdir=/etc \
             	--target-list=x86_64-softmmu \
             	--audio-drv-list=alsa \
             	--docdir=/usr/share/doc/qemu-2.5.0
	make -j $JOBS
	make -j $JOBS install
	[ -e /usr/lib/libcacard.so ] && chmod -v 755 /usr/lib/libcacard.so
	groupadd -g 61 kvm
	#usermod -a -G kvm <username>
	echo 'KERNEL=="kvm", GROUP="kvm", MODE="0660"' > /lib/udev/rules.d/65-kvm.rules
	ln -sv qemu-system-x86_64 /usr/bin/qemu
	cd ../..
	rm -rvf qemu-2.5.0
	let "STEP++"
fi

#xfdesktop-4.12.3
if [ $STEP -eq 71 ]; then
	tar -xvf xfdesktop-4.12.3.tar.bz2
	cd xfdesktop-4.12.3
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf xfdesktop-4.12.3
	let "STEP++"
fi

#midori-0.5.11
if [ $STEP -eq 71 ]; then
	tar -xvf midori_0.5.11_all_.tar.bz2
	cd midori-0.5.11
	mkdir -v build
	cd build
	cmake \
		-DCMAKE_INSTALL_PREFIX=/usr \
      		-DCMAKE_BUILD_TYPE=Release \
      		-DUSE_ZEITGEIST=OFF \
      		-DUSE_GTK3=1 \
      		-DCMAKE_INSTALL_DOCDIR=/usr/share/doc/midori-0.5.11 \
      		..
	make -j $JOBS
	make -j $JOBS install
	cd ../..
	rm -rvf midori-0.5.11
	let "STEP++"
fi

#thunar-volman-0.8.1
if [ $STEP -eq 71 ]; then
	tar -xvf thunar-volman-0.8.1.tar.bz2
	cd thunar-volman-0.8.1
	./configure --prefix=/usr
	make -j $JOBS
	make -j $JOBS install
	cd ..
	rm -rvf thunar-volman-0.8.1
	let "STEP++"
fi

#final-configuration
if [ $STEP -eq 71 ]; then
	let "STEP++"
fi

#-------------------------------------------------------
#Next packages need at least one package installed above
#-------------------------------------------------------
