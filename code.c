/*
 * Smalltalk interpreter: Parser.
 *
 * $Log: code.c,v $
 * Revision 1.5  2001/01/16 01:08:16  rich
 * Code cleanup.
 *
 * Revision 1.4  2000/08/19 19:46:50  rich
 * Fixed optimizer bug resulting in not all code being emited.
 * Always relabel nodes after jump optimization.
 *
 * Revision 1.3  2000/02/02 16:48:58  rich
 * Changed include order.
 *
 * Revision 1.2  2000/02/01 18:09:46  rich
 * Removed unused variables.
 * Cleaned up max stack sizeing code.
 * Routines to check for get and set instance variable.
 * Changed way jump targets set.
 * Improved optimizer.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#ifndef lint
static char        *rcsid =
	"$Id: code.c,v 1.5 2001/01/16 01:08:16 rich Exp rich $";

#endif

#include "smalltalk.h"
#include "object.h"
#include "smallobjs.h"
#include "interp.h"
#include "symbols.h"
#include "code.h"
#include "fileio.h"
#include "dump.h"

Codenode            code = NULL;
Codenode            lastcode = NULL;

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

    /* Create a new code node */
    if ((newcode = (Codenode) malloc(sizeof(codenode))) != NULL) {
	/* Fill in values */
	newcode->type = type;
	newcode->oper = oper;
	newcode->len = 0;
	newcode->offset = 0;
	newcode->flags = 0;
	newcode->u.codeblock = NULL;
        newcode->next = NULL;
	/* Hook it into the linked list of instructions */
	if (cstate->code == NULL) {
	    cstate->code = newcode;
	    cstate->last = newcode;
	} else {
	    cstate->last->next = newcode;
	    cstate->last = newcode;
	}
	/* Adjust the stack */
        if (cstate->curstack > cstate->maxstack)
           cstate->maxstack = cstate->curstack;
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

    newnode = genCode(cstate, Jump, Label, 0);
    newnode->u.jump = label;
    newnode->argcount = 0;
}

void
setJumpTarget(Codestate cstate, Codenode label, int advance)
{
    if (label != NULL && cstate->last != NULL) {
      	label->u.jump = cstate->last;
	if (label->type != BlockCopy)
	    label->argcount = advance;
    }
}

/*
 * Remove the next code node.
 */
