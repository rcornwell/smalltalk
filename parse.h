/*
 * Smalltalk interpreter: Parser.
 *
 * $Id: parse.h,v 1.2 2000/02/01 18:10:00 rich Exp rich $
 *
 * $Log: parse.h,v $
 * Revision 1.2  2000/02/01 18:10:00  rich
 * Routines now propage error back to caller.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */  

void		    AddSelectorToClass(Objptr, char *, Objptr, Objptr, int);
int                 CompileForClass(char *, Objptr, Objptr, int);
Objptr              CompileForExecute(char *);
