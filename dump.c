
/*
 * Smalltalk interpreter: Object space dump utilities.
 *
 * $Log: dump.c,v $
 * Revision 1.4  2000/08/19 19:24:49  rich
 * Print out if a node is referenced or not.
 *
 * Revision 1.3  2000/02/02 00:37:43  rich
 * Exported dump_class_name
 *
 * Revision 1.2  2000/02/01 18:09:49  rich
 * Exposed dump_object_value.
 * Renamed trace_inst to dump_inst.
 * Added stack pointer display to push instructions.
 * Added trace code to display set and get of instance variable
 * Added dump of code tree.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#ifndef lint
static char        *rcsid =
"$Id: dump.c,v 1.4 2000/08/19 19:24:49 rich Exp rich $";

#endif

/* System stuff */
#ifdef unix
#include <stdio.h>
#include <unistd.h>
#include <malloc.h>
#include <memory.h>

#define wsprintf	sprintf
#endif
#ifdef _WIN32
#include <stddef.h>
#include <windows.h>
#endif

#include "object.h"
#include "smallobjs.h"
#include "fileio.h"
#include "interp.h"
#include "lex.h"
#include "symbols.h"
#include "code.h"
#include "dump.h"

/*
 * Pretty print and dump a class name.
 */
char        *
dump_class_name(Objptr op)
{
    static char         buffer[30];
    Objptr              class = class_of(op);
    Objptr              cname;
    int                 i, sz, len, base;

    wsprintf(buffer, "#%d (", class);
    if (class != NilPtr && (cname = get_pointer(class, CLASS_NAME)) != NilPtr) {
	len = length_of(cname);
	base = fixed_size(cname);
	sz = strlen(buffer);
	for (i = 0; i < len && sz < (sizeof(buffer) - 2); i++)
	    buffer[sz++] = get_byte(cname, i + base);
	buffer[sz++] = '\0';
    } else
	strcat(buffer, "?");
    strcat(buffer, ")");
    return buffer;
}

/*
 * Dump contents of simple objects.
 */
char        *
dump_object_value(Objptr op)
{
    static char         buffer[1000];
    Objptr              class;
    Objptr              cname;
    Objptr              value;
    int                 i, sz, len, base;
    double		*fval;

    if (is_integer(op)) {
	wsprintf(buffer, "Integer %d", as_integer(op));
	return buffer;
    }
    class = class_of(op);
    wsprintf(buffer, "#%d ", op);
    switch (class) {
    case UndefinedClass:
	strcat(buffer, "nil");
	break;
    case StringClass:
	strcat(buffer, "String '");
	len = length_of(op);
	base = fixed_size(op);
	sz = strlen(buffer);
	for (i = 0; i < len; i++)
	    buffer[sz++] = get_byte(op, i + base);
	buffer[sz++] = '\0';
	strcat(buffer, "'");
	break;
    case CharacterClass:
	value = get_integer(op, CHARVALUE);
	if (value >= ' ' && value < 0x7f)
	    wsprintf(buffer, "#%d Character $%c", op, value);
	else
	    wsprintf(buffer, "#%d Character $0x%02x", op, value);
	break;
    case SymLinkClass:
	op = get_pointer(op, SYM_VALUE);
	strcat(buffer, "Symbol #");
	len = length_of(op);
	base = fixed_size(op);
	sz = strlen(buffer);
	for (i = 0; i < len; i++)
	    buffer[sz++] = get_byte(op, i + base);
	buffer[sz++] = '\0';
	break;
    case FloatClass:
	len = strlen(buffer);
	fval = (double *) get_object_base(op);
	wsprintf(&buffer[len], "Float %f", *fval);
	break;
    default:
	wsprintf(buffer, "#%d -> Class #%d (", op, class);
	if (class != NilPtr &&
	    (cname = get_pointer(class, CLASS_NAME)) != NilPtr) {
	    len = length_of(cname);
	    base = fixed_size(cname);
	    sz = strlen(buffer);
	    for (i = 0; i < len; i++)
		buffer[sz++] = get_byte(cname, i + base);
	    buffer[sz++] = '\0';
	} else
	    strcat(buffer, "?");
	strcat(buffer, ")");
	break;
    }
    return buffer;
}

/*
 * Dump summary of object table.
 */