static void
removeNext(Codestate cstate, Codenode node)
{
    if (node != NULL && node->next != NULL) {
	Codenode            dead = node->next;

	if ((dead->flags & CODE_LABEL) != 0)
	   dump_string("Removing referenced node");
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
 * Remove the current node.
 */
static Codenode
removeCur(Codestate cstate, Codenode node)
{
    if (node != NULL) {
	Codenode            next = node->next;
        Codenode	    temp;

	/* Remove anything it referenced */
	if (node->oper == Literal && node->u.literal != NULL) {
	    node->u.literal->usage--;
	}
	if (node->type == CodeBlock)
	    free(node->u.codeblock);
	/* Remove it from tree */
	if (node == cstate->code) 
	    cstate->code = next;
	else {
	    for(temp = cstate->code; temp != NULL; temp = temp->next) {
		if (temp->next == node) {
		    temp->next = next;
		    if (cstate->last == node)
			cstate->last = temp;
		    break;
		}
	    }
	    
	}

	/* If old node was a label, advance all labeles to next */
	for (temp = cstate->code; temp != NULL; temp = temp->next) {
	    if (temp->oper == Label && temp->u.jump == node) {
		temp->u.jump = next;
		next->flags |= CODE_LABEL;
	    }
    	}
	free(node);
        return next;
    }
    return NULL;
}

/*
 * Compare two node. Return true if they point to same type of
 * object.
 */
static int
compareNode(Codenode node1, Codenode node2)
{
    if (node1->oper != node2->oper)
	return FALSE;

    switch (node1->oper) {
    default:
	break;
    case Temp:
    case Inst:
    case Arg:
    	if (node1->u.symbol != node2->u.symbol)
	    return FALSE;
        break;
     case Literal:
     case Variable:
        if (node1->u.literal != node2->u.literal)
	    return FALSE;
    	node2->u.literal->usage--;
        break;
     }
     return TRUE;
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
	     (nxt->type == CodeBlock || nxt->type == Nop );
	     nxt = nxt->next)
	    len += nxt->len;

       /* Build new code array */
	if ((cb = (char *) realloc(cur->u.codeblock, len)) == NULL)
	    break;
	i = cur->len;
	for (nxt = cur->next;
	     nxt != NULL &&
             (nxt->type == CodeBlock || nxt->type == Nop);
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
 * Check if code could be a get instance variable.
 *
 *   psh ins #
 *   ret tos
 */
int
isGetInst(Codestate cstate)
{
    Codenode            cur;
    int                 inst;

    cur = cstate->code;
    if (cur == NULL)
	return -1;
    if (cur->type != Push || cur->oper != Inst)
	return -1;
    inst = cur->u.symbol->offset;
    if ((cur = cur->next) == NULL)
	return -1;
    if (cur->type != Return || cur->oper != Stack)
	return -1;
    if (cur->next != NULL)
	return -1;
    return inst;
}

/*
 * Check if code could be a set instance variable.
 *
 *   psh arg 0       psh arg 0
 *   str ins #	     dup
 *   psh arg 0	     str arg 0
 *   ret tos         ret tos
 */
int
isSetInst(Codestate cstate)
{
    Codenode            cur;
    int                 inst;

    cur = cstate->code;
    if (cur == NULL)
	return -1;
    if (cur->type != Push || cur->oper != Arg || cur->u.symbol->offset != 0)
	return -1;
    if ((cur = cur->next) == NULL)
	return -1;
    if (cur->type == Store && cur->type == Inst) {
        inst = cur->u.symbol->offset;
        if ((cur = cur->next) == NULL)
	    return -1;
        if (cur->type != Push || cur->oper != Arg || cur->u.symbol->offset != 0)
	    return -1;
    } else if (cur->type == Duplicate) {
        if ((cur = cur->next) == NULL)
	    return -1;
        if (cur->type == Store && cur->type == Inst) 
            inst = cur->u.symbol->offset;
	else
	    return -1;
    } else
	return -1;
    if ((cur = cur->next) == NULL)
        return -1;
    if (cur->type != Return || cur->oper != Stack)
	return -1;
    if (cur->next != NULL)
	return -1;
    return inst;
}

/*
 * Fix jump targets to point to next instruction, also set referenced flag.
 */
static void
fixjumps(Codestate cstate)
{
    Codenode            cur;

    for (cur = cstate->code; cur != NULL; cur = cur->next) {
	if (cur->oper == Label && cur->u.jump != NULL && 
		cur->u.jump->next != NULL) {
	    Codenode target = cur->u.jump->next;
	    if (cur->type != BlockCopy &&  cur->argcount > 0)
		target = target->next;
	    cur->u.jump = target;
	    target->flags |= CODE_LABEL;
	}
    }
}

/*
 * Preform inline optimitization.
 */
static int
peephole(Codestate cstate)
{
    Codenode            cur;
    int                 superflag = 0;
    int                 i;


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
	   /* Remove unneeded push/pop pairs */
	    if (beginBlock(cur) && cur->next->type == PopStack) {
		cur = removeCur(cstate, cur);
		cur = removeCur(cstate, cur);
		continue;
	    }

	   /* Convert push x /push x to push x/dup */
	    if (beginBlock(cur) && cur->next->type == Push &&
	        compareNode(cur, cur->next) == TRUE) {
		cur->next->type = Duplicate;
		cur->next->oper = Stack;
	    }

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
		    break;
		default:
		    break;
	        }
	    }

	   /* Convert push bool, jcond to jump or pop */
	    if (beginBlock(cur) &&
		 (cur->next->type == JTrue || cur->next->type == JFalse)) {
	        switch (cur->oper) {
	        case True:
		     if (cur->next->type == JTrue) 
			cur->next->type = Jump;		/* Jump always */
		     else
			cur = removeCur(cstate, cur);	/* Never Jump */
		     cur = removeCur(cstate, cur);
		     continue;
	        case False:
		     if (cur->next->type == JFalse) 
			cur->next->type = Jump;		/* Jump always */
		     else
			cur = removeCur(cstate, cur);	/* Never Jump */
		     cur = removeCur(cstate, cur);
		     continue;
		default:
		    /* Can't do anything since don't know what got pushed */
		    break;
	        }
	    }
	    break;

	case Duplicate:
	    /* Remove dup/pop pairs */
	    if (beginBlock(cur) && cur->next->type == PopStack) {
		cur = removeCur(cstate, cur);
		cur = removeCur(cstate, cur);
		break;
	    }

	   /* Don't need a dup before a ret */
	    if (beginBlock(cur) && cur->next->type == Return) {
		cur = removeCur(cstate, cur);
		break;
	    }
	    /* Convert  Dup, Store, Pop -> Store */
	    if (beginBlock(cur) && cur->next->type == Store &&
		beginBlock(cur->next) && cur->next->next->type == PopStack) {
		if (beginBlock(cur->next->next)
		    && cur->next->next->next->type == Push &&
	               compareNode(cur->next, cur->next->next->next) == TRUE) {
		    removeNext(cstate, cur->next);
		    removeNext(cstate, cur->next);
		} else {
		    cur = removeCur(cstate, cur);
		    removeNext(cstate, cur);
		}
	    }
	    break;

	case Jump:
	case Return:
	   /* Remove dead code after a jump or return */
	    while (beginBlock(cur)) {
		removeNext(cstate, cur);
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
		    cur->oper = Operand;
		    cur->u.literal->usage--;
		    cur->u.operand = i;
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
 * Readjust reference labels.
 */
static void
relabel(Codestate cstate)
{
    Codenode            cur;

    for (cur = cstate->code; cur != NULL; cur = cur->next) 
	cur->flags &= ~CODE_LABEL;

    /* If node is a jump/block, mark target */
    for (cur = cstate->code; cur != NULL; cur = cur->next) 
        if (cur->oper == Label) 
	    cur->u.jump->flags |= CODE_LABEL;
        
} 

/*
 * Preform code motion optimizations.
 */
static int
optimizeJump(Codestate cstate)
{
     Codenode		cur, node;
     int		valuenum = -1;
     Objptr		valuesym = internString("value");
     int		i;
     int		changed = FALSE;

     for (i = 0; i < 32; i++) {
	if (get_pointer(SpecialSelectors, i) == valuesym) {
	    valuenum = i;
	    break;
	}
    }
	
     for (cur = cstate->code; cur != NULL; cur = cur->next) {
	switch (cur->type) {
	case Duplicate:
		/* Optimize jump chains */
		if (cur->next != NULL && 
		    (cur->next->type == JTrue || cur->next->type == JFalse) &&
		    cur->next->next != NULL &&
		    cur->next->next->type == PopStack && 
		    (cur->next->u.jump->type == JFalse ||
			cur->next->u.jump->type == JTrue) &&
		    cur->next->u.jump->next != NULL) {
		   /* Remove dup and pop */
		    cur = removeCur(cstate, cur);
		    removeNext(cstate, cur);
		   /* Move jump forward one step */
		    if (cur->u.jump->type != cur->type)
		    	cur->u.jump = cur->u.jump->next;
		    else
		    	cur->u.jump = cur->u.jump->u.jump;
	            cur->u.jump->flags |= CODE_LABEL;
		    changed = TRUE;
		}
 	        break;
	case JTrue:
	case JFalse:
	case Jump:
		/* Jumps to jumps can be passed through */
		if (cur->u.jump->type == Jump) {
		    cur->u.jump = cur->u.jump->u.jump; 
		    changed = TRUE;
		}
		/* Remove jumps to next location */
		if (cur->u.jump == cur->next) {
		    changed = TRUE;
		    if (cur->type == JTrue || cur->type == JFalse) {
			cur->type = PopStack;
			cur->oper = Stack;
		    } else {
			cur = removeCur(cstate, cur);
			continue;
		    }
		}
		break;
	case BlockCopy:
		/* Try and unblock whiles */
		if (cur->argcount == 0 && cur->u.jump->type == Duplicate &&
		   cur->u.jump->next != NULL && 
		   ((cur->u.jump->next->type == Send &&
			cur->u.jump->next->u.literal->value == valuesym) || 
		    (cur->u.jump->next->type == SendSpec && 
			cur->u.jump->next->u.operand == valuenum)) &&
		    cur->u.jump->next->next != NULL &&
		    (cur->u.jump->next->next->type == JFalse ||
			cur->u.jump->next->next->type == JTrue) &&
		    cur->u.jump->next->next->u.jump->type == PopStack) {
		    /* Major code surgery follows */
		    /* All labels that point at the dup need to be pointed
		       at the inst after the block copy */
		    for(node = cstate->code; node != NULL; node = node->next) {
        		if (node->oper == Label && node->u.jump == cur->u.jump
				&& node != cur) {
			    node->u.jump = cur->next;
			}
        		if (node->oper == Label && node->u.jump == cur) {
			    node->u.jump = cur->next;
			}
		    }
		    /* All ret blks between blockcopy and target need to be
		       converted to jmp to after send */
		    for(node = cur->next; node != cur->u.jump; node = node->next) {
			if (node->type == Return && node->oper == Block) {
			    node->type = Jump;
			    node->oper = Label;
			    node->u.jump = cur->u.jump->next->next;
			}
		    }
		    /* Remove extra instructions */
		    /* Remove pop */
		    removeCur(cstate, cur->u.jump->next->next->u.jump);
		    /* remove Dup and send */
		    removeCur(cstate, cur->u.jump->next);
		    removeCur(cstate, cur->u.jump);
		    cur = removeCur(cstate, cur);
		    changed = TRUE;
		    continue;
		}
	     break;
	default:
	     break;
        }
    }
    return changed;
}

/*
 * Optimize a code block.
 */
int
optimize(Codestate cstate)
{
    int                 superflag = 0;
    int                 i;

    fixjumps(cstate);
    show_code(cstate);

    do {
        superflag = peephole(cstate);
	i = optimizeJump(cstate);
        relabel(cstate);
    } while (i == TRUE);
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
	    opcode = SNDSPC1 + cur->u.operand;
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
	i = -1;
	switch (cur->type) {
	default:		/* Skip if not jump */
	    len = 0;
	    continue;
	case JTrue:
	    operand = cur->u.jump->offset - (cur->offset + cur->len);
	    opcode = JMPT;
	    if (len == 1)
		opcode |= 0xf & operand;
	    else if (len == 4) {
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
	    else if (len == 4) {
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
	    }
	    if (i != -1)
		cur->u.codeblock[j++] = i;
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

