INSTALLDIR = /usr/local/mathematica/AddOns/Applications

CC = gcc
CFLAGS = -O2 -I. -Wall -static
LDLIBS = -L. -L/usr/X11/lib
AR = ar
ARFLAGS = rs
TAR = tar
TARFLAGS = zcvf
CP = cp
INSTALL = install
PACKAGES = Banzhaf.m BifCurve.m Frechet.m Ideal.m NormalForm.m	\
Puiseux.m RatSimp.m Taylor.m Tr.m WriteBin.m

unpack: $(PACKAGES) init.m

install: $(PACKAGES)
	$(INSTALL) -m0444 $(PACKAGES) $(INSTALLDIR)

init: init.m
	$(INSTALL) -m0400 init.m $(HOME)/.Mathematica/3.0/Kernel

dist: unpack VERSION Makefile
	mkdir addons-$(shell cat VERSION)
	$(CP) Makefile $(PACKAGES) init.m addons-$(shell cat VERSION)
	$(TAR) $(TARFLAGS) addons-$(shell cat VERSION).tgz addons-$(shell cat VERSION)
	$(RM) -r addons-$(shell cat VERSION) VERSION

VERSION:
	$(CO) -kv $@

%.tgz: %
	$(TAR) $(TARFLAGS) $*.tgz $*

%.gz: %
	$(GZIP) < $* > $*.gz

%: %.c $(INC) $(LIB)
	$(CC) $(CFLAGS) $*.c $(LDLIBS) -o $*

(%.o): %.c $(INC)
	$(CC) -c $(CFLAGS) $*.c -o $*.o
	$(AR) $(ARFLAGS) $@ $*.o
	$(RM) $*.o 

$(LIB):	$(LIB)($(addsuffix .o, $(basename $(SRC))))
