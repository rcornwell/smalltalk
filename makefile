#
# Makefile for Smalltalk
#
.SUFFIXES:	.exe .rc .res .ico .sti .obj

O=obj
PROJ = smalltalk
SDK=//c/platform
INCLUDE=$(SDK)/include
CC = gcc 
RC = windres -I rc -O coff --include-dir $(INCLUDE)
HC = $(SDK)/bin/hcw
CFLAGS = -g -Wall -O2 -I$(INCLUDE) -DINLINE_OBJECT_MEM
LDFLAGS = -g -mwindows -mno-cygwin
LIBS=-lversion


SRCS = $(PROJ).c about.c image.c object.c interp.c primitive.c fileio.c \
	 	init.c dump.c lex.c code.c symbols.c parse.c

OBJS = $(PROJ).$(O) about.$(O) image.$(O) object.$(O) interp.$(O) \
	     primitive.$(O) fileio.$(O) init.$(O) dump.$(O) lex.$(O) \
	     code.$(O) symbols.$(O) parse.$(O) $(PROJ).res

SMALLSRC = basic.st stream.st magnitude.st collection.st misc.st compile.st \
	   behavior.st object.st

all:	$(PROJ).sti 

$(PROJ).sti: $(PROJ).exe $(PROJ).st
	./$(PROJ).exe $(PROJ).st

$(PROJ).st: $(SMALLSRC)
	cat $(SMALLSRC) > $(PROJ).st

$(PROJ).exe: $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS) $(LIBS) 

$(PROJ).hlp: $(PROJ).rtf $(PROJ).hpj $(PROJ).cnt
	$(HC) /C /E $(PROJ).hpj

$(PROJ).res: $(PROJ).rc $(PROJ).h about.h
	$(RC) -i $< -o $@

clean:
	rm -f $(OBJS)
	rm -f $(PROJ).hlp $(PROJ).gid $(PROJ).err $(PROJ).log

.c.$(O):
	$(CC) -c $(CFLAGS) -o $@ $<

about.$(O):	about.c about.h
$(PROJ).$(O):	$(PROJ).c $(PROJ).h  about.h
object.$(O):	object.c smallobjs.h object.h
interp.$(O):	interp.c smallobjs.h object.h interp.h primitive.h dump.h
primitive.$(O):	primitive.c smallobjs.h fileio.h object.h interp.h \
		primitive.h image.h
fileio.$(O):	fileio.c smallobjs.h object.h primitive.h fileio.h 
image.$(O):	image.c object.h fileio.h image.h
dump.$(O):	dump.c smallobjs.h lex.h object.h fileio.h dump.h
init.$(O):	init.c smallobjs.h object.h interp.h fileio.h primitive.h \
		 dump.h parse.h
lex.$(O):	lex.c smallobjs.h object.h primitive.h lex.h dump.h
code.$(O):	code.c smallobjs.h object.h interp.h primitive.h lex.h \
		 symbols.h code.h
symbols.$(O):	symbols.c smallobjs.h object.h interp.h primitive.h lex.h \
		 symbols.h
parse.$(O):	parse.c smallobjs.h dump.h object.h interp.h fileio.h \
		primitive.h lex.h symbols.h code.h parse.h

