/*
 * Smalltalk interpreter: Parser.
 *
 * $Log: parse.c,v $
 * Revision 1.7  2001/08/18 16:17:02  rich
 * Removed section generating incorrect categories.
 *
 * Revision 1.6  2001/07/31 14:09:48  rich
 * Fixed to compile under new cygwin
 *
 * Revision 1.5  2001/01/17 01:02:12  rich
 * Changed location of flags in header.
 * Fixed compile bug in generation of send super messages.
 *
 * Revision 1.4  2000/08/27 01:17:50  rich
 * Don't pop tos before else part of conditional.
 *
 * Revision 1.3  2000/03/04 22:28:13  rich
 * Removed extra includes.
 * Converted local references to static.
 * Fixed bug in compiling of cascade messages.
 *
 * Revision 1.2  2000/02/01 18:09:59  rich
 * Added code to detect get and set of instance variable short methods.
 * Added errors for failing to add symbols.
 * Redid doBody to generate correct code.
 * Functions now propogate error status to caller.
 * Fixed jump targets.
 * Added support for method categories.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#ifndef lint
static char        *rcsid =
	"$Id: parse.c,v 1.7 2001/08/18 16:17:02 rich Exp rich $";

#endif

#include "smalltalk.h"
#include "object.h"
#include "smallobjs.h"
#include "lex.h"
#include "symbols.h"
#include "code.h"
#include "parse.h"
#include "fileio.h"
#include "system.h"
#include "dump.h"

Token		    tstate;
Namenode	    nstate;
Codestate	    cstate;
int                 primnum;
char               *sel = NULL;
int                 inBlock;
int                 optimBlk;

static void         initcompile();
static void         messagePattern();
static void         keyMessage();
static void         doTemps();
static int	    isVarSep();
static void         doBody();
static void         doExpression();
static int          doTerm();
static int          parsePrimitive();
static int          nameTerm(Symbolnode);
static void         doContinue(int);
static int          keyContinue(int);
static int          doBinaryContinue(int);
static int          doUnaryContinue(int);
static int          doBlock();
static int          optimBlock();
static int          doIfTrue();
static int          doIfFalse();
static int          doWhileTrue();
static int          doWhileFalse();
static int          doAnd();
static int          doOr();

/*
 * Initialize the compiler for a new compile.
 */
static void
initcompile()
{
    nstate = newname();
    cstate = newCode();

    if (sel != NULL)
	free(sel);
    primnum = 0;
    sel = NULL;
}

/*
 * Add a selector to a class and catagory.
 */
void
AddSelectorToClass(Objptr aClass, char *selector, Objptr aCatagory, 
				Objptr aMethod, int pos)
{
    Objptr	aSelector;
    Objptr	methinfo;
    Objptr	dict;

    rootObjects[TEMP2] = aSelector = internString(selector);

    if ((dict = get_pointer(aClass, METHOD_DICT)) == NilPtr) {
	dict = new_IDictionary();
	Set_object(aClass, METHOD_DICT, dict);
    }

    /* Add it to class dictionary */
    AddSelectorToIDictionary(dict, aSelector, aMethod);

    /* Add Category */
    rootObjects[TEMP2] = methinfo = create_new_object(MethodInfoClass, 0);
    Set_object(aMethod, METH_DESCRIPTION, methinfo);
    Set_integer(methinfo, METHINFO_SOURCE, 1);
    Set_integer(methinfo, METHINFO_POS, pos);
    Set_object(methinfo, METHINFO_CAT, aCatagory);
    rootObjects[TEMP2] = NilPtr;
}
 
/*
 * Compile a string for a class.
 */
