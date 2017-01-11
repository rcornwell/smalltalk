/*
 * Smalltalk interpreter: Parser.
 *
 * Copyright 1999-2017 Richard P. Cornwell.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the the Artistic License (2.0). You may obtain a copy
 * of the full license at:
 *
 * http://www.perlfoundation.org/artistic_license_2_0
 *
 * Any use, modification, and distribution of the Standard or Modified
 * Versions is governed by this Artistic License. By using, modifying or
 * distributing the Package, you accept this license. Do not use, modify, or
 * distribute the Package, if you do not accept this license.
 *
 * If your Modified Version has been derived from a Modified Version made by
 * someone other than you, you are nevertheless required to ensure that your
 * Modified Version complies with the requirements of this license.
 *
 * This license does not grant you the right to use any trademark, service
 * mark, tradename, or logo of the Copyright Holder.
 *
 * Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
 * AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
 * PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
 * YOUR LOCAL LAW.  UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
 * CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
 * CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Id: symbols.h,v 1.3 2001/08/01 16:44:08 rich Exp $
 *
 * $Log: symbols.h,v $
 * Revision 1.3  2001/08/01 16:44:08  rich
 * Added thisContext variable.
 *
 * Revision 1.2  2000/02/01 18:10:05  rich
 * Added Operand Class for sendSpec
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */  

enum oper_type {
    Arg, Inst, Literal, Temp, Variable, Self, True, False, Nil, Stack, Super,
	 Label, Block, Operand, Context
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