void
dump_otable()
{
    char                buffer[1024];
    int                 i;

    for (i = 0; i < (otsize / 2); i += 2) {
	if (notFree(i)) {
	    wsprintf(buffer, "#%d (%d%s%s%s) %s %d",
		     i, get_object_refcnt(i),
		     (is_indexable(i)) ? " index" : "",
		     (is_byte(i)) ? " byte" : "",
		     (!is_word(i)) ? " ptrs" : " word",
		     dump_class_name(i), size_of(i));
	    dump_string(buffer);
	}
    }
}

/*
 * Dump an Object.
 */
void
dump_object(int op)
{
    char                buffer[1024];
    int                 i;
    int                 len, sz, base;
    Objptr              o;

    if (!is_object(op)) {
	wsprintf(buffer, "integer %d", as_integer(op));
	dump_string(buffer);
	return;
    }

    if (notFree(op)) {
	wsprintf(buffer, "#%d (%d%s%s%s) %s %d [",
		 op, get_object_refcnt(op),
		 (is_indexable(op)) ? " index" : "",
		 (is_byte(op)) ? " byte" : "",
		 (!is_word(op)) ? " ptrs" : " word",
		 dump_class_name(op), size_of(op));
	dump_string(buffer);
	if (class_of(op) == CompiledMethodClass) {
	    dump_method(op);
	    return;
	}

	/* Print out variable part of object */
	len = fixed_size(op) / sizeof(Objptr);
	for (i = 0; i < len; i++) {
	    o = get_pointer(op, i);
	    wsprintf(buffer, "   v %d = %s", i, dump_object_value(o));
	    dump_string(buffer);
	}
	if (is_indexable(op)) {
	    len = length_of(op);
	    base = fixed_size(op);
	    if (class_of(op) == StringClass) {
		strcpy(buffer, "    String '");
		sz = strlen(buffer);
		for (i = 0; i < len; i++)
		    buffer[sz++] = get_byte(op, i + base);
		buffer[sz++] = '\0';
		strcat(buffer, "'");
		dump_string(buffer);
	    } else if (is_byte(op)) {
		dump_string("(");
		for (i = 0; i < len; i++) {
		    wsprintf(buffer, "    [%d] = %02x", i,
			     get_byte(op, i + base));
		    dump_string(buffer);
		}
		dump_string(")");
	    } else if (is_word(op)) {
		dump_string("(");
		base /= sizeof(Objptr);
		for (i = 0; i < len; i++) {
		    wsprintf(buffer, "    [%d] = %8x", i,
			     get_pointer(op, i + base));
		    dump_string(buffer);
		}
		dump_string(")");
	    } else {
		dump_string("(");
		base /= sizeof(Objptr);
		for (i = 0; i < len; i++) {
		    wsprintf(buffer, "     %d = %s", i,
			   dump_object_value(get_pointer(op, i + base)));
		    dump_string(buffer);
		}
		dump_string(")");
	    }
	    dump_string("]");
	}
    } else {
	wsprintf(buffer, "#%d free", op);
	dump_string(buffer);
    }
}

/*
 * Dump all objects.
 */
void
dump_objects()
{
    int                 i;

    for (i = 0; i < (otsize / 2); i += 2) {
	if (notFree(i)) {
	    dump_object(i);
	}
    }
}

/*
 * Disassemble a method.
 */