int
CompileForClass(char *text, Objptr class, Objptr aCatagory, int pos)
{
    int			litsize;
    int			header, eheader;
    int			size, numargs, i;
    Objptr		method;
    int			savereclaim = noreclaim;

    noreclaim = TRUE;
    initcompile();
    for_class(nstate, class);
    tstate = new_tokscanner(text);
    (void) get_token(tstate);
    messagePattern();
    doTemps();
    if (parsePrimitive() == -1) {
        done_scan(tstate);
	return FALSE;
    }
    doBody();
    genCode(cstate, Return, Self, -1);
    done_scan(tstate);
    i =  optimize(cstate);
    sort_literals(nstate, i, get_pointer(class, SUPERCLASS));
    /* Check if we can shortcut this method */
    if (nstate->tempcount == 0 && nstate->litcount == 0) {
	/* No point to check if it can't possibly be shortcircuit */
	if ((i = isGetInst(cstate)) >= 0) {
            header = (METH_NUMTEMPS & (i << 9)) + (METH_RETURN);
	    method = create_new_object(CompiledMethodClass, 0);
 	    rootObjects[TEMP1] = method;
	    /* Build header */
	    Set_object(method, METH_HEADER, as_oop(header));
    	    freeCode(cstate);
    	    freename(nstate);
    	    AddSelectorToClass(class, sel, aCatagory, method, pos);
    	    rootObjects[TEMP1] = NilPtr;
    	    noreclaim = savereclaim;
	    return TRUE;
  	} else if ((i = isSetInst(cstate)) >= 0) {
            header = (METH_NUMTEMPS & (i << 9)) + (METH_SETINST);
	    method = create_new_object(CompiledMethodClass, 0);
 	    rootObjects[TEMP1] = method;
	    /* Build header */
	    Set_object(method, METH_HEADER, as_oop(header));
    	    freeCode(cstate);
    	    freename(nstate);
    	    AddSelectorToClass(class, sel, aCatagory, method, pos);
    	    rootObjects[TEMP1] = NilPtr;
    	    noreclaim = savereclaim;
	    return TRUE;
	}
    }
    genblock(cstate);
    litsize = nstate->litcount;
    numargs = nstate->argcount;
    if (primnum > 0 || numargs > 12) {
	litsize++;
	eheader = (EMETH_PRIM & (primnum << 1)) +
			(EMETH_ARGS  & (numargs << 17));
        header = (METH_NUMLITS & (litsize << 1)) +
			(METH_NUMTEMPS & (nstate->tempcount << 9)) +
			(METH_STACKSIZE & (cstate->maxstack << 17)) +
			METH_EXTEND;
    } else {
        header = (METH_NUMLITS & (litsize << 1)) +
			(METH_NUMTEMPS & (nstate->tempcount << 9)) +
			(METH_STACKSIZE & (cstate->maxstack << 17)) +
			(METH_FLAG & (numargs << 27));
	eheader = 0;
    }
    size = ((cstate->code->len) + (sizeof(Objptr) - 1)) / sizeof(Objptr); 
    method = create_new_object(CompiledMethodClass, size + litsize);
    rootObjects[TEMP1] = method;
    /* Build header */
    Set_object(method, METH_HEADER, as_oop(header));
    for (i = 0; i < nstate->litcount; i++)
	Set_object(method, METH_LITSTART + i, nstate->litarray[i]->value);
    if (eheader != 0)
        Set_object(method, METH_LITSTART + i, as_oop(eheader));
    /* Copy over code */
    for (i = 0; i < cstate->code->len; i++) 
	set_byte(method, i + (METH_LITSTART + litsize) * sizeof(Objptr),
		cstate->code->u.codeblock[i]);
    freeCode(cstate);
    freename(nstate);
    AddSelectorToClass(class, sel, aCatagory, method, pos);
    show_method(method);
    rootObjects[TEMP1] = NilPtr;
    noreclaim = savereclaim;
    return TRUE;
}

/*
 * Compile a string execute.
 */
Objptr
CompileForExecute(char *text)
{
    int			litsize;
    int			header, eheader;
    int			size, i;
    Objptr		method;
    int			savereclaim = noreclaim;

    noreclaim = TRUE;
    initcompile();
    for_class(nstate, ObjectClass);
    tstate = new_tokscanner(text);
    (void) get_token(tstate);
    doTemps();
    doBody();
    done_scan(tstate);
    genCode(cstate, Break, Nil, 0);
    (void)optimize(cstate);
    sort_literals(nstate, 0, NilPtr);
    genblock(cstate);
    litsize = nstate->litcount;
    if (primnum > 0) {
	litsize++;
	eheader = (EMETH_PRIM & (primnum << 1)) +
			(EMETH_ARGS  & (0 << 17));
        header = (METH_NUMLITS & (litsize << 1)) +
			(METH_NUMTEMPS & (nstate->tempcount << 9)) +
			(METH_STACKSIZE & (cstate->maxstack << 17)) +
			METH_EXTEND;
    } else {
        header = (METH_NUMLITS & (litsize << 1)) +
			(METH_NUMTEMPS & (nstate->tempcount << 9)) +
			(METH_STACKSIZE & (cstate->maxstack << 17)) +
			(METH_FLAG & (0 << 27));
	eheader = 0;
    }
    size = ((cstate->code->len) + (sizeof(Objptr) - 1)) / sizeof(Objptr);
    method = create_new_object(CompiledMethodClass, size + litsize);
    rootObjects[TEMP1] = method;
    /* Build header */
    Set_object(method, METH_HEADER, as_oop(header));
    for (i = 0; i < nstate->litcount; i++)
	Set_object(method, METH_LITSTART + i, nstate->litarray[i]->value);
    if (eheader != 0)
        Set_object(method, METH_LITSTART + i, as_oop(eheader));
    /* Copy over code */
    for (i = 0; i < cstate->code->len; i++) 
	set_byte(method, i + (METH_LITSTART + litsize) * sizeof(Objptr),
		cstate->code->u.codeblock[i]);
    freeCode(cstate);
    freename(nstate);
    noreclaim = savereclaim;
    show_exec(method);
    return method;
}

