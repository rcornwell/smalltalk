#
# Makefile for Smalltalk
#
.SUFFIXES:	.exe .rc .res .ico .sti .obj

O=obj
PROJ = smalltalk
SDK=//e/sdk
INCLUDE=$(SDK)/include
CC = gcc 
RC = windres -I rc -O coff --include-dir $(INCLUDE)
HC = $(SDK)/bin/hcw
CFLAGS = -g -Wall -O2 -I$(INCLUDE) -DINLINE_OBJECT_MEM
LDFLAGS = -g -mwindows -mno-cygwin
LIBS=-lversion


SRCS = $(PROJ).c about.c image.c object.c interp.c primitive.c fileio.c \
	 	init.c dump.c lex.c code.c symbols.c parse.c smallobjs.c

OBJS = $(PROJ).$(O) about.$(O) image.$(O) object.$(O) interp.$(O) \
	     primitive.$(O) fileio.$(O) init.$(O) dump.$(O) lex.$(O) \
	     code.$(O) symbols.$(O) parse.$(O) smallobjs.$(O) $(PROJ).res

SMALLSRC = basic.st stream.st collection.st magnitude.st misc.st compile.st \
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
code.$(O):	code.c object.h smallobjs.h interp.h lex.h symbols.h code.h fileio.h dump.h
dump.$(O):	dump.c object.h smallobjs.h fileio.h interp.h lex.h symbols.h code.h dump.h
fileio.$(O):	fileio.c object.h smallobjs.h fileio.h
image.$(O):	image.c object.h smallobjs.h image.h interp.h fileio.h
init.$(O):	init.c smalltalk.h object.h smallobjs.h interp.h primitive.h fileio.h lex.h dump.h symbols.h parse.h image.h
interp.$(O):	interp.c object.h smallobjs.h interp.h primitive.h dump.h fileio.h
lex.$(O):	lex.c object.h smallobjs.h lex.h fileio.h dump.h
object.$(O):	object.c object.h smallobjs.h dump.h fileio.h
parse.$(O):	parse.c object.h smallobjs.h fileio.h lex.h symbols.h code.h parse.h dump.h
primitive.$(O):	primitive.c image.h object.h smallobjs.h interp.h primitive.h fileio.h dump.h
smallobjs.$(O):	smallobjs.c object.h smallobjs.h interp.h fileio.h dump.h
smalltalk.$(O):	smalltalk.c smalltalk.h about.h object.h interp.h fileio.h dump.h
symbols.$(O):	symbols.c object.h smallobjs.h lex.h symbols.h