void
dump_method(Objptr op)
{
    int                 header;
    int                 ehdr;
    int                 lits;
    int                 bytes;
    int                 i;
    char                buffer[1024];
    char                opc[20];
    int                 opcode;
    int                 operand;
    int                 len;

    header = get_pointer(op, METH_HEADER);
    lits = LiteralsOf(header);
    bytes = size_of(op) - ((lits + METH_LITSTART) * sizeof(Objptr));
    wsprintf(buffer, "%08x Flag %d, Lits %d Stack %d Temps %d",
    header, 0xf & FlagOf(header), lits, StackOf(header), TempsOf(header));
    dump_string(buffer);
    if (FlagOf(header) == METH_EXTEND) {
	ehdr = get_pointer(op, METH_HEADER + lits);
	wsprintf(buffer, " %08x Extended: Args %d, Primitive %d",
		 ehdr, EArgsOf(ehdr), PrimitiveOf(ehdr));
	dump_string(buffer);
	lits--;
    }
   /* Dump literals */
    for (i = 0; i < lits; i++) {
	wsprintf(buffer, " Lit #%d: %s", i,
		 dump_object_value(get_pointer(op, METH_LITSTART + i)));
	dump_string(buffer);
    }

    lits = (METH_LITSTART + LiteralsOf(header)) * sizeof(Objptr);
   /* Disassemble Bytecodes */
    for (i = 0; i < bytes; i += len) {
	opcode = 0xff & get_byte(op, lits + i);
	operand = opcode & 0xf;
	len = 1;
      loop:
	switch (opcode & 0xf0) {
	case LONGOP:
	    if (operand == JMPLNG) {
		if ((i + 2) > bytes)
		   return;
		operand = 0xff & get_byte(op, lits + i + 1);
		operand += (0xff & get_byte(op, lits + i + 2)) << 8;
		if (operand > 32768)
		    operand -= 65536;
		wsprintf(opc, "j %d", operand + lits);
		len = 3;
		break;
	    }
	    if (operand == BLKCPY) {
		operand = 0xff & get_byte(op, lits + i + 1);
		wsprintf(opc, "blk %d", operand);
		len = 2;
		break;
	    }
	    opcode = operand << 4;
	    operand = 0xff & get_byte(op, lits + i + 1);
	    len++;
	    goto loop;
	case PSHARG:
	    wsprintf(opc, "psh arg(%d)", operand);
	    break;
	case PSHLIT:
	    wsprintf(opc, "psh lit(%d)", operand);
	    break;
	case PSHINST:
	    wsprintf(opc, "psh ins(%d)", operand);
	    break;
	case PSHTMP:
	    wsprintf(opc, "psh tmp(%d)", operand);
	    break;
	case STRINST:
	    wsprintf(opc, "str ins(%d)", operand);
	    break;
	case STRTMP:
	    wsprintf(opc, "str tmp(%d)", operand);
	    break;
	case RETTMP:
	    wsprintf(opc, "ret tmp(%d)", operand);
	    break;
	case JMPT:
	    if (len == 2) {
		operand = get_byte(op, lits + i + 1);
		if (operand > 127)
		   operand -= 256;
	    }
	    wsprintf(opc, "jpt Byte %d(%d)", i + len + operand + lits,
		     operand);
	    break;
	case JMPF:
	    if (len == 2) {
		operand = get_byte(op, lits + i + 1);
		if (operand > 127)
		   operand -= 256;
	    }
	    wsprintf(opc, "jpf Byte %d(%d)", i + len + operand + lits,
		     operand);
	    break;
	case JMP:
	    if (len == 2) {
		operand = get_byte(op, lits + i + 1);
		if (operand > 127)
		   operand -= 256;
	    }
	    wsprintf(opc, "jmp Byte %d(%d)", i + len + operand + lits,
		     operand);
	    break;

	case SNDSPC2:
	    operand += 16;
	case SNDSPC1:
	    wsprintf(opc, "snd spc(%d, %d)", operand,
		     0xff & get_byte(op, lits + i + 1));
	    
	    operand = get_byte(op, lits + i + 1);
	    len = 2;
	    break;
	case SNDSUP:
	    wsprintf(opc, "sup snd(%d, %d)", operand,
		     0xff & get_byte(op, lits + i + len++));
	    break;
	case SNDLIT:
	    wsprintf(opc, "snd lit(%d, %d)", operand,
		     0xff & get_byte(op, lits + i + len++));
	    break;
	case GRP2:
	    switch (opcode) {
	    case RETSELF:
		wsprintf(opc, "ret self");
		break;
	    case RETTOS:
		wsprintf(opc, "ret top");
		break;
	    case RETTRUE:
		wsprintf(opc, "ret true");
		break;
	    case RETFALS:
		wsprintf(opc, "ret false");
		break;
	    case RETNIL:
		wsprintf(opc, "ret nil");
		break;
	    case DUPTOS:
		wsprintf(opc, "dup");
		break;
	    case RETBLK:
		wsprintf(opc, "ret blk");
		break;
	    case POPSTK:
		wsprintf(opc, "pop");
		break;
	    case PSHVAR:
		operand = 0xff & get_byte(op, lits + i + 1);
		wsprintf(opc, "psh var(%d)", operand);
		len = 2;
		break;
	    case STRVAR:
		operand = 0xff & get_byte(op, lits + i + 1);
		wsprintf(opc, "str var(%d)", operand);
		len = 2;
		break;
	    case PSHSELF:
		wsprintf(opc, "psh self");
		break;
	    case PSHNIL:
		wsprintf(opc, "psh nil");
		break;
	    case PSHTRUE:
		wsprintf(opc, "psh true");
		break;
	    case PSHFALS:
		wsprintf(opc, "psh false");
		break;
	    case PSHONE:
		wsprintf(opc, "psh 1");
		break;
	    case PSHZERO:
		wsprintf(opc, "psh 0");
		break;
	    }
	}
	switch (len) {
	case 1:
   	    wsprintf(buffer, " Byte %d: %02x      %s", i + lits, opcode, opc);
	    break;
 	case 2:
   	    wsprintf(buffer, " Byte %d: %02x %02x   %s", i + lits, opcode,
			0xff & operand, opc);
	    break;
	case 3:
   	    wsprintf(buffer, " Byte %d: %02x %04x %s", i + lits, opcode,
			0xffff & operand, opc);
	    break;
	}
	dump_string(buffer);
    }
}