/*
 * Parse the message pattern.
 */
static void
messagePattern()
{
    int                 tok;

    switch (tok = get_cur_token(tstate)) {
    case KeyName:
	sel = strsave(get_token_string(tstate));
	get_token(tstate);
	break;
    case KeyKeyword:
	keyMessage();
	break;
    case KeySpecial:
	sel = strsave(get_token_spec(tstate));
	if (get_token(tstate) == KeyName) {
	    if (!add_symbol(nstate, get_token_string(tstate), Arg)) {
	        parseError(tstate, "Failed to add symbol ",
				 get_token_string(tstate));
		break;
	    }
	    get_token(tstate);
	} else {
	   parseError(tstate, "Binary not followed by name", NULL);
	}
	break;
    default:
	parseError(tstate, "Illegal message selector", NULL);
    }
}

/*
 * Parse a keywork selector pattern.
 */
static void
keyMessage()
{
    int                 tok;

    sel = strsave(get_token_string(tstate));
    while (TRUE) {
	tok = get_token(tstate);
	if (tok != KeyName) {
	    parseError(tstate, "Keyword message pattern not followed by a name", NULL);
	    return;
	}
	if (!add_symbol(nstate, get_token_string(tstate), Arg)) {
	    parseError(tstate, "Failed to add symbol ",
				 get_token_string(tstate));
	    return;
	}
	tok = get_token(tstate);
	if (tok != KeyKeyword)
	    return;
	sel = strappend(sel, get_token_string(tstate));
    }
}

/*
 * Parse temporaries.
 */
static void
doTemps()
{
    int                 tok;

    if (isVarSep()) {
	while ((tok = get_token(tstate)) == KeyName) {
	    if (!add_symbol(nstate, get_token_string(tstate), Temp)) {
	         parseError(tstate, "Failed to add symbol ",
				 get_token_string(tstate));
	         return;
	    }
	}
	if (isVarSep())
	    tok = get_token(tstate);
	else {
	    parseError(tstate, "Needs to be name or |", NULL);
	    return;
	}
    }
}

/*
 * Determine if next token is a variable seperator.
 */
static int
isVarSep()
{
    char	*str;

    if (get_cur_token(tstate) == KeySpecial) {
	str = get_token_spec(tstate);
	if (*str == '|' && str[1] == '\0')
		return TRUE;
    }
    return FALSE;
}


/*
 * Parse body of definition.
 */
static void
doBody()
{
    int                 tok;

    if (get_cur_token(tstate) == KeyEOS)
	return;

    if (get_cur_token(tstate) == KeyRBrack) {
        genPushNil(cstate);
	if (!inBlock) 
            parseError(tstate, "Mismatched ]", NULL);
        return;
    }
    while (TRUE) {
        if (get_cur_token(tstate) == KeyReturn) {
	    get_token(tstate);
	    doExpression();
            genReturnTOS(cstate);
        }  else 
	    doExpression();

	if ((tok = get_cur_token(tstate)) == KeyEOS) {
  	    genPopTOS(cstate);
	    return;
	} else if (tok == KeyPeriod) {
       	    genPopTOS(cstate);		/* Remove value of last stat. */
	    tok = get_token(tstate);
	    if (tok == KeyRBrack) {		/* End of block */
		genPushNil(cstate);		/* For optimizer */
		return;
	    } else if (tok == KeyEOS) {
		return;
	    }
	} else if (tok == KeyRBrack) {
	    if (inBlock && !optimBlk)
	       genDupTOS(cstate); 
	    if (!inBlock)
	    	parseError(tstate, "Extra ]", NULL);
	    return;
	} else {
	    parseError(tstate, "Invalid statement ending", NULL);
	    return;
	}
    }
}


