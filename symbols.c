/*
 * Smalltalk interpreter: Parser.
 *
 * $Log: symbols.c,v $
 * Revision 1.5  2001/07/31 14:09:49  rich
 * Fixed to compile under new cygwin.
 *
 * Revision 1.4  2001/01/06 21:28:12  rich
 * Fixed error in find selector
 *
 * Revision 1.3  2000/02/02 16:12:24  rich
 * Don't need to include primitive or interper anymore.
 *
 * Revision 1.2  2000/02/01 18:10:05  rich
 * Class instance variables now stored in a Array.
 * Fixed some errors in Literal table generation.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#ifndef lint
static char        *rcsid =
	"$Id: symbols.c,v 1.5 2001/07/31 14:09:49 rich Exp rich $";

#endif

#include "smalltalk.h"
#include "object.h"
#include "smallobjs.h"
#include "lex.h"
#include "symbols.h"


/*
 * Save string.
 */
char               *
strsave(char *str)
{
    int                 len = strlen(str);
    char               *newstr;

    if ((newstr = (char *) malloc(len + 1)) != NULL)
	strcpy(newstr, str);
    return newstr;
}

/*
 * Append strings together.
 */
char               *
strappend(char *old, char *str)
{
    int                 len = strlen(old) + strlen(str);
    char               *newstr;

    if ((newstr = (char *) realloc(old, len + 1)) != NULL)
	strcat(newstr, str);
    else
	newstr = old;
    return newstr;
}

/*
 * Allocate a new name block.
 */
Namenode
newname()
{
    Namenode		nname;

    if ((nname = (Namenode)malloc(sizeof(namenode))) == NULL)
	return NULL;

    nname->lits = NULL;
    nname->litarray = NULL;
    nname->syms = NULL;
    nname->instcount = 0;
    nname->tempcount = 0;
    nname->argcount = 0;
    nname->classptr = NilPtr;

    /* Add in defined objects */
    add_builtin_symbol(nname, "self", Self);
    add_builtin_symbol(nname, "super", Super);
    add_builtin_symbol(nname, "true", True);
    add_builtin_symbol(nname, "false", False);
    add_builtin_symbol(nname, "nil", Nil);
    add_builtin_symbol(nname, "thisContext", Context);
    return nname;
}

/*
 * Free a name block.
 */
void
freename(Namenode nstate)
{

    Literalnode         lp, lpp;
    Symbolnode          sp, spp;

   /* Free literals */
    if (nstate->litarray != NULL)
	free(nstate->litarray);

    for (lp = nstate->lits; lp != NULL; lp = lpp) {
	lpp = lp->next;
	free(lp);
    }

   /* Free symbol table */
    for( sp = nstate->syms; sp != NULL; sp = spp) {
	spp = sp->next;
	free(sp->name);
	free(sp);
    }

    free(nstate);
}

/*
 * Set compiler up for class.
 */
void
for_class(Namenode nstate, Objptr aClass)
{
    Objptr		op;
    Objptr              var;
    char               *str;
    int			base, length, i;

    if (aClass == NilPtr)
	return;
   /* Add superclass names first */
    op = get_pointer(aClass, SUPERCLASS);
    if (op != NilPtr)
	for_class(nstate, op);

   /* After we ran superclass, see if any more vars. */
    nstate->classptr = aClass;
    op = get_pointer(aClass, CLASS_VARS);
    if (op == NilPtr)
	return;
    base = fixed_size(op);
    length = length_of(op);
    for (i = 0; i < length; i++) {
	var = get_pointer(op, i + (base / sizeof(Objptr)));
	if (var != NilPtr) {
	    str = Cstring(var);
	    add_symbol(nstate, str, Inst);
	    free(str);
	}
    }
}

/*
 * Add a builtin symbol table node.
 */
int
add_builtin_symbol(Namenode nstate, char *name, enum oper_type type)
{
    Symbolnode          newsym;

    if ((newsym = (Symbolnode) malloc(sizeof(symbolnode))) != NULL) {
	newsym->name = strsave(name);
	newsym->type = type;
	newsym->lit = NULL;
	newsym->offset = 0;
	newsym->flags = 0;
	newsym->next = nstate->syms;
	nstate->syms = newsym;
	return TRUE;
    }
    return FALSE;
}

/*
 * Add a new symbol table node.
 */
int
add_symbol(Namenode nstate, char *name, enum oper_type type)
{
    Symbolnode          newsym;

    if (find_symbol(nstate, name) == NULL &&
	(newsym = (Symbolnode) malloc(sizeof(symbolnode))) != NULL) {
	newsym->name = strsave(name);
	newsym->type = type;
	newsym->lit = NULL;
	switch(type) {
	case Arg:
		newsym->offset = nstate->argcount++;
		break;
	case Inst:
		newsym->offset = nstate->instcount++;
		break;
	case Temp:
		newsym->offset = nstate->tempcount++;
		break;
	default:
		newsym->offset = 0;
		break;
	}
	newsym->flags = 0;
	newsym->next = nstate->syms;
	nstate->syms = newsym;
	return TRUE;
    }
    return FALSE;
}

/*
 * Clean out symbols defined after offset.
 */
void
clean_symbol(Namenode nstate, int offset)
{
    Symbolnode          sp;

    for (sp = nstate->syms; sp != NULL; sp = sp->next) {
	if (sp->type == Temp &&
	    (sp->flags & SYMBOL_OLDBLOCK) == 0 &&
	    sp->offset >= offset) {
	    sp->flags |= SYMBOL_OLDBLOCK;
	}
    }
}

