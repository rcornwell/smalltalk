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
 * $Id: code.h,v 1.2 2000/02/01 18:09:47 rich Exp $
 *
 * $Log: code.h,v $
 * Revision 1.2  2000/02/01 18:09:47  rich
 * Fixed stack adjust of return.
 * Changed way jump targets set.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */  

enum code_type {
    Push, Store, Return, Send, Jump, JTrue, JFalse, BlockCopy, Duplicate,
    PopStack, SuperSend, CodeBlock, SendSpec, Break, Nop
};


#define	CODE_LABEL	01	/* Flag to say code element is a label */
/*
 * This structure holds the code chunks as they are built by the compiler.
 */ 
typedef struct _codenode {
    struct _codenode   *next;
    enum code_type      type;
    enum oper_type      oper;
    int                 len;
    int                 offset;
    int                 flags;
    int                 argcount;
    union {
	char               *codeblock;
	struct _codenode   *jump;
        Literalnode	    literal;
        Symbolnode	    symbol;
	int                 operand;
    } u;
} codenode         , *Codenode;

typedef struct _codestate {
    Codenode		code;
    Codenode		last;
    int			maxstack;
    int			curstack;
} codestate, *Codestate;


Codestate	    newCode();
void		    freeCode(Codestate cstate);
Codenode	    genCode(Codestate cstate, enum code_type type,
			 enum oper_type oper, int amount);
void                genStore(Codestate cstate, Symbolnode sym);
void                genPushLit(Codestate cstate, Literalnode lit);
void                genPush(Codestate cstate, Symbolnode sym);
void                genSend(Codestate cstate, Literalnode lit, int argc,
			int superFlag);
Codenode	    genBlockCopy(Codestate cstate, int argc);
void                genJump(Codestate cstate, Codenode label);
void                setJumpTarget(Codestate cstate, Codenode label, 
			int advance);
int		    isGetInst(Codestate cstate);
int		    isSetInst(Codestate cstate);
int                 optimize(Codestate cstate);
void                genblock(Codestate cstate);


/* Generate Empty location */
#define genNop(cstate) genCode(cstate, Nop, Nil, 0)

/* Generate push nil opcode.  */
#define genPushNil(cstate) genCode(cstate, Push, Nil, 1)

/* Generate return nil opcode.  */
#define genReturnNil(cstate) genCode(cstate, Return, Nil, 0)

/* Generate return Top of stack opcode.  */
#define genReturnTOS(cstate) genCode(cstate, Return, Stack, 0)

#define genPopTOS(cstate) genCode(cstate, PopStack, Stack, -1)

#define genDupTOS(cstate) genCode(cstate, Duplicate, Stack, 1)

#define genJumpForw(cstate) genCode(cstate, Jump, Label, 0)

#define genJumpFForw(cstate) genCode(cstate, JFalse, Label, -1)

#define genJumpTForw(cstate) genCode(cstate, JTrue, Label, -1)

#define getCodeLabel(cstate) (cstate->last)