/*
 * Parse Expression.
 */
static void
doExpression()
{
    int                 superFlag = FALSE;
    int                 tok;
    Symbolnode          asgname;

    if ((tok = get_cur_token(tstate)) == KeyName) {
        if ((asgname = find_symbol(nstate, get_token_string(tstate))) == NULL) {
            parseError(tstate, "Invalid name ", get_token_string(tstate));
	    return;
        }
        if ((tok = get_token(tstate)) == KeyAssign) {
	    if (asgname->type != Inst && asgname->type != Temp &&
		     asgname->type != Variable) {
            	parseError(tstate, "Invalid asignment name ", asgname->name);
	        return;
	    }
	    (void)get_token(tstate);
	    doExpression();
	    genDupTOS(cstate);
	    genStore(cstate, asgname);
 	    return;
        } else 
	    superFlag = nameTerm(asgname);
    } else 
        superFlag = doTerm();
    if (superFlag != -1)
        doContinue(superFlag);
    return;
}

/*
 * Parse a term.
 */
static int
doTerm()
{
    int                 tok = get_cur_token(tstate);
    int                 superFlag = FALSE;

    if (tok == KeyLiteral) {
	genPushLit(cstate, add_literal(nstate,  get_token_object(tstate)));
    } else if (tok == KeyName) {
	superFlag = nameTerm(find_symbol(nstate, get_token_string(tstate)));
    } else if (tok == KeyLBrack) {
	if (!doBlock())
	    return -1;
    } else if (tok == KeyRParen) {
	(void)get_token(tstate);
	doExpression();
	if (get_cur_token(tstate) != KeyLParen) {
	    parseError(tstate, "Missing )", NULL);
	    return -1;
	}
    } else if (tok == KeyLParen || tok == KeyRBrack || tok == KeyEOS
		|| tok == KeyPeriod) {
	return superFlag;
    } else {
        parseError(tstate, "Invalid terminal", NULL);
	return -1;
    }
    (void)get_token(tstate);
    return superFlag;
}

/*
 * Parse a primitive description.
 */
static int
parsePrimitive()
{
    int                 tok;

    if (get_cur_token(tstate) == KeySpecial && 
	strcmp(get_token_spec(tstate), "<") == 0) {
       /* Handle primitive */
	if ((tok = get_token(tstate)) == KeyName &&
	    strcmp(get_token_string(tstate), "primitive") == 0 &&
	    (tok = get_token(tstate)) == KeyLiteral &&
	    is_integer(get_token_object(tstate))) {
	    primnum = as_integer(get_token_object(tstate));
	    if ((tok = get_token(tstate)) == KeySpecial &&
		strcmp(get_token_spec(tstate), ">") == 0)
		(void)get_token(tstate);
		return TRUE;
	}
	parseError(tstate, "Invalid primitive", NULL);
	return -1;
    }
    return FALSE;
}

/*
 * Parse a name terminal.
 */
static int
nameTerm(Symbolnode sym)
{
    if (sym == NULL) {
	parseError(tstate, "Invalid name terminal", NULL);
	return FALSE;
    }
    genPush(cstate, sym);
    return ((sym->type == Super) ? TRUE: FALSE);
}

/*
 * Handle rest of expression.
 * message expression or
 * message expression ; message expression
 */
static void
doContinue(int superFlag)
{
    superFlag = keyContinue(superFlag);
    while (superFlag != -1 && get_cur_token(tstate) == KeyCascade) {
	genDupTOS(cstate);
	get_token(tstate); 
	superFlag = keyContinue(superFlag);
	genPopTOS(cstate);
    }
    return;
}

/*
 * Handle keyword continuation.
 */
