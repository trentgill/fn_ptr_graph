module_name = goth

WRLIB=../wrLib
WRDSP=../wrDsp

CC = gcc
LD = gcc
GHC = ghc

SRC = main.c \
      dsp_block.c \
      $(WRLIB)/wrMath.c \
	  $(WRDSP)/wrCliHelpers.c \
      $(WRDSP)/wrFilterCli.c \
      $(WRDSP)/wrFilter.c \
      $(WRDSP)/wrOscSineCli.c \
      $(WRDSP)/wrOscSine.c \
	  $(WRDSP)/wrLpGateCli.c \
	  $(WRDSP)/wrLpGate.c

# NB! files must be listed bottom-up (main is last)
# otherwise dependencies aren't found
HMAIN = Hcli
HSRC = FTypes.hs \
       DSP.hs \
	   Dict.hs \
       $(HMAIN).hs

OBJDIR = .
OBJS = $(SRC:%.c=$(OBJDIR)/%.o)

HOBJDIR = .
HOBJS = $(HSRC:%.hs=$(OBJDIR)/%.hi)
HOBJS += $(HSRC:%.hs=$(OBJDIR)/%.o)

EXECUTABLE = $(module_name)

INCLUDES = \
    -I$(WRLIB)/ \
    -I$(WRDSP)/

HsFFI=/usr/lib/ghc/include/

HCINCLUDES = -I$(HsFFI)

HCFLAGS = -lm -lc -lsoundio -D
HCFLAGS += $(DEFS) -I. -I./ $(INCLUDES) $(HCINCLUDES)

LDFLAGS =
LIBS = -lm -lc -lsoundio

all:
	@touch $(EXECUTABLE)
	@rm ./$(EXECUTABLE)
	ghc -c -O $(HCFLAGS) $(HSRC)
	ghc --make -no-hs-main -optc-O $(HCFLAGS) $(SRC) $(HMAIN) -o $(EXECUTABLE)

clean:
	rm $(OBJS) $(EXECUTABLE) $(HOBJS) $(HMAIN)_stub.h

.PHONY: all clean
