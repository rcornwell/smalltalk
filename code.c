/*
 * Smalltalk interpreter: Parser.
 *
 * $Log: $
 *
 */

#ifndef lint
static char        *rcsid =
	"$Id: $";

#endif

/* System stuff */
#ifdef unix
#include <stdio.h>
#include <unistd.h>
#include <memory.h>
#include <malloc.h>
#endif
#ifdef _WIN32
#include <stddef.h>
#include <windows.h>
#include <math.h>

#define malloc(x)	GlobalAlloc(GMEM_FIXED, x)
#define free(x)		GlobalFree(x)
#endif

#include "object.h"
#include "smallobjs.h"
#include "primitive.h"
#include "interp.h"
#include "lex.h"
#include "symbols.h"
#include "code.h"

Codenode            code = NULL;
Codenode            lastcode = NULL;
int                 maxstack;
int                 curstack;

/*
 * Create a new code state block.
 */
Codestate
newCode()
{
	Codestate	cstate;

	if ((cstate = (Codestate)malloc(sizeof(codestate))) == NULL)
		return NULL;

	cstate->code = NULL;
	cstate->last = NULL;
	cstate->maxstack = 0;
	cstate->curstack = 0;
	return cstate;
}

/*
 * Release a code block.
 */
void
freeCode(Codestate cstate)
{
    Codenode            cpp, cp;

   /* Free code table */
    for(cp = cstate->code; cp != NULL; cp = cpp) {
	cpp = cp->next;
	if (cp->type == CodeBlock)
	    free(cp->u.codeblock);
	free(cp);
    }

    free(cstate);
}

/*
 * Create a new code block node. Return new node.
 */

Codenode
genCode(Codestate cstate, enum code_type type, enum oper_type oper, int amount)
{
    Codenode            newcode;

    if ((newcode = (Codenode) malloc(sizeof(codenode))) != NULL) {
	newcode->type = type;
	newcode->oper = oper;
	newcode->len = 0;
	newcode->offset = 0;
	newcode->flags = 0;
	newcode->u.codeblock = NULL;
        newcode->next = NULL;
	if (cstate->code == NULL) {
	    cstate->code = newcode;
	    cstate->last = newcode;
	} else {
	    cstate->last->next = newcode;
	    cstate->last = newcode;
	}
	if (amount < 0) {
           if (cstate->curstack > cstate->maxstack)
	      cstate->maxstack = cstate->curstack;
	}
    	cstate->curstack += amount;
    }
    return newcode;
}

void
genStore(Codestate cstate, Symbolnode sym)
{
    Codenode            newnode;

    newnode = genCode(cstate, Store, sym->type, -1);
    newnode->u.symbol = sym;
}

void
genPushLit(Codestate cstate, Literalnode lit)
{
    Codenode            newnode;

    newnode = genCode(cstate, Push, Literal, 1);
    newnode->u.literal = lit;
}

void
genPush(Codestate cstate, Symbolnode sym)
{
    Codenode            newnode;

    newnode = genCode(cstate, Push, sym->type, 1);
    newnode->u.symbol = sym;
}

void
genSend(Codestate cstate, Literalnode lit, int argc, int superFlag)
{
    Codenode            newnode;

    newnode = genCode(cstate, (superFlag)? SuperSend: Send, Literal, -argc);
    newnode->u.literal = lit;
    newnode->argcount = argc;
}

Codenode
genBlockCopy(Codestate cstate, int argc)
{
    Codenode            newnode;

    newnode = genCode(cstate, BlockCopy, Label, 1);
    newnode->argcount = argc;
    if ((cstate->curstack + argc) > cstate->maxstack)
	cstate->maxstack = cstate->curstack + argc;
    return newnode;
}

void
genJump(Codestate cstate, Codenode label)
{
    Codenode            newnode;

    newnode = genCode(cstate, Jump, Nil, 0);
    newnode->u.jump = label;
    if (label != NULL)
	label->flags |= CODE_LABEL;
}

void
setJumpTarget(Codestate cstate, Codenode label)
{
    if (label != NULL && cstate->last != NULL) 
        label->u.jump = cstate->last;
}

/*
 * Remove the next code node.
 */
static void
removeNext(Codestate cstate, Codenode node)
{
    if (node != NULL && node->next != NULL) {
	Codenode            dead = node->next;

	node->next = dead->next;
       /* Fix last pointer */
	if (dead == cstate->last) {
	    cstate->last = node;
	    node->next = NULL;
	}
	if (dead->type == CodeBlock) {
	    free(dead->u.codeblock);
	} else if (dead->oper == Literal && dead->u.literal != NULL) {
	    dead->u.literal->usage--;
	}
	free(dead);
    }
}