static int
keyContinue(int superFlag)
{
    int                 argc = 0;
    char               *key;
    char               *pat;
    Literalnode         lit;

    superFlag = doBinaryContinue(superFlag);
    if (get_cur_token(tstate) != KeyKeyword)
	return 0;

   /* Check if it is a built in keyword message */
    key = get_token_string(tstate);
    if (strcmp(key, "ifTrue:") == 0)
	return doIfTrue(tstate);
    if (strcmp(key, "ifFalse:") == 0)
	return doIfFalse(tstate);
    if (strcmp(key, "whileTrue:") == 0)
	return doWhileTrue(tstate);
    if (strcmp(key, "whileFalse:") == 0)
	return doWhileFalse(tstate);
    if (strcmp(key, "and:") == 0)
	return doAnd(tstate);
    if (strcmp(key, "or:") == 0)
	return doOr(tstate);

    pat = strsave("");

    while (get_cur_token(tstate) == KeyKeyword) {
	int                 sTerm;

	pat = strappend(pat, get_token_string(tstate));
	argc++;
	get_token(tstate);
	sTerm = doTerm();
	(void)doBinaryContinue(sTerm);
    }
    lit = add_literal(nstate, internString(pat));
    genSend(cstate, lit, argc, superFlag);
    return 0;
}

/*
 * Handle binary continuation
 */
static int
doBinaryContinue(int superFlag)
{
    int                 sTerm;
    Literalnode         lit;

    superFlag = doUnaryContinue(superFlag);
    while (get_cur_token(tstate) == KeySpecial) {
	lit = add_literal(nstate, internString(get_token_spec(tstate)));
	(void) get_token(tstate);
	sTerm = doTerm();
	sTerm = doUnaryContinue(sTerm);
        genSend(cstate, lit, 1, superFlag);
    }
    return superFlag;
}

/*
 * Handle unary continuations.
 */
static int
doUnaryContinue(int superFlag)
{
    Literalnode         lit;

    while (get_cur_token(tstate) == KeyName) {
	lit = add_literal(nstate, internString(get_token_string(tstate)));
	genSend(cstate, lit, 0, superFlag);
	superFlag = FALSE;
	get_token(tstate);
    }
    return superFlag;
}

/*
 * Parse a block of code.
 */
static int
doBlock()
{
    int                 savetemps = nstate->tempcount;
    int                 tok;
    int                 i, argc = 0;
    int                 saveInblock = inBlock;
    int                 saveOptimBlk = optimBlk;
    Codenode            block;

    while ((tok = get_token(tstate)) == KeyVariable) {
	if (!add_symbol(nstate, get_token_string(tstate), Temp)) {
	   parseError(tstate, "Failed to add symbol ", get_token_string(tstate));
	   return FALSE;
	}
	argc++;
    }

    if (isVarSep()) {
	if (argc == 0) {
	    parseError(tstate, "No arguments defined.", NULL);
	    return FALSE;
	}
	tok = get_token(tstate);
    } else {
	if (argc > 0) {
	    parseError(tstate, "Need var seporator", NULL);
	    return FALSE;
	}
    }

   /* Jump forward to end of block. */
    block = genBlockCopy(cstate, argc);

    inBlock = TRUE;
    optimBlk = FALSE;

   /* Store arguments from stack into temps. */
    for (i = argc; i > 0; i--) {
	Symbolnode sym = find_symbol_offset(nstate, i + savetemps - 1);
	if (sym == NULL) {
	    parseError(tstate, "Could not find block temp", NULL);
	    return -1;
	}
	genStore(cstate, sym);
    }

   /* Do body of block */
    doBody();

    if (get_cur_token(tstate) != KeyRBrack) {
	parseError(tstate, "Block must end with ]", NULL);
	return -1;
    }

    genCode(cstate, Return, Block, -1);

    setJumpTarget(cstate, block, 0);
    inBlock = saveInblock;
    optimBlk = saveOptimBlk;
    clean_symbol(nstate, savetemps);
    return TRUE;
}

/*
 * Compile a optimized block.
 */
static int
optimBlock()
{
    int                 saveInblock = inBlock;
    int                 saveOptimBlk = optimBlk;
    int                 tok;

   /* Make sure we start with a block */
    if ((tok = get_token(tstate)) != KeyLBrack) {
        parseError(tstate, "Error missing [", NULL);
	return -1;
    }
    get_token(tstate);
    inBlock = TRUE;
    optimBlk = TRUE;

   /* Do body of block */
    doBody();

    if (get_cur_token(tstate) != KeyRBrack) {
	parseError(tstate, "Block must end with ]", NULL);
	return -1;
    }

    (void)get_token(tstate);

    inBlock = saveInblock;
    optimBlk = saveOptimBlk;
    return TRUE;

}

/*
 * Compile ifTrue: as a built in.
 */
