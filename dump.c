
/*
 * Smalltalk interpreter: Object space dump utilities.
 *
 * $Log: dump.c,v $
 * Revision 1.8  2001/08/18 16:17:01  rich
 * Moved system error routines to system.h
 *
 * Revision 1.7  2001/08/01 16:42:31  rich
 * Added Pshint instruction.
 * Moved sendsuper to group 2.
 * Added psh context instruction.
 *
 * Revision 1.6  2001/07/31 14:09:48  rich
 * Fixed to compile under new cygwin.
 *
 * Revision 1.5  2001/01/17 00:28:17  rich
 * Added display of Float class.
 *
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
"$Id: dump.c,v 1.8 2001/08/18 16:17:01 rich Exp rich $";

#endif

/* System stuff */
#include "smalltalk.h"
#include "object.h"
#include "smallobjs.h"
#include "system.h"
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

    sprintf(buffer, "#%d (", class);
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
	sprintf(buffer, "Integer %d", as_integer(op));
	return buffer;
    }
    if (!notFree(op)) {
	sprintf(buffer, "***FREE OBJECT %d*****", as_integer(op));
	return buffer;
    }
    class = class_of(op);
    sprintf(buffer, "#%d ", op);
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
	    sprintf(buffer, "#%d Character $%c", op, value);
	else
	    sprintf(buffer, "#%d Character $0x%02x", op, value);
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
	sprintf(&buffer[len], "Float %f", *fval);
	break;
    default:
	sprintf(buffer, "#%d -> Class #%d (", op, class);
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
	    sprintf(buffer, "#%d (%d%s%s%s) %s %d",
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
	sprintf(buffer, "integer %d", as_integer(op));
	dump_string(buffer);
	return;
    }

    if (notFree(op)) {
	sprintf(buffer, "#%d (%d%s%s%s) %s %d [",
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
	    sprintf(buffer, "   v %d = %s", i, dump_object_value(o));
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
		    sprintf(buffer, "    [%d] = %02x", i,
			     get_byte(op, i + base));
		    dump_string(buffer);
		}
		dump_string(")");
	    } else if (is_word(op)) {
		dump_string("(");
		base /= sizeof(Objptr);
		for (i = 0; i < len; i++) {
		    sprintf(buffer, "    [%d] = %8x", i,
			     get_pointer(op, i + base));
		    dump_string(buffer);
		}
		dump_string(")");
	    } else {
		dump_string("(");
		base /= sizeof(Objptr);
		for (i = 0; i < len; i++) {
		    sprintf(buffer, "     %d = %s", i,
			   dump_object_value(get_pointer(op, i + base)));
		    dump_string(buffer);
		}
		dump_string(")");
	    }
	    dump_string("]");
	}
    } else {
	sprintf(buffer, "#%d free", op);
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
    sprintf(buffer, "%08x Flag %d, Lits %d Stack %d Temps %d",
    header, 0xf & FlagOf(header), lits, StackOf(header), TempsOf(header));
    dump_string(buffer);
    if (FlagOf(header) == METH_EXTEND) {
	ehdr = get_pointer(op, METH_HEADER + lits);
	sprintf(buffer, " %08x Extended: Args %d, Primitive %d",
		 ehdr, EArgsOf(ehdr), PrimitiveOf(ehdr));
	dump_string(buffer);
	lits--;
    }
   /* Dump literals */
    for (i = 0; i < lits; i++) {
	sprintf(buffer, " Lit #%d: %s", i,
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
		sprintf(opc, "j %d", operand + lits);
		len = 3;
		break;
	    }
	    if (operand == BLKCPY) {
	    	operand = 0xff & get_byte(op, lits + i + 1);
		sprintf(opc, "blk %d", operand);
		len = 2;
		break;
	    }
	    opcode = operand << 4;
    	    operand = 0xff & get_byte(op, lits + i + 1);
	    len++;
	    goto loop;
	case PSHARG:
	    sprintf(opc, "psh arg(%d)", operand);
	    break;
	case PSHLIT:
	    sprintf(opc, "psh lit(%d)", operand);
	    break;
	case PSHINST:
	    sprintf(opc, "psh ins(%d)", operand);
	    break;
	case PSHTMP:
	    sprintf(opc, "psh tmp(%d)", operand);
	    break;
	case PSHINT:
	    if (len == 1) {
		if (operand > 8)
		   operand -= 16;
	    } else {
		operand = get_byte(op, lits + i + 1); 
		if (operand > 127)
		   operand -= 256;
	    }
	    sprintf(opc, "psh int(%d)", operand);
	    break;
	case STRINST:
	    sprintf(opc, "str ins(%d)", operand);
	    break;
	case STRTMP:
	    sprintf(opc, "str tmp(%d)", operand);
	    break;
	case RETTMP:
	    sprintf(opc, "ret tmp(%d)", operand);
	    break;
	case JMPT:
	    if (len == 2) {
		operand = get_byte(op, lits + i + 1); 
		if (operand > 127)
		   operand -= 256;
	    }
	    sprintf(opc, "jpt Byte %d(%d)", i + len + operand + lits,
		     operand);
	    break;
	case JMPF:
	    if (len == 2) {
		operand = get_byte(op, lits + i + 1); 
		if (operand > 127)
		   operand -= 256;
	    }
	    sprintf(opc, "jpf Byte %d(%d)", i + len + operand + lits,
		     operand);
	    break;
	case JMP:
	    if (len == 2) {
		operand = get_byte(op, lits + i + 1); 
		if (operand > 127)
		   operand -= 256;
	    }
	    sprintf(opc, "jmp Byte %d(%d)", i + len + operand + lits,
		     operand);
	    break;

	case SNDSPC2:
	    operand += 16;
	case SNDSPC1:
	    sprintf(opc, "snd spc(%d, %d)", operand,
		     0xff & get_byte(op, lits + i + 1));
	    
	    operand = get_byte(op, lits + i + 1);
	    len = 2;
	    break;
	case SNDLIT:
	    sprintf(opc, "snd lit(%d, %d)", operand,
		     0xff & get_byte(op, lits + i + len++));
	    break;
	case GRP2:
	    switch (opcode) {
	    case RETSELF:
		sprintf(opc, "ret self");
		break;
	    case RETTOS:
		sprintf(opc, "ret top");
		break;
	    case RETTRUE:
		sprintf(opc, "ret true");
		break;
	    case RETFALS:
		sprintf(opc, "ret false");
		break;
	    case RETNIL:
		sprintf(opc, "ret nil");
		break;
	    case DUPTOS:
		sprintf(opc, "dup");
		break;
	    case RETBLK:
		sprintf(opc, "ret blk");
		break;
	    case POPSTK:
		sprintf(opc, "pop");
		break;
	    case PSHVAR:
		operand = 0xff & get_byte(op, lits + i + 1);
		sprintf(opc, "psh var(%d)", operand);
		len = 2;
		break;
	    case STRVAR:
		operand = 0xff & get_byte(op, lits + i + 1);
		sprintf(opc, "str var(%d)", operand);
		len = 2;
		break;
	    case PSHSELF:
		sprintf(opc, "psh self");
		break;
	    case PSHNIL:
		sprintf(opc, "psh nil");
		break;
	    case PSHTRUE:
		sprintf(opc, "psh true");
		break;
	    case PSHFALS:
		sprintf(opc, "psh false");
		break;
	    case PSHCTX:
		sprintf(opc, "psh ctx");
		break;
	    case SNDSUP:
		operand = 0xff & get_byte(op, lits + i + 1);
		len =  0xff & get_byte(op, lits + i + 2);
	        sprintf(opc, "sup snd(%d, %d)", operand, len);
		operand = (operand << 8) + len;
		len = 3;
	        break;
	    }
	}
	switch (len) {
	case 1:
   	    sprintf(buffer, " Byte %d: %02x      %s", i + lits, opcode, opc);
	    break;
 	case 2:
   	    sprintf(buffer, " Byte %d: %02x %02x   %s", i + lits, opcode,
			0xff & operand, opc);
	    break;
	case 3:
   	    sprintf(buffer, " Byte %d: %02x %04x %s", i + lits, opcode,
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
	sprintf(buffer, "{Name} %s", get_token_string(tstate));
	break;
    case KeyKeyword:
	sprintf(buffer, "{Keyword} %s", get_token_string(tstate));
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
	sprintf(buffer, "{Spec} %s", get_token_spec(tstate));
	break;
    case KeyRBrack:
	strcpy(buffer, "{[}");
	break;
    case KeyLBrack:
	strcpy(buffer, "{]}");
	break;
    case KeyVariable:
	sprintf(buffer, "{Var} %s", get_token_string(tstate));
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
	sprintf(opc, "psh arg: %d [%d]", oprand, oprand2);
	dumpflag = TRUE;
	break;
    case PSHLIT:
	sprintf(opc, "psh lit: %d [%d]", oprand, oprand2);
	dumpflag = TRUE;
	break;
    case PSHINST:
	sprintf(opc, "psh ins: %d [%d]", oprand, oprand2);
	dumpflag = TRUE;
	break;
    case PSHTMP:
	sprintf(opc, "psh tmp: %d [%d]", oprand, oprand2);
	dumpflag = TRUE;
	break;
    case PSHINT:
	sprintf(opc, "psh int: %d", oprand);
	break;
    case STRINST:
	sprintf(opc, "str ins: %d", oprand);
	dumpflag = TRUE;
	break;
    case STRTMP:
	sprintf(opc, "str tmp: %d", oprand);
	dumpflag = TRUE;
	break;
    case RETTMP:
	sprintf(opc, "ret tmp: %d", oprand);
	dumpflag = TRUE;
	break;
    case JMPT:
	sprintf(opc, "jpt %d", oprand);
	dumpflag = TRUE;
	break;
    case JMPF:
	sprintf(opc, "jpf %d", oprand);
	dumpflag = TRUE;
	break;
    case LONGOP:
	if (opcode == BLKCPY) {
	    sprintf(opc, "blk %d", oprand);
	    dumpflag = TRUE;
	    break;
	}
    case JMP:
	sprintf(opc, "jmp %d", oprand);
	break;

    case SNDSPC2:
    case SNDSPC1:
	sprintf(opc, "snd spc %d", oprand2);
	dumpflag = TRUE;
	break;
    case SNDLIT:
	sprintf(opc, "snd lit %d", oprand2);
	dumpflag = TRUE;
	break;
    case GRP2:
	switch (opcode & 0xff) {
	case RETSELF:
	    sprintf(opc, "ret self");
	    dumpflag = TRUE;
	    break;
	case RETTOS:
	    sprintf(opc, "ret top");
	    dumpflag = TRUE;
	    break;
	case RETTRUE:
	    sprintf(opc, "ret true");
	    break;
	case RETFALS:
	    sprintf(opc, "ret false");
	    break;
	case RETNIL:
	    sprintf(opc, "ret nil");
	    break;
	case DUPTOS:
	    sprintf(opc, "dup [%d]", oprand2);
	    dumpflag = TRUE;
	    break;
	case RETBLK:
	    sprintf(opc, "ret blk");
	    dumpflag = TRUE;
	    break;
	case POPSTK:
	    sprintf(opc, "pop");
	    break;
	case PSHVAR:
	    sprintf(opc, "psh var [%d]", oprand2);
	    dumpflag = TRUE;
	    break;
	case STRVAR:
	    sprintf(opc, "str var");
	    dumpflag = TRUE;
	    break;
	case PSHSELF:
	    sprintf(opc, "psh self [%d]", oprand2);
	    dumpflag = TRUE;
	    break;
	case PSHNIL:
	    sprintf(opc, "psh nil [%d]", oprand2);
	    break;
	case PSHTRUE:
	    sprintf(opc, "psh true [%d]", oprand2);
	    break;
	case PSHFALS:
	    sprintf(opc, "psh false [%d]", oprand2);
	    break;
	case PSHCTX:
	    sprintf(opc, "psh [%d]", oprand2);
	    break;
	case SNDSUP:
	    sprintf(opc, "sup snd %d", oprand2);
	    dumpflag = TRUE;
	    break;
	}
    }
    if (dumpflag)
	sprintf(buffer, "#%d Exec: %d %02x %s %s", meth, ip, opcode, opc,
		 dump_object_value(op));
    else
	sprintf(buffer, "#%d Exec: %d %02x %s", meth, ip, opcode, opc);
    dump_string(buffer);
}
/*
 * Dump set instance variable.
 */
void 
dump_setinst(Objptr op, int inst, Objptr value)
{
    char                buffer[1024];

    sprintf(buffer, "Set: %s [%d] to ", dump_object_value(op), inst);
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

    sprintf(buffer, "Get: %s [%d] is ", dump_object_value(op), inst);
    strcat(buffer, dump_object_value(value));
    dump_string(buffer);
}
#endif


#ifdef TRACE_SEND
/*
 * Report on success or failure of a primitive.
 */
void
dump_primitive(int flag, int number)
{
   char			buffer[1024];
   sprintf(buffer, "Primitive: %d ", number);
   strcat(buffer, (flag)?"Success":"Failed");
   dump_string(buffer);
}

/*
 * Dump message send information.
 */
void 
dump_send(Objptr op, Objptr sel, Objptr meth)
{
    char                buffer[1024];

    sprintf(buffer, "Send: to %s sel ", dump_object_value(op));
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

    sprintf(buffer, "%s #%d", str, op);
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
		sprintf(buffer, "Store Temp %s", cur->u.symbol->name);
		break;
	    case Variable:
		sprintf(buffer, "Store Var %s", cur->u.symbol->name);
		break;
	    case Inst:
		sprintf(buffer, "Store Inst %s", cur->u.symbol->name);
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
		sprintf(buffer, "Push Temp %s", cur->u.symbol->name);
		break;
	    case Inst:
		sprintf(buffer, "Push Inst %s", cur->u.symbol->name);
		break;
	    case Arg:
		sprintf(buffer, "Push Arg %s", cur->u.symbol->name);
		break;
	    case Literal:
		sprintf(buffer, "Push Lit %s",
			 dump_object_value(cur->u.literal->value));
		break;
	    case Variable:
		sprintf(buffer, "Push Var %s", cur->u.symbol->name);
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
		sprintf(buffer, "Ret Temp %s", cur->u.symbol->name);
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
	    sprintf(buffer, "Send Sup %d %s", cur->argcount,
		 dump_object_value(cur->u.literal->value));
	    break;
	case Send:
	    sprintf(buffer, "Send Lit %d %s", cur->argcount,
		 dump_object_value(cur->u.literal->value));
	    break;
	case SendSpec:
	    sprintf(buffer, "Send Spc %d %d", cur->argcount, cur->u.operand);
	    break;
	case JTrue:
	    sprintf(buffer, "Jmp True %x", cur->u.jump);
	    break;
	case JFalse:
	    sprintf(buffer, "Jmp False %x", cur->u.jump);
	    break;
	case Jump:
	    sprintf(buffer, "Jump %x", cur->u.jump);
	    break;
	case BlockCopy:
	    sprintf(buffer, "BlkCpy %d %x", cur->argcount, cur->u.jump);
	    break;
	default:
	    break;
	}
	ref = (cur->flags & CODE_LABEL)? '*': ' ';
        sprintf(line, "%x: %c%s", cur, ref, buffer);
        dump_string(line);
    }
}
#endif