/*
 * Check if the next statement begins a basic block.
 */
static int
beginBlock(Codenode node)
{
    if (node != NULL && node->next != NULL &&
	(node->next->flags & CODE_LABEL) == 0)
	return 1;
    else
	return 0;
}

/*
 * Combine blocks of code together into one huge block.
 */
static void
combineCode(Codestate cstate)
{
    Codenode            cur, nxt;
    int                 len;
    int                 i, j;

   /* Coloaless all codeblocks together */
    for (cur = cstate->code; cur != NULL; cur = cur->next) {
	char               *cb;

       /* Skip to next if not a codeblock */
	if (cur->type != CodeBlock)
	    continue;
       /* Exit is no more blocks */
	if (cur->next == NULL)
	    break;
	len = cur->len;

       /* Find end of code block run */
	for (nxt = cur->next;
	     nxt != NULL &&
	     (nxt->type == CodeBlock || nxt->type == Nop ) &&
	     (nxt->flags & CODE_LABEL) == 0;
	     nxt = nxt->next)
	    len += nxt->len;

       /* Build new code array */
	if ((cb = (char *) realloc(cur->u.codeblock, len)) == NULL)
	    break;
	i = cur->len;
	for (nxt = cur->next;
	     nxt != NULL &&
             (nxt->type == CodeBlock || nxt->type == Nop) &&
	     (nxt->flags & CODE_LABEL) == 0;
	     nxt = cur->next) {
	   /* Copy over chunks */
	    if (nxt->type == CodeBlock)
	        for (j = 0; j < nxt->len; cb[i++] = nxt->u.codeblock[j++]);
	   /* Remove the node */
	    removeNext(cstate, cur);
	}
	cur->len = len;

	cur->u.codeblock = cb;
    }
}

/*
 * Optimize a code block.
 */
int
optimize(Codestate cstate)
{
    Codenode            cur;
    int                 changed;
    int                 superflag = 0;
    int                 i;

/*
 * Fix jump targets to point to next instruction, also set referenced flag.
 */
    for (cur = cstate->code; cur != NULL; cur = cur->next) {
	if (cur->oper == Label) {
	    if (cur->u.jump != NULL && cur->u.jump->next != NULL) {
		if (cur->u.jump->next->type == Nop) 
		     cur->u.jump = cur->u.jump->next->next->next;
		else
		     cur->u.jump = cur->u.jump->next;
		cur->u.jump->flags |= CODE_LABEL;
	    }
	}
    }

/* Preform preoptimization pass.
 * 1) Convert sends into sendSpecail if we can.
 * 2) Remove Dup/Pop pairs when second one is not referenced.
 * 3) Remove Push/Popstack pairs.
 * 4) Remove unreferenced code after a return.
 * 5) Remove unreferenced code after a jump.
 */
    for (cur = cstate->code; cur != NULL; cur = cur->next) {
	switch (cur->type) {
	case Push:
	   /* Check if it could be a zero or a one. */
	    if (cur->oper == Literal) {
		if (is_integer(cur->u.literal->value)) {
		    i = as_integer(cur->u.literal->value);
		    if (i == 0 || i == 1)
			cur->u.literal->usage--;
		}
	    }

	   /* Check if we can shorten a return TOS */
	    if (beginBlock(cur) &&
		 cur->next->type == Return && cur->next->oper == Stack) {
	        switch (cur->oper) {
	        case Self:
	        case True:
	        case False:
	        case Nil:
	        case Temp:
		    cur->type = Return;
		    removeNext(cstate, cur);
		    /* Clean up any code after the return block */
	    	    while (beginBlock(cur)) 
			removeNext(cstate, cur);
		    changed |= 1;
		    break;
		default:
		    break;
	        }
	    }

	case Duplicate:
	    if (beginBlock(cur) && cur->next->type == PopStack) {
		removeNext(cstate, cur);
		changed |= 1;
		break;
	    }
	    /* Convert  Dup, Store, Pop -> Store */
	    if (beginBlock(cur) && cur->next->type == Store &&
		beginBlock(cur->next) && cur->next->next->type == PopStack) {
		/* Next to the current value */
		cur->type = Store;
		cur->oper = cur->next->oper;
		cur->u.symbol = cur->next->u.symbol;
		removeNext(cstate, cur);	/* Remove next two */
		removeNext(cstate, cur);
		changed |= 1;
	    }
	    break;
	case Jump:
	case Return:
	    while (beginBlock(cur)) {
		removeNext(cstate, cur);
		changed |= 1;
	    }
	    break;
	case SuperSend:
	    superflag = 1;
	    break;
	case Send:
	   /* Scan for selector in specails. */
	    for (i = 0; i < 32; i++) {
		if (get_pointer(SpecialSelectors, i) == cur->u.literal->value) {
		    cur->type = SendSpec;
		    cur->u.literal->usage--;
		    cur->u.operand = i;
		    changed = 1;
		    break;
		}
	    }
	    break;
	default:
	    break;
	}
    }
    return superflag;
}