static int
doIfTrue()
{
    Codenode            block;
    int                 flag;
    int			next = 1;

    block = genJumpFForw(cstate);	/* Jump forward to end of block. */
    flag = optimBlock();

    if (get_cur_token(tstate) == KeyKeyword &&
	strcmp(get_token_string(tstate), "ifFalse:") == 0) {
    /*    genPopTOS(cstate); */
	setJumpTarget(cstate, block, 1);
	block = genJumpForw(cstate);	/* Skip around else block */
	flag = optimBlock();		/* Do else part */
	next = 0;
    } 
    setJumpTarget(cstate, block, next);
    return flag;
}

/*
 * Compile ifFalse: as a built in.
 */
static int
doIfFalse()
{
    Codenode            block, eblock = NULL;
    int                 flag;
    int			next = 1;

    block = genJumpTForw(cstate);	/* Jump forward to end of block. */
    flag = optimBlock();

    if (get_cur_token(tstate) == KeyKeyword &&
	strcmp(get_token_string(tstate), "ifTrue:") == 0) {
     /*   genPopTOS(cstate); */
	setJumpTarget(cstate, block, 1);
	eblock = genJumpForw(cstate);	/* Skip around else block */
	block = eblock;
	flag = optimBlock();	/* Do else part */
	next = 0;
    } 
    setJumpTarget(cstate, block, next);
    return flag;
}

/*
 * Compile whileTrue: as built in.
 */
static int
doWhileTrue()
{
    Codenode            loop, block;
    int                 flag;

    loop = getCodeLabel(cstate);
    genDupTOS(cstate);
    genSend(cstate, add_literal(nstate, internString("value")), 0, FALSE);
    block = genJumpFForw(cstate);	/* Jump forward to end of block. */
    flag = optimBlock();		/* Block body */
    genPopTOS(cstate);			/* Remove result of block */
    setJumpTarget(cstate, block, 1);
    genJump(cstate, loop);		/* Jump to start of block */
    return flag;
}

/*
 * Compile whileFalse: as built in.
 */
static int
doWhileFalse()
{
    Codenode            loop, block;
    int                 flag;

    loop = getCodeLabel(cstate);
    genDupTOS(cstate);
    genSend(cstate, add_literal(nstate, internString("value")), 0, FALSE);
    block = genJumpTForw(cstate);	/* Jump forward to end of block. */
    flag = optimBlock();		/* Block body */
    genPopTOS(cstate);			/* Remove result of block */
    setJumpTarget(cstate, block, 1);
    genJump(cstate, loop);		/* Jump to start of block */
    return flag;
}

/*
 * Compile and: as a built in.
 *
 *  expression
 *  DupTOS
 *  JF          L1
 *  PopTOS
 *  block
 * L1:
 *  
 */
static int
doAnd()
{
    Codenode            block;
    int                 flag;

    genDupTOS(cstate);
    block = genJumpFForw(cstate);	/* Jump forward to end of block. */
    genPopTOS(cstate); 
    flag = optimBlock();
    setJumpTarget(cstate, block, 0);

    /* Keep grabing if we got another builtin */
    if (get_cur_token(tstate) == KeyKeyword) {
	if (strcmp(get_token_string(tstate), "ifFalse:") == 0) 
		doIfFalse();
	else if (strcmp(get_token_string(tstate), "ifTrue:") == 0) 
		doIfTrue();
	else if (strcmp(get_token_string(tstate), "or:") == 0) 
		doOr();
	else if (strcmp(get_token_string(tstate), "and:") == 0) 
		doOr();
    }
    return flag;
}

/*
 * Compile or: as a built in.
 */
static int
doOr()
{
    Codenode            block;
    int                 flag;

    genDupTOS(cstate);
    block = genJumpTForw(cstate);	/* Jump forward to end of block. */
    genPopTOS(cstate); 
    flag = optimBlock();
    setJumpTarget(cstate, block, 0);

    /* Keep grabing if we got another builtin */
    if (get_cur_token(tstate) == KeyKeyword) {
	if (strcmp(get_token_string(tstate), "ifFalse:") == 0) 
		doIfFalse();
	else if (strcmp(get_token_string(tstate), "ifTrue:") == 0) 
		doIfTrue();
	else if (strcmp(get_token_string(tstate), "or:") == 0) 
		doOr();
	else if (strcmp(get_token_string(tstate), "and:") == 0) 
		doAnd();
    }
    return flag;
}