/*
 * Lookup symbol in symbol table.
 */
Symbolnode
find_symbol(Namenode nstate, char *name)
{
    Symbolnode          sp;
    Symbolnode          newsym;
    Objptr		sym;
    Objptr		var = NilPtr;

    for (sp = nstate->syms; sp != NULL; sp = sp->next) {
	if ((sp->flags & SYMBOL_OLDBLOCK) == 0 &&
	    strcmp(sp->name, name) == 0)
	    return sp;
    }

    sym = internString(name);

    /* Look for name in class dictionary */
    if (nstate->classptr != NilPtr) {
	Objptr		class = nstate->classptr;
	for(class = nstate->classptr;
	   var == NilPtr && class != NilPtr; 
	   class = get_pointer(class, SUPERCLASS)) {
	     var = get_pointer(class, CLASS_DICT);
	     if (var != NilPtr)
	         var = FindSelectorInDictionary(var, sym);
	}
    }

    /* If not found try Smalltalk dictionary */
    if (var == NilPtr) 
	var = FindSelectorInDictionary(SmalltalkPointer, sym);

    /* If we found something, add it in */
    if (var != NilPtr &&
	(newsym = (Symbolnode) malloc(sizeof(symbolnode))) != NULL) {
	newsym->name = strsave(name);
	newsym->type = Variable;
	newsym->offset = 0;
	newsym->lit = add_literal(nstate, var);
	newsym->flags = 0;
	newsym->next = nstate->syms;
	nstate->syms = newsym;
	return newsym;
    }
    return NULL;
}

/*
 * Lookup symbol in symbol table.
 */
Symbolnode
find_symbol_offset(Namenode nstate, int offset)
{
    Symbolnode          sp;

    for (sp = nstate->syms; sp != NULL; sp = sp->next) {
	if (sp->type == Temp && sp->offset == offset)
	    return sp;
    }
    return NULL;
}

/*
 * Add a new literal table node.
 */
Literalnode
add_literal(Namenode nstate, Objptr lit)
{
    Literalnode         newlit;

    if ((newlit = find_literal(nstate, lit)) != NULL) {
	newlit->usage++;
	return newlit;
    }
    if ((newlit = (Literalnode) malloc(sizeof(literalnode))) != NULL) {
	newlit->value = lit;
	newlit->offset = 0;
	newlit->usage = 1;
	newlit->next = nstate->lits;
	nstate->lits = newlit;
	return newlit;
    }
    return NULL;
}

/*
 * Sort literals by usage count.
 */
void
sort_literals(Namenode nstate, int superFlag, Objptr superClass)
{
    Literalnode         lp;
    int                 foundSuper = 0;
    int                 i, j;

   /* Count number of used literals */
    nstate->litcount = 0;
    for (lp = nstate->lits; lp != NULL; lp = lp->next) {
	if (lp->usage > 0)
	    nstate->litcount++;
	if (is_object(lp->value) && lp->value == superClass)
	    foundSuper++;
    }

   /* Add in superclass if we need it */
    if (superFlag && foundSuper == 0) {
	lp = add_literal(nstate, superClass);
	lp->offset = -1;
	nstate->litcount++;
    }
   /* Build an array to sort them */
    if ((nstate->litarray =
      (Literalnode *) malloc(sizeof(Literalnode) * nstate->litcount)) == NULL) {
	for (i = 0, lp = nstate->lits; lp != NULL; lp = lp->next) {
	    if (lp->offset == -1)
		lp->offset = nstate->litcount - 1;
	    else
		lp->offset = i++;
	}
	return;
    }
   /* Clear array */
    for (i = 0; i < nstate->litcount; nstate->litarray[i++] = NULL) ;

   /* Now load the array in usage order */
    for (lp = nstate->lits; lp != NULL; lp = lp->next) {
	if (lp->usage <= 0)
	    continue;
       /* Find slot based on usage */
	if (lp->offset == -1) {
	    nstate->litarray[nstate->litcount - 1] = lp;
	    continue;
	}
       /* Find slot to put it in */
	for (i = 0; i < nstate->litcount; i++) {
	    if (nstate->litarray[i] == NULL) {
	       /* Insert element */
		nstate->litarray[i] = lp;
		break;
	    }
	    if (lp->usage > nstate->litarray[i]->usage) {
	       /* Find next empty slot */
		for (j = i + 1; j <= nstate->litcount; j++) {
		    if (nstate->litarray[j] == NULL) {
	       		/* Slide the elements down */
			for (; j > i; j--)
		             nstate->litarray[j] = nstate->litarray[j - 1];
			break;
		    }
		}

	       /* Insert element */
		nstate->litarray[i] = lp;
		break;
	    }
	}
    }

   /* Now set offsets based on index into litarray */
    for (i = 0; i < nstate->litcount; i++)
	if (nstate->litarray[i] != NULL)
	    nstate->litarray[i]->offset = i;
}

/*
 * Lookup literal in literal table.
 */
Literalnode
find_literal(Namenode nstate, Objptr lit)
{
    Literalnode         lp;

    for (lp = nstate->lits; lp != NULL; lp = lp->next) {
	if (lit == lp->value)
	    return lp;
    }
    return NULL;
}

