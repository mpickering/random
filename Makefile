# -----------------------------------------------------------------------------
# $Id: Makefile,v 1.27 2002/05/10 13:16:55 simonmar Exp $

TOP=..
include $(TOP)/mk/boilerplate.mk

# -----------------------------------------------------------------------------

SUBDIRS = cbits include

ALL_DIRS = \
	Control \
	Control/Concurrent \
	Control/Monad \
	Control/Monad/ST \
	Data \
	Data/Array \
	Database \
	Debug \
	Debug/QuickCheck \
	FileFormat \
	Foreign \
	Foreign/C \
	Foreign/Marshal \
	GHC \
	Hugs \
	Language \
	Network \
	NHC \
	System \
	System/Console \
	System/Mem \
	System/IO \
	Text \
	Text/Html \
	Text/PrettyPrint \
	Text/ParserCombinators \
	Text/Regex \
	Text/Show \
	Text/Read

PACKAGE = base

SRC_HC_OPTS += -fglasgow-exts -cpp -Iinclude
SRC_HSC2HS_OPTS += -Iinclude

# Make sure we can get hold of regex.h
ifneq "$(HavePosixRegex)" "YES"
SRC_HC_OPTS     += -Icbits/regex
SRC_HSC2HS_OPTS += -Icbits/regex
endif

# -----------------------------------------------------------------------------
# Per-module flags

# ESSENTIAL, for getting reasonable performance from the I/O library:
SRC_HC_OPTS += -funbox-strict-fields

# -----------------------------------------------------------------------------
# PrimOpWrappers

GHC/PrimopWrappers.hs: $(GHC_COMPILER_DIR)/prelude/primops.txt
	rm -f $@
	$(GHC_GENPRIMOP) --make-haskell-wrappers < $< > $@

boot :: GHC/PrimopWrappers.hs

EXTRA_SRCS  += GHC/PrimopWrappers.hs
CLEAN_FILES += GHC/PrimopWrappers.hs

#-----------------------------------------------------------------------------
# 	Building the library for GHCi
#
# The procedure differs from that in fptools/mk/target.mk in one way:
#  (*) on Win32 we must split it into two, because a single .o file can't
#      have more than 65536 relocations in it.

ifeq "$(TARGETPLATFORM)" "i386-unknown-mingw32"

# Turn off standard rule which creates HSbase.o from LIBOBJS.
DONT_WANT_STD_GHCI_LIB_RULE=YES

GHCI_LIBOBJS = $(HS_OBJS)

INSTALL_LIBS += HSbase1.o HSbase2.o

endif # TARGETPLATFORM = i386-unknown-mingw32


# -----------------------------------------------------------------------------
# Doc building with Haddock

EXCLUDED_HADDOCK_SRCS = \
	Data/Generics.hs \
	GHC/PArr.hs

HS_PPS = $(addsuffix .raw-hs, $(basename $(filter-out $(EXCLUDED_HADDOCK_SRCS), $(HS_SRCS))))

HADDOCK = $(FPTOOLS_TOP)/haddock/src/haddock-inplace

# Urgh, hack needed to ensure that the value of HS_SRCS is computed in time for
# the docs rule below.
PRE_SRCS := $(ALL_SRCS)

.PHONY: docs
haddock-docs : $(HS_PPS)
	$(HADDOCK) -t "Haskell Core Libraries" -h -s "." $(HS_PPS)

%.raw-hs : %.lhs
	$(GHC_INPLACE) $(HC_OPTS) -D__HADDOCK__ -E -cpp $< -o $<.tmp && sed -e 's/^#.*//' <$<.tmp >$@

%.raw-hs : %.hs
	$(GHC_INPLACE) $(HC_OPTS) -E -cpp $< -o $<.tmp && sed -e 's/^#.*//' <$<.tmp >$@

# -----------------------------------------------------------------------------

include $(TOP)/mk/target.mk

ifeq "$(TARGETPLATFORM)" "i386-unknown-mingw32"
HSbase.o : $(GHCI_LIBOBJS)
	$(LD) -r $(LD_X) -o HSbase1.o $(filter     GHC/%, $(GHCI_LIBOBJS))
	$(LD) -r $(LD_X) -o HSbase2.o $(filter-out GHC/%, $(GHCI_LIBOBJS))
	@touch HSbase.o
endif # TARGETPLATFORM = i386-unknown-mingw32

