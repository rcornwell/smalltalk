/*
 * Smalltalk interpreter: Parser.
 *
 * $Id: symbols.h,v 1.1 1999/09/02 15:57:59 rich Exp rich $
 *
 * $Log: symbols.h,v $
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */  

enum oper_type {
    Arg, Inst, Literal, Temp, Variable, Self, True, False, Nil, Stack, Super,
	 Label, Block, Operand
};


/*
 * This structure keeps track of literal strings used during compile.
 */ 
typedef struct _literalnode {
    struct _literalnode *next;
    int                 offset;
    Objptr		value;
    int                 usage;
} literalnode      , *Literalnode;

/*
 * This structure keeps the symbol table during compiles.
 */ 
#define SYMBOL_OLDBLOCK 01
typedef struct _symbolnode {
    struct _symbolnode *next;
    int                 offset;
    int                 flags;
    Literalnode		lit;
    enum oper_type      type;
    char               *name;
} symbolnode       , *Symbolnode;

/*
 * Structure to hold symbol information.
 */
typedef struct _namenode {
    Literalnode		lits;
    Literalnode		*litarray;
    Symbolnode		syms;
    int			instcount;
    int			tempcount;
    int			argcount;
    int			litcount;
    Objptr		classptr;
} namenode, *Namenode;


char               *strsave(char *str);
char               *strappend(char *old, char *str);
Namenode	    newname();
void		    freename(Namenode nstate);
void                for_class(Namenode nstate, Objptr aClass);
int                 add_builtin_symbol(Namenode nstate, char *name, enum oper_type type);
int                 add_symbol(Namenode nstate, char *name, enum oper_type type);
void                clean_symbol(Namenode nstate, int offset);
void		    sort_literals(Namenode nstate, int superflag, Objptr superClass);
Symbolnode	    find_symbol(Namenode nstate, char *name);
Symbolnode	    find_symbol_offset(Namenode nstate, int offset);
Literalnode	    add_literal(Namenode nstate, Objptr lit);
Literalnode	    find_literal(Namenode nstate, Objptr lit);