/*
 * Generate a block of code.
 */
void
genblock(Codestate cstate)
{
    Codenode            cur;
    int                 changed;
    int                 i, j, len;
    int                 opcode;
    int                 operand;

   /* Convert everything but jumps into code blocks */
    for (cur = cstate->code; cur != NULL; cur = cur->next) {
	len = 0;
	opcode = 0;
	operand = 0;
	switch (cur->type) {
	case Nop:
	     cur->len = 0;
	     continue;
	case Store:
	    if (cur->oper == Temp)
		opcode = STRTMP;
	    else if (cur->oper == Variable) {
		opcode = STRVAR;
		operand = cur->u.symbol->lit->offset;
		len = 2;
		break;
	    } else
		opcode = STRINST;
	    if (cur->u.symbol->offset >= 16) {
		opcode >>= 4;
		operand = cur->u.symbol->offset;
		len = 2;
	    } else {
		opcode |= cur->u.symbol->offset;
		len = 1;
	    }
	    break;
	case Push:
	    len = 0;
	    operand = 0;
	    switch (cur->oper) {
	    case Super:
	    case Self:
		opcode = PSHSELF;
		break;
	    case True:
		opcode = PSHTRUE;
		break;
	    case False:
		opcode = PSHFALS;
		break;
	    case Nil:
		opcode = PSHNIL;
		break;
	    case Temp:
		opcode = PSHTMP;
		operand = cur->u.symbol->offset;
		break;
	    case Inst:
		opcode = PSHINST;
		operand = cur->u.symbol->offset;
		break;
	    case Arg:
		opcode = PSHARG;
		operand = cur->u.symbol->offset;
		break;
	    case Literal:
		opcode = PSHLIT;
		operand = cur->u.literal->offset;
		if (is_integer(cur->u.literal->value)) {
		    i = as_integer(cur->u.literal->value);
		    if (i == 0) {
			opcode = PSHZERO;
			len = 1;
		    } else if (i == 1) {
			opcode = PSHONE;
			len = 1;
		    }
		}
		break;
	    case Variable:
		opcode = PSHVAR;
		operand = cur->u.symbol->lit->offset;
		len = 2;
		break;
	    default:
		break;
	    }
	    if (len == 0) {
		if (operand >= 16) {
		    opcode >>= 4;
		    len = 2;
		} else {
		    opcode |= operand;
		    len = 1;
		}
	    }
	    break;
	case Duplicate:
	    opcode = DUPTOS;
	    len = 1;
	    break;
	case PopStack:
	    opcode = POPSTK;
	    len = 1;
	    break;
	case Break:
	    opcode = JMP;
	    len = 1;
	    break;
	case Return:
	    len = 0;
	    operand = 0;
	    switch (cur->oper) {
	    case Self:
		opcode = RETSELF;
		break;
	    case True:
		opcode = RETTRUE;
		break;
	    case False:
		opcode = RETFALS;
		break;
	    case Nil:
		opcode = RETNIL;
		break;
	    case Temp:
		opcode = RETTMP;
		operand = cur->u.symbol->offset;
		break;
	    case Stack:
		opcode = RETTOS;
		break;
	    case Block:
		opcode = RETBLK;
		break;
	    default:
		break;
	    }
	    if (operand >= 16) {
	        opcode >>= 4;
	        len = 2;
	    } else {
	        opcode |= operand;
	        len = 1;
	    }
	    break;
	case SuperSend:
	case Send:
	    if (cur->type == Send)
		opcode = SNDLIT;
	    else
		opcode = SNDSUP;

	    operand = cur->u.literal->offset;
	    if (operand >= 16) {
		opcode >>= 4;
		len = 3;
	    } else {
		opcode |= operand;
		len = 2;
	    }
	    break;
	case SendSpec:
	    opcode = SNDSPC1;
	    opcode += cur->u.operand;
	    operand = cur->argcount;
	    len = 2;
	    break;
	case JTrue:
	case JFalse:
	case Jump:
	    cur->len = 1;
	    break;
	case BlockCopy:
	    cur->len = 3;
	    break;
	default:
	    break;
	}
       /* Build the code block */
	if (len > 0) {
	    if ((cur->u.codeblock = (char *) malloc(len)) == NULL)
		return;
	    i = 0;
	    cur->u.codeblock[i++] = opcode;
	    if (cur->type == Send || cur->type == SuperSend) {
	        if (len > 2) 
		    cur->u.codeblock[i++] = operand;
	        cur->u.codeblock[i++] = cur->argcount;
	    } else if (len > 1) 
		    cur->u.codeblock[i++] = operand;
	    cur->len = len;
	    cur->type = CodeBlock;
	    cur->oper = Block;
	}
    }

    do {
	changed = 0;
       /* Set offsets of all blocks */
	for (cur = cstate->code, i = 0; cur != NULL; cur = cur->next) {
	    cur->offset = i;
	    i += cur->len;
	}

       /* Convert everything but jumps into code blocks */
	for (cur = cstate->code; cur != NULL; cur = cur->next) {
	    switch (cur->type) {
	    default:
		len = cur->len;
		break;
	    case JTrue:
	    case JFalse:
	        operand = cur->u.jump->offset - (cur->offset + cur->len);
		if (operand >= 0 && operand < 16)
		    len = 1;
		else if (operand < -127 || operand > 128)
		    len = 4;
		else
		    len = 2;
		break;
	    case Jump:
	        operand = cur->u.jump->offset - (cur->offset + cur->len);
		if (operand >= 0 && operand < 16)
		    len = 1;
		else if (operand < -127 || operand > 128)
		    len = 3;
		else
		    len = 2;
		break;
	    case BlockCopy:
	        operand = cur->u.jump->offset - (cur->offset + cur->len);
		if (operand >= 0 && operand < 16)
		    len = 3;
		else if (operand < -127 || operand > 128)
		    len = 5;
		else
		    len = 4;
		break;
	    }
	    if (cur->len != len) {
		cur->len = len;
		changed = 1;
	    }
	}
    }
    while (changed == 1);

   /* Convert jumps and remaining into code blocks */
    for (cur = cstate->code; cur != NULL; cur = cur->next) {
	len = cur->len;
	i = 0;
	switch (cur->type) {
	default:		/* Skip if not jump */
	    len = 0;
	    continue;
	case JTrue:
	    operand = cur->u.jump->offset - (cur->offset + cur->len);
	    opcode = JMPT;
	    if (len == 1)
		opcode |= 0xf & operand;
	    else if (len == 3) {
		opcode = JMPF + 3;
		i = JMPLNG;
	    } else
		opcode >>= 4;
	    break;
	case JFalse:
	    operand = cur->u.jump->offset - (cur->offset + cur->len);
	    opcode = JMPF;
	    if (len == 1)
		opcode |= 0xf & operand;
	    else if (len == 3) {
		opcode = JMPT + 3;
		i = JMPLNG;
	    } else
		opcode >>= 4;
	    break;
	case Jump:
	    operand = cur->u.jump->offset - (cur->offset + cur->len);
	    opcode = JMP;
	    if (len == 1)
		opcode |= 0xf & operand;
	    else if (len == 3)
		opcode = JMPLNG;
	    else
		opcode >>= 4;
	    break;
	case BlockCopy:
	    operand = cur->u.jump->offset - (cur->offset + cur->len);
	    opcode = BLKCPY;
	    i = JMP;
	    if (len == 3)
		i |= 0xf & operand;
	    else if (len == 5)
		i = JMPLNG;
	    else
		i >>= 4;
	    break;
	}

       /* Build the code block */
	if (len > 0) {
	    cur->u.jump->flags &= ~CODE_LABEL;

	    if ((cur->u.codeblock = (char *) malloc(len)) == NULL)
		return;

	    j = 0;
	    cur->u.codeblock[j++] = opcode;
	    if (opcode == BLKCPY) {
		cur->u.codeblock[j++] = cur->argcount;
		len--;
		len--;
		cur->u.codeblock[j++] = i;
	    }
	    if (len > 1)
		cur->u.codeblock[j++] = operand;
	    if (len > 2)
		cur->u.codeblock[j++] = operand >> 8;
	    cur->type = CodeBlock;
	    cur->oper = Block;
	}
    }

    /* Combine remaining code blocks, should have only one block left */
    combineCode(cstate);
}