#ifdef SHOW_TOKEN
/*
 * Dump a token out.
 */
void
dump_token(int tok, void *state)
{
    char                buffer[1024];
    Token 		tstate = (Token) state;

    switch (tok) {
    case KeyEOS:
	strcpy(buffer, "{EOS}");
	break;
    case KeyLiteral:
	strcpy(buffer, "{Lit} ");
	break;
    case KeyName:
	wsprintf(buffer, "{Name} %s", get_token_string(tstate));
	break;
    case KeyKeyword:
	wsprintf(buffer, "{Keyword} %s", get_token_string(tstate));
	break;
    case KeyAssign:
	strcpy(buffer, "{<-}");
	break;
    case KeyRParen:
	strcpy(buffer, "{(}");
	break;
    case KeyLParen:
	strcpy(buffer, "{)}");
	break;
    case KeyReturn:
	strcpy(buffer, "{^}");
	break;
    case KeyCascade:
	strcpy(buffer, "{;}");
	break;
    case KeyPeriod:
	strcpy(buffer, "{.}");
	break;
    case KeySpecial:
	wsprintf(buffer, "{Spec} %s", get_token_spec(tstate));
	break;
    case KeyRBrack:
	strcpy(buffer, "{[}");
	break;
    case KeyLBrack:
	strcpy(buffer, "{]}");
	break;
    case KeyVariable:
	wsprintf(buffer, "{Var} %s", get_token_string(tstate));
	break;
    case KeyUnknown:
	strcpy(buffer, "{Unknown}");
	break;
    }

    dump_string(buffer);
    if (tok == KeyLiteral)
	dump_object(get_token_object(tstate));
    dump_string("");
}
#endif


#ifdef TRACE_INST
/*
 * Dump a instruction execute out.
 */
