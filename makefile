#
# Makefile for Smalltalk
#
.SUFFIXES:	.exe .rc .res .ico .sti .obj

O=obj
PROJ = smalltalk
SDK=//d/sdk
INCLUDE=$(SDK)/include
CC = gcc 
RC = windres -I rc -O coff -DWIN32 -DINLINE_OBJECT_MEM #--include-dir $(INCLUDE)
HC = $(SDK)/bin/hcw
CFLAGS = -g -Wall -O2 -DWIN32 -DINLINE_OBJECT_MEM #-I$(INCLUDE) 
LDFLAGS = -g -mwindows -mno-cygwin
LIBS=-lversion


SRCS = $(PROJ).c about.c image.c object.c interp.c primitive.c fileio.c \
	 	init.c dump.c lex.c code.c symbols.c parse.c smallobjs.c \
		largeint.c graphic.c xwin.c win32.c

OBJS = $(PROJ).$(O) about.$(O) image.$(O) object.$(O) interp.$(O) \
	     primitive.$(O) fileio.$(O) init.$(O) dump.$(O) lex.$(O) \
	     code.$(O) symbols.$(O) parse.$(O) smallobjs.$(O) $(PROJ).res \
	     largeint.$(O) graphic.$(O) xwin.$(O) win32.$(O)

BOOTSRC = basic.st stream.st collection.st magnitude.st misc.st compile.st \
	   behavior.st object.st boottail.st
SMALLSRC = stream.st collection.st magnitude.st misc.st compile.st \
	   behavior.st object.st

all:	$(PROJ).sti 

$(PROJ).sti: $(PROJ).exe $(PROJ).st boot.st
	./$(PROJ).exe boot.st

boot.st: $(BOOTSRC)
	cat $(BOOTSRC) > boot.st

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

about.$(O):	about.c smalltalk.h about.h
code.$(O):	code.c smalltalk.h object.h smallobjs.h interp.h lex.h \
		 symbols.h code.h system.h dump.h
dump.$(O):	dump.c smalltalk.h object.h smallobjs.h fileio.h interp.h \
		 lex.h symbols.h code.h dump.h
fileio.$(O):	fileio.c smalltalk.h object.h smallobjs.h fileio.h interp.h \
		fileio.h
image.$(O):	image.c smalltalk.h object.h smallobjs.h image.h interp.h \
		 fileio.h system.h graphic.h
init.$(O):	init.c smalltalk.h smalltalk.h object.h smallobjs.h interp.h \
		 primitive.h fileio.h lex.h dump.h symbols.h parse.h image.h \
		 system.h
interp.$(O):	interp.c smalltalk.h object.h smallobjs.h interp.h primitive.h \
		 dump.h system.h
lex.$(O):	lex.c smalltalk.h object.h smallobjs.h lex.h system.h dump.h
object.$(O):	object.c smalltalk.h object.h smallobjs.h dump.h system.h \
		 interp.h
parse.$(O):	parse.c smalltalk.h object.h smallobjs.h fileio.h lex.h \
		 symbols.h code.h parse.h dump.h system.h
primitive.$(O):	primitive.c smalltalk.h image.h object.h smallobjs.h interp.h \
		 primitive.h fileio.h dump.h largeint.h graphic.h system.h
smallobjs.$(O):	smallobjs.c smalltalk.h object.h smallobjs.h interp.h \
		 fileio.h dump.h
smalltalk.$(O):	smalltalk.c smalltalk.h about.h object.h interp.h fileio.h \
		 dump.h system.h
symbols.$(O):	symbols.c smalltalk.h object.h smallobjs.h lex.h symbols.h
largeint.$(O):	largeint.c object.h smallobjs.h largeint.h
graphic.$(O):	graphic.c object.h interp.h smallobjs.h graphic.h primitive.h \
		 system.h
xwin.$(O):	xwin.c	object.h interp.h smallobjs.h graphic.h
win32.$(O):	win32.c	object.h interp.h smallobjs.h graphic.h about.h

