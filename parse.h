/*
 * Smalltalk interpreter: Parser.
 *
 * $Id: $
 *
 * $Log: $
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
void                doBinaryContinue(int);
void                doUnaryContinue(int);
int                 doBlock();
int                 optimBlock();
int                 doIfTrue();
int                 doIfFalse();
int                 doWhileTrue();
int                 doWhileFalse();
int                 doAnd();
int                 doOr();
