# vim: noet

test:
	perl -c lib/Ubic/Service/Spark2.pm
	#prove -v t/test.t

install:
	mkdir -p $(DESTDIR)/etc/init.d/
	cp spark2-init.pl $(DESTDIR)/etc/init.d/spark2
	cp spark2-conf-json $(DESTDIR)/usr/bin
	cp -r etc $(DESTDIR)/
	# bash completion
	mkdir -p -m755 $(DESTDIR)/etc/bash_completion.d/
	cp bash_completion $(DESTDIR)/etc/bash_completion.d/spark2_init
	# libs
	mkdir -p $(DESTDIR)/usr/share/perl5/
	cp -r lib/* $(DESTDIR)/usr/share/perl5/
	# Note: don't use dh_installinit, it generates postinst/postrm scripts, we don't need them here.

clean:
	rm -rf tfiles
