module_name = fpg

WRLIB=../wrLib
WRDSP=../wrDsp

CC = gcc
LD = gcc

SRC = main.c \
      dsp_block.c \
      $(WRLIB)/wrMath.c \
      $(WRDSP)/wrFilter.c \
      $(WRDSP)/wrOscSine.c

OBJDIR = .
OBJS = $(SRC:%.c=$(OBJDIR)/%.o)

EXECUTABLE = $(module_name)

INCLUDES = \
    -I$(WRLIB)/ \
    -I$(WRDSP)/

CFLAGS = -lm -lc -lsoundio -D ARCH_LINUX=1
CFLAGS += $(DEFS) -I. -I./ $(INCLUDES)
LDFLAGS =
LIBS = -lm -lc -lsoundio

all: $(OBJS)
	touch $(EXECUTABLE)
	rm ./$(EXECUTABLE)
	$(CC) $(LIBS) $(OBJS) $(CFLAGS) -o $(EXECUTABLE) -g

#	$(LD) -g $(LDFLAGS) $(OBJS) $(LIBS) -o $@

%.o: %.c
	$(CC) -ggdb $(CFLAGS) -c $< -o $@


clean:
	rm $(OBJS) $(EXECUTABLE)
