#
# Makefile for Smalltalk
#
.SUFFIXES:	.exe .rc .res .ico .sti

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

OBJS = $(PROJ).o about.o image.o object.o interp.o primitive.o fileio.o \
 		init.o dump.o lex.o code.o symbols.o parse.o $(PROJ).res

SMALLSRC = basic.st stream.st magnitude.st collection.st behavior.st object.st

all:	$(PROJ).sti 

$(PROJ).sti: $(PROJ).exe $(PROJ).st
	$(PROJ).exe $(PROJ).st

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


about.o:	about.c about.h
$(PROJ).o:	$(PROJ).c $(PROJ).h  about.h
object.o:	object.c smallobjs.h object.h
interp.o:	interp.c smallobjs.h object.h interp.h primitive.h dump.h
primitive.o:	primitive.c smallobjs.h fileio.h object.h interp.h \
		primitive.h image.h
fileio.o:	fileio.c smallobjs.h object.h primitive.h fileio.h 
image.o:	image.c object.h fileio.h image.h
dump.o:		dump.c smallobjs.h lex.h object.h fileio.h dump.h
init.o:		init.c smallobjs.h object.h interp.h fileio.h primitive.h \
			 dump.h parse.h
lex.o:		lex.c smallobjs.h object.h primitive.h lex.h
code.o:		code.c smallobjs.h object.h interp.h primitive.h lex.h \
			 symbols.h code.h
symbols.o:	symbols.c smallobjs.h object.h interp.h primitive.h lex.h \
			 symbols.h
parse.o:	parse.c smallobjs.h dump.h object.h interp.h fileio.h \
			primitive.h lex.h symbols.h code.h parse.h