void
dump_inst(Objptr meth, int ip, int opcode, int oprand, Objptr op, int oprand2)
{
    char                buffer[1024];
    char                opc[20];
    int                 dumpflag = FALSE;

    ip -= LiteralsOf(get_pointer(meth, METH_HEADER)) + METH_LITSTART;
    switch (opcode & 0xf0) {
    case PSHARG:
	wsprintf(opc, "psh arg: %d [%d]", oprand, oprand2);
	dumpflag = TRUE;
	break;
    case PSHLIT:
	wsprintf(opc, "psh lit: %d [%d]", oprand, oprand2);
	dumpflag = TRUE;
	break;
    case PSHINST:
	wsprintf(opc, "psh ins: %d [%d]", oprand, oprand2);
	dumpflag = TRUE;
	break;
    case PSHTMP:
	wsprintf(opc, "psh tmp: %d [%d]", oprand, oprand2);
	dumpflag = TRUE;
	break;
    case STRINST:
	wsprintf(opc, "str ins: %d", oprand);
	dumpflag = TRUE;
	break;
    case STRTMP:
	wsprintf(opc, "str tmp: %d", oprand);
	dumpflag = TRUE;
	break;
    case RETTMP:
	wsprintf(opc, "ret tmp: %d", oprand);
	dumpflag = TRUE;
	break;
    case JMPT:
	wsprintf(opc, "jpt %d", oprand);
	dumpflag = TRUE;
	break;
    case JMPF:
	wsprintf(opc, "jpf %d", oprand);
	dumpflag = TRUE;
	break;
    case LONGOP:
	if (opcode == BLKCPY) {
	    wsprintf(opc, "blk %d", oprand);
	    dumpflag = TRUE;
	    break;
	}
    case JMP:
	wsprintf(opc, "jmp %d", oprand);
	break;

    case SNDSPC2:
    case SNDSPC1:
	wsprintf(opc, "snd spc %d", oprand2);
	dumpflag = TRUE;
	break;
    case SNDSUP:
	wsprintf(opc, "sup snd %d", oprand2);
	dumpflag = TRUE;
	break;
    case SNDLIT:
	wsprintf(opc, "snd lit %d", oprand2);
	dumpflag = TRUE;
	break;
    case GRP2:
	switch (opcode & 0xff) {
	case RETSELF:
	    wsprintf(opc, "ret self");
	    dumpflag = TRUE;
	    break;
	case RETTOS:
	    wsprintf(opc, "ret top");
	    dumpflag = TRUE;
	    break;
	case RETTRUE:
	    wsprintf(opc, "ret true");
	    break;
	case RETFALS:
	    wsprintf(opc, "ret false");
	    break;
	case RETNIL:
	    wsprintf(opc, "ret nil");
	    break;
	case DUPTOS:
	    wsprintf(opc, "dup [%d]", oprand2);
	    dumpflag = TRUE;
	    break;
	case RETBLK:
	    wsprintf(opc, "ret blk");
	    dumpflag = TRUE;
	    break;
	case POPSTK:
	    wsprintf(opc, "pop");
	    break;
	case PSHVAR:
	    wsprintf(opc, "psh var [%d]", oprand2);
	    dumpflag = TRUE;
	    break;
	case STRVAR:
	    wsprintf(opc, "str var");
	    dumpflag = TRUE;
	    break;
	case PSHSELF:
	    wsprintf(opc, "psh self [%d]", oprand2);
	    dumpflag = TRUE;
	    break;
	case PSHNIL:
	    wsprintf(opc, "psh nil [%d]", oprand2);
	    break;
	case PSHTRUE:
	    wsprintf(opc, "psh true [%d]", oprand2);
	    break;
	case PSHFALS:
	    wsprintf(opc, "psh false [%d]", oprand2);
	    break;
	case PSHONE:
	    wsprintf(opc, "psh 1 [%d]", oprand2);
	    break;
	case PSHZERO:
	    wsprintf(opc, "psh 0 [%d]", oprand2);
	    break;
	}
    }
    if (dumpflag)
	wsprintf(buffer, "#%d Exec: %d %02x %s %s", meth, ip, opcode, opc,
		 dump_object_value(op));
    else
	wsprintf(buffer, "#%d Exec: %d %02x %s", meth, ip, opcode, opc);
    dump_string(buffer);
}
/*
 * Dump set instance variable.
 */
void 
dump_setinst(Objptr op, int inst, Objptr value)
{
    char                buffer[1024];

    wsprintf(buffer, "Set: %s [%d] to ", dump_object_value(op), inst);
    strcat(buffer, dump_object_value(value));
    dump_string(buffer);
}

/*
 * Dump get instance variable.
 */
void 
dump_getinst(Objptr op, int inst, Objptr value)
{
    char                buffer[1024];

    wsprintf(buffer, "Get: %s [%d] is ", dump_object_value(op), inst);
    strcat(buffer, dump_object_value(value));
    dump_string(buffer);
}

/*
 * Report on success or failure of a primitive.
 */
void
dump_primitive(int flag, int number)
{
   char			buffer[1024];
   wsprintf(buffer, "Primitive: %d ", number);
   strcat(buffer, (flag)?"Success":"Failed");
   dump_string(buffer);
}
#endif


#ifdef TRACE_SEND
/*
 * Dump message send information.
 */
void 
dump_send(Objptr op, Objptr sel, Objptr meth)
{
    char                buffer[1024];

    wsprintf(buffer, "Send: to %s sel ", dump_object_value(op));
    strcat(buffer, dump_object_value(sel));
    strcat(buffer, " -> ");
    strcat(buffer, dump_object_value(meth));
    dump_string(buffer);
}
#endif

