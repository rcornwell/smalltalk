/*
 * Smalltalk interpreter: Parser.
 *
 * $Id: parse.h,v 1.1 1999/09/02 15:57:59 rich Exp rich $
 *
 * $Log: parse.h,v $
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */  

void                initcompile();
void		    AddSelectorToClass(Objptr, char *, Objptr, Objptr, int);
int                 CompileForClass(char *, Objptr, Objptr, int);
Objptr              CompileForExecute(char *);
void                messagePattern();
void                keyMessage();
void                doTemps();
int		    isVarSep();
void                doBody();
void                doExpression();
int                 doTerm();
int                 parseBinary();
int                 nameTerm(Symbolnode);
int                 doContinue(int);
int                 keyContinue(int);
int                 doBinaryContinue(int);
int                 doUnaryContinue(int);
int                 doBlock();
int                 optimBlock();
int                 doIfTrue();
int                 doIfFalse();
int                 doWhileTrue();
int                 doWhileFalse();
int                 doAnd();
int                 doOr();