/*
 * Dump string and object message.
 */
void 
dump_str(char *str, Objptr op)
{
    char                buffer[1024];

    wsprintf(buffer, "%s #%d", str, op);
    dump_string(buffer);
}

#ifdef DUMP_CODETREE
/*
 * Dump a list of code.
 */
void
dump_code(void *state)
{
    Codestate 		cstate = (Codestate) state;
    Codenode            cur;
    char                buffer[1024];
    char                line[1024];
    char		ref;

    for (cur = cstate->code; cur != NULL; cur = cur->next) {
	switch (cur->type) {
	case Nop:
	     strcpy(buffer, "Nop");
	     break;
	case Store:
	    switch (cur->oper) {
	    case Temp:
		wsprintf(buffer, "Store Temp %s", cur->u.symbol->name);
		break;
	    case Variable:
		wsprintf(buffer, "Store Var %s", cur->u.symbol->name);
		break;
	    case Inst:
		wsprintf(buffer, "Store Inst %s", cur->u.symbol->name);
		break;
	    default:
		strcpy(buffer, "Store xxx");
		break;
	    }
	    break;
	case Push:
	    switch (cur->oper) {
	    case Super:
	    case Self:
		strcpy(buffer, "Push Self");
		break;
	    case True:
		strcpy(buffer, "Push True");
		break;
	    case False:
		strcpy(buffer, "Push False");
		break;
	    case Nil:
		strcpy(buffer, "Push Nil");
		break;
	    case Temp:
		wsprintf(buffer, "Push Temp %s", cur->u.symbol->name);
		break;
	    case Inst:
		wsprintf(buffer, "Push Inst %s", cur->u.symbol->name);
		break;
	    case Arg:
		wsprintf(buffer, "Push Arg %s", cur->u.symbol->name);
		break;
	    case Literal:
		wsprintf(buffer, "Push Lit %s",
			 dump_object_value(cur->u.literal->value));
		break;
	    case Variable:
		wsprintf(buffer, "Push Var %s", cur->u.symbol->name);
		break;
	    default:
		strcpy(buffer, "Push xxx");
		break;
	    }
	    break;
	case Duplicate:
	    strcpy(buffer, "Dup");
	    break;
	case PopStack:
	    strcpy(buffer, "Pop");
	    break;
	case Break:
	    strcpy(buffer, "Break");
	    break;
	case Return:
	    switch (cur->oper) {
	    case Self:
	        strcpy(buffer, "Ret Self");
		break;
	    case True:
	        strcpy(buffer, "Ret True");
		break;
	    case False:
	        strcpy(buffer, "Ret False");
		break;
	    case Nil:
	        strcpy(buffer, "Ret Nil");
		break;
	    case Temp:
		wsprintf(buffer, "Ret Temp %s", cur->u.symbol->name);
		break;
	    case Stack:
	        strcpy(buffer, "Ret TOS");
		break;
	    case Block:
	        strcpy(buffer, "Ret Blk");
		break;
	    default:
	        strcpy(buffer, "Ret xxx");
		break;
	    }
	    break;
	case SuperSend:
	    wsprintf(buffer, "Send Sup %d %s", cur->argcount,
		 dump_object_value(cur->u.literal->value));
	    break;
	case Send:
	    wsprintf(buffer, "Send Lit %d %s", cur->argcount,
		 dump_object_value(cur->u.literal->value));
	    break;
	case SendSpec:
	    wsprintf(buffer, "Send Spc %d %d", cur->argcount, cur->u.operand);
	    break;
	case JTrue:
	    wsprintf(buffer, "Jmp True %x", cur->u.jump);
	    break;
	case JFalse:
	    wsprintf(buffer, "Jmp False %x", cur->u.jump);
	    break;
	case Jump:
	    wsprintf(buffer, "Jump %x", cur->u.jump);
	    break;
	case BlockCopy:
	    wsprintf(buffer, "BlkCpy %d %x", cur->argcount, cur->u.jump);
	    break;
	default:
	    break;
	}
	ref = (cur->flags & CODE_LABEL)? '*': ' ';
        wsprintf(line, "%x: %c%s", cur, ref, buffer);
        dump_string(line);
    }
}
#endif


