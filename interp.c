/*
 * Smalltalk interpreter: Main byte code interpriter.
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
 * $Log: interp.c,v $
 * Revision 1.8  2001/08/29 20:16:35  rich
 * Initialize async event queue in InitSystem
 *
 * Revision 1.7  2001/08/18 16:17:01  rich
 * Fixed process management code.
 * Added queue functions to improve communications from system to image.
 *
 * Revision 1.6  2001/08/01 16:42:31  rich
 * Added Pshint instruction.
 * Moved sendsuper to group 2.
 * Added psh context instruction.
 * Enabled process scheduling.
 * Moved checkProcessSwitch to sendmethod.
 *
 * Revision 1.5  2001/07/31 14:09:48  rich
 * Fixed to compile under new cygwin.
 * Added method to flush a method out of cache if removeing it.
 *
 * Revision 1.4  2001/01/17 01:46:17  rich
 * Added routine to flush method cache.
 * Added routine to send an error message.
 * Temporiarly commented out process scheduling.
 *
 * Revision 1.3  2000/03/03 00:23:52  rich
 * Moved recurseError to a functions.
 * Moved dump_stack here.
 * Return Temp gets temps from home context not current context.
 *
 * Revision 1.2  2000/02/01 18:09:53  rich
 * Tracing now controlled in dump.h
 * Added stack checking code to push, pop and send.
 * Added stack display to push instructions.
 * Reload methodPointer after a object create or send.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#ifndef lint
static char        *rcsid =
"$Id: interp.c,v 1.8 2001/08/29 20:16:35 rich Exp rich $";

#endif

#include "smalltalk.h"
#include "object.h"
#include "smallobjs.h"
#include "interp.h"
#include "primitive.h"
#include "dump.h"
#include "system.h"

method_Cache        methodCache[1024];
int                 newProcessWaiting = 0;
Objptr              newProcess;
event_queue         asyncsigs;
Objptr              current_context;
int                 running;
int                 compiling;
int                 newContextFlag = 0; 

static INLINE Objptr lookupMethodInClass(Objptr, Objptr, int *, int *);
static INLINE void   return_Object(Objptr, Objptr);
static void          init_method_cache();

/*
 * Initialize the method cache before we run anything.
 */
static void
init_method_cache()
{
    int                 i;

   /* Clear Method Cache */
    for (i = 0; i < (sizeof(methodCache) / sizeof(method_Cache)); i++) {
	methodCache[i].select = NilPtr;
	methodCache[i].class = NilPtr;
	methodCache[i].method = NilPtr;
	methodCache[i].header = NilPtr;
    }
}

/*
 * Flush the method cache of a given selector.
 */
void
flushCache(Objptr sel)
{
    int                 i;

   /* Clear Method Cache */
    for (i = 0; i < (sizeof(methodCache) / sizeof(method_Cache)); i++) {
        if (sel == NilPtr || sel == methodCache[i].select) {
	    methodCache[i].select = NilPtr;
	    methodCache[i].class = NilPtr;
	    methodCache[i].method = NilPtr;
	    methodCache[i].header = NilPtr;
	}
    }
}

/*
 * Flush the method cache of a given method.
 */
void
flushMethod(Objptr meth)
{
    int                 i;

   /* Clear Method Cache */
    for (i = 0; i < (sizeof(methodCache) / sizeof(method_Cache)); i++) {
        if (meth == NilPtr || meth == methodCache[i].method) {
	    methodCache[i].select = NilPtr;
	    methodCache[i].class = NilPtr;
	    methodCache[i].method = NilPtr;
	    methodCache[i].header = NilPtr;
	}
    }
}


/*
 * Dump out a error message, when we get stuck in a loop trying to send
 * a message and we can't find DoesNotUnderstand selector in class chain.
 * This is a fatal error since there is nothing else we can do since we
 * got here trying to send a selector we don't know about and then could
 * not find DoesNotUnderstand selector either.
 */
static void
recurseError(Objptr class, Objptr selector)
{
    char		buf[1024];

    strcpy(buf, dump_class_name(class));
    strcat(buf, ":");
    strcat(buf, dump_object_value(selector));
    strcat(buf, " Recurisive not understood error encountered");
    error(buf);
}

/*
 * Helper function to send a selector to object on top of stack.
 */
void
SendError(Objptr selector, int *stack)
{
	SendMethod(selector, stack, 0);
}

/*
 * Lookup a method in a class tree, if not found, Send not found message.
 */
static INLINE       Objptr
lookupMethodInClass(Objptr class, Objptr selector, int *stack_pointer,
		    int *args)
{
    Objptr              currentClass;
    Objptr              argarr;
    Objptr              msg;
    Objptr              dict;
    Objptr              res;
    int                 i;
    Objptr		oselector = selector;

   /* Look up class chain */
    for (currentClass = class;
	 currentClass != NilPtr;
	 currentClass = get_pointer(currentClass, SUPERCLASS)) {
	if ((dict = get_pointer(currentClass, METHOD_DICT)) != NilPtr &&
	    (res = FindSelectorInIDictionary(dict, selector)) != NilPtr)
	    return res;
    }

   /* Did not find it, build error message */
    msg = create_new_object(MessageClass, 0);
    rootObjects[ERRORSEL] = msg;
    Set_object(msg, MESSAGE_SELECT, selector);
    argarr = create_new_object(ArrayClass, *args);
    Set_object(msg, MESSAGE_ARGS, argarr);
    for (i = 0; i < *args; i++) {
	Set_object(argarr, i, get_pointer(current_context, *stack_pointer + i));
	Set_object(current_context, *stack_pointer + i, NilPtr);
    }
    *stack_pointer += *args;
    *args = 1;
    Set_object(current_context, --(*stack_pointer), msg);
    rootObjects[ERRORSEL] = NilPtr;
    selector = DoesNotUnderstandSelector;

   /* Look up class chain */
    for (currentClass = class;
	 currentClass != NilPtr;
	 currentClass = get_pointer(currentClass, SUPERCLASS)) {
	if ((dict = get_pointer(currentClass, METHOD_DICT)) != NilPtr &&
	    (res = FindSelectorInIDictionary(dict, selector)) != NilPtr)
	    return res;
    }

   /* Not found... if it is DoesNotUnderstandSelector, error our */
    running = 0;
    recurseError(class, oselector);
    return NilPtr;
}


/*
 * Return an object to a sender.
 *      if there is no sender, we send a error message.
 *      clear stack of returned method.
 *      Then push value onto returned stack.
 *      Lastly, clear out current context stack.
 */
static INLINE void
return_Object(Objptr value, Objptr caller)
{
    int                 sstack;
    int                 args;
    Objptr              prev;

   /* Find out who original sender was. */
    for (prev = current_context;
	 caller != get_pointer(prev, BLOCK_CALLER);
	 prev = get_pointer(prev, BLOCK_CALLER)) ;

    sstack = get_integer(caller, BLOCK_SP);
    object_incr_ref(value);	/* Mark value so it does not get freed */

   /* Remove arguments, if original sender was a methodContext */
    if (get_integer(prev, BLOCK_IIP) == 0)
	for (args = get_integer(prev, BLOCK_ARGCNT); args >= 0; args--)
	    Set_object(caller, sstack++, NilPtr);

   /* Push return value */
    Set_object(caller, --sstack, value);
    Set_integer(caller, BLOCK_SP, sstack);
    object_decr_ref(value);	/* Value now safe */

   /* Clear out old frame */
    object_incr_ref(caller);	/* Mark caller so it does not get freed */
    Set_object(current_context, BLOCK_SENDER, NilPtr);

    object_decr_ref(current_context);	/* Caller is now safe from removal */
   /* Mark caller as current */
    rootObjects[CURCONT] = current_context = caller;
    checkProcessSwitch();
}

/*
 * Send a message to a class.
 */
void
SendToClass(Objptr selector, int *stack_pointer, int args, Objptr newClass)
{
    Objptr              newMethod;
    Objptr              reciever;
    int                 hash;
    int                 newHeader;
    int                 literals;
    int                 temps;
    int                 stacksize;
    Objptr              value;
    Objptr              newContext;

   /* Locate method */
    hash = (selector & newClass) % (sizeof(methodCache) / sizeof(method_Cache));
    if (methodCache[hash].select == selector &&
	methodCache[hash].class == newClass) {
	newMethod = methodCache[hash].method;
    } else {
	newMethod = lookupMethodInClass(newClass, selector, stack_pointer,
					&args);
	if (newMethod == NilPtr) {
	    running = 0;
	    return;
	}
	methodCache[hash].select = selector;
	methodCache[hash].class = newClass;
	methodCache[hash].method = newMethod;
	methodCache[hash].header = get_pointer(newMethod, METH_HEADER);
    }

   /* Grab header information */
    reciever = get_pointer(current_context, *stack_pointer + args);
    trace_send(reciever, selector, newMethod);
    newHeader = methodCache[hash].header;
    literals = LiteralsOf(newHeader);
    temps = TempsOf(newHeader);

   /* Check type of method */
    switch (FlagOf(newHeader)) {
    case METH_RETURN:
	value = get_pointer(reciever, temps);
	Set_object(current_context, *stack_pointer, value);
	trace_getinst(reciever, temps, value);
	return;
    case METH_SETINST:
	value = get_pointer(current_context, *stack_pointer);
	Set_object(reciever, temps, value);
	Set_object(current_context, (*stack_pointer)++, NilPtr);
       /* Return is value */
	Set_object(current_context, *stack_pointer, value);
	trace_setinst(reciever, temps, value);
	return;
    case METH_EXTEND:
	value = get_pointer(newMethod, literals + METH_HEADER);
	value = PrimitiveOf(value);
	if (value > 0 &&
	    primitive(value, reciever, newClass, args, stack_pointer)) {
	    trace_primitive(TRUE, value);
	    return;
	}
	trace_primitive(FALSE, value);
	break;
    default:
	break;
    }
    stacksize = StackOf(newHeader) + temps;

   /* Initialize a new method. */
    newContext = create_new_object(MethodContextClass, stacksize);
    Set_object(newContext, BLOCK_SENDER, current_context);
    Set_integer(newContext, BLOCK_IP, sizeof(Objptr) *
		(literals + METH_LITSTART));
    Set_integer(newContext, BLOCK_SP, size_of(newContext) / sizeof(Objptr));
    Set_object(newContext, BLOCK_METHOD, newMethod);
    Set_integer(newContext, BLOCK_IIP, 0);
    Set_object(newContext, BLOCK_REC, reciever);
    Set_integer(newContext, BLOCK_ARGCNT, args);
    current_context = newContext;
    newContextFlag = 1; 
    checkProcessSwitch();
    return;
}


/*
 * Do a stack trace back of offending send.
 */
void
dump_stack(Objptr op)
{
    char		buffer[4096];
    Objptr		context = current_context;

    context = get_pointer(context, BLOCK_SENDER);
    while (context != NilPtr) {
	Objptr		rec, meth, class, dict;
	Objptr		select = NilPtr;

	/* Figure out info about call */
	if (get_integer(context, BLOCK_IIP) != 0) {
	    Objptr	home = get_pointer(context, BLOCK_HOME);
	    rec = get_pointer(home, BLOCK_REC);
	    meth = get_pointer(home, BLOCK_METHOD);
	    strcpy(buffer, "Block: ");
	} else  {
	    rec = get_pointer(context, BLOCK_REC);
	    meth = get_pointer(context, BLOCK_METHOD);
	    strcpy(buffer, "Method: ");
	}

	/* Find method name */
	for (class = class_of(rec);
	     class != NilPtr;
	     class = get_pointer(class, SUPERCLASS)) {
	  if ((dict = get_pointer(class, METHOD_DICT)) != NilPtr &&
	      (select = FindKeyInIDictionary(dict, meth)) != NilPtr)
	     break;
	}

	/* Sanity check */
	if (select == NilPtr)
	   break;
	strcat(buffer, dump_object_value(rec));
	strcat(buffer, " Selector: ");
	strcat(buffer, dump_object_value(select));
	dump_string(buffer);
        context = get_pointer(context, BLOCK_SENDER);
    }
}

/*
 * Execute a method.
 */
void
execute(Objptr meth, Objptr rec)
{
    Objptr		newContext;
    int			header;
    int			stacksize;
//    int			oldrunning = running;

    header = get_pointer(meth, METH_HEADER);
    stacksize = StackOf(header) + TempsOf(header);

    /* Initialize a new method. */
    newContext = create_new_object(MethodContextClass, stacksize);
    object_incr_ref(newContext);
    rootObjects[CURCONT] = newContext;
    Set_object(newContext, BLOCK_SENDER, NilPtr);
    Set_integer(newContext, BLOCK_IP, 
	sizeof(Objptr) *(LiteralsOf(header) + METH_LITSTART));
    Set_integer(newContext, BLOCK_SP, size_of(newContext) / sizeof(Objptr));
    Set_object(newContext, BLOCK_METHOD, meth);
    Set_integer(newContext, BLOCK_IIP, 0);
    Set_object(newContext, BLOCK_REC, rec);
    Set_integer(newContext, BLOCK_ARGCNT, 0);
    current_context = newContext;
    newContextFlag = 1;
    /* Ok we have a refernce to method, we can clear out holder */
    rootObjects[TEMP1] = NilPtr;
    interp();
    /* Break cycle */
    Set_object(newContext, BLOCK_SENDER, NilPtr);
    object_decr_ref(newContext);
 //   running = oldrunning;
}

/*
 * Main byte code interpreture. Only exit is on shutdown.
 */
void
interp()
{
    unsigned char      *methodPointer = NULL;
    Objptr              old_context = NilPtr;
    int                 instruct_pointer = 0;
    int                 stack_pointer = 0;
    int			stack_top = 0;		/* Top of stack */
    int                 reciever = 0;
    int                 opcode;
    int                 oprand;
    int                 argc;
    int                 tstack;			/* Place to save stack */
    Objptr              value, temp;
    Objptr              caller = NilPtr;
    Objptr              sender = NilPtr;
    Objptr              home = NilPtr;
    Objptr              meth = NilPtr;

    running = TRUE;

   /* Clear Method Cache */
    init_method_cache();

   /* Force a load */
    newContextFlag = 1;
    old_context = NilPtr;
    while (running) {
	if (old_context != current_context) {

	    if (newContextFlag && old_context != NilPtr) {
		Set_integer(old_context, BLOCK_SP, stack_pointer);
		Set_integer(old_context, BLOCK_IP, instruct_pointer);
		object_decr_ref(old_context);
	    }
	    rootObjects[CURCONT] = current_context;
	    old_context = current_context;
	    object_incr_ref(current_context);
	    caller = get_pointer(current_context, BLOCK_SENDER);
	   /* Check for in a block context or not */
	    if (GetInteger(BLOCK_IIP) == 0)
		home = current_context;
	    else
		home = get_pointer(current_context, BLOCK_HOME);
	    sender = get_pointer(home, BLOCK_SENDER);
	    reciever = get_pointer(home, BLOCK_REC);
	    meth = get_pointer(home, BLOCK_METHOD);
	    methodPointer = get_object_base(meth);
	    stack_pointer = GetInteger(BLOCK_SP);
	    instruct_pointer = GetInteger(BLOCK_IP);
	    stack_top = size_of(current_context) / sizeof(Objptr);
	    newContextFlag = 0;
	}
	opcode = methodPointer[instruct_pointer++];
	oprand = opcode & 0xf;
	switch (opcode) {
	case BLKCPY:
	   /* Block copy */
	    argc = methodPointer[instruct_pointer++];
	   /* Next instruct has to be a jump, so do it. */
	    opcode = methodPointer[instruct_pointer++];
	    oprand = opcode & 0xf;
	    if (opcode == JMPLNG) {
	        oprand = methodPointer[instruct_pointer++];
	        oprand += methodPointer[instruct_pointer++] << 8;
	        if (oprand > 32768)
		    oprand -= 65536;
	    } else if (opcode == (JMP >> 4)) {
	        oprand = methodPointer[instruct_pointer++];
	        if (oprand > 127)
		    oprand -= 256;
	    }

	   /* Build block */
	    temp = create_new_object(BlockContextClass,
				     length_of(current_context));
	    methodPointer = get_object_base(meth);
	    Set_integer(temp, BLOCK_IP, 0);
	    Set_integer(temp, BLOCK_SP, size_of(temp) / sizeof(Objptr));
	    Set_object(temp, BLOCK_HOME, home);
	    Set_integer(temp, BLOCK_IIP, instruct_pointer);
	/*    Set_object(temp, BLOCK_REC, reciever); */
	    Set_integer(temp, BLOCK_ARGCNT, argc);
	    Push(temp);
	    trace_inst(meth, instruct_pointer, BLKCPY, argc, temp, 0);

	   /* Jump to next instuction */
	    trace_inst(meth, instruct_pointer, JMP, oprand, NilPtr, 0);
	    instruct_pointer += oprand;
	    break;
	case JMPLNG:
	    oprand = methodPointer[instruct_pointer++];
	    oprand += methodPointer[instruct_pointer++] << 8;
	    if (oprand > 32768)
		oprand -= 65536;
	    trace_inst(meth, instruct_pointer, opcode, oprand, NilPtr, 0);
	    instruct_pointer += oprand;
	    break;

	case PSHARG >> 4:
	    oprand = methodPointer[instruct_pointer++];
	case PSHARG + 0x0:
	case PSHARG + 0x1:
	case PSHARG + 0x2:
	case PSHARG + 0x3:
	case PSHARG + 0x4:
	case PSHARG + 0x5:
	case PSHARG + 0x6:
	case PSHARG + 0x7:
	case PSHARG + 0x8:
	case PSHARG + 0x9:
	case PSHARG + 0xa:
	case PSHARG + 0xb:
	case PSHARG + 0xc:
	case PSHARG + 0xd:
	case PSHARG + 0xe:
	case PSHARG + 0xf:
	   /* Arguments are in reverse order on stack */
	    trace_inst(meth, instruct_pointer, PSHARG, oprand,
		 get_pointer(sender, (get_integer(sender, BLOCK_SP) - 1) +
		 (get_integer(home, BLOCK_ARGCNT) - oprand)), stack_pointer);
	    Push(get_pointer(sender,
			     (get_integer(sender, BLOCK_SP) - 1) +
			     (get_integer(home, BLOCK_ARGCNT) - oprand)));
	    break;

	case PSHLIT >> 4:
	    oprand = methodPointer[instruct_pointer++];
	case PSHLIT + 0x0:
	case PSHLIT + 0x1:
	case PSHLIT + 0x2:
	case PSHLIT + 0x3:
	case PSHLIT + 0x4:
	case PSHLIT + 0x5:
	case PSHLIT + 0x6:
	case PSHLIT + 0x7:
	case PSHLIT + 0x8:
	case PSHLIT + 0x9:
	case PSHLIT + 0xa:
	case PSHLIT + 0xb:
	case PSHLIT + 0xc:
	case PSHLIT + 0xd:
	case PSHLIT + 0xe:
	case PSHLIT + 0xf:
	    trace_inst(meth, instruct_pointer, PSHLIT, oprand, Literal(oprand),
			 stack_pointer);
	    Push(Literal(oprand));
	    break;

	case PSHINST >> 4:
	    oprand = methodPointer[instruct_pointer++];
	case PSHINST + 0x0:
	case PSHINST + 0x1:
	case PSHINST + 0x2:
	case PSHINST + 0x3:
	case PSHINST + 0x4:
	case PSHINST + 0x5:
	case PSHINST + 0x6:
	case PSHINST + 0x7:
	case PSHINST + 0x8:
	case PSHINST + 0x9:
	case PSHINST + 0xa:
	case PSHINST + 0xb:
	case PSHINST + 0xc:
	case PSHINST + 0xd:
	case PSHINST + 0xe:
	case PSHINST + 0xf:
	    trace_inst(meth, instruct_pointer, PSHINST, oprand,
			 get_pointer(reciever, oprand), stack_pointer);
	    Push(get_pointer(reciever, oprand));
	    break;

	case PSHTMP >> 4:
	    oprand = methodPointer[instruct_pointer++];
	case PSHTMP + 0x0:
	case PSHTMP + 0x1:
	case PSHTMP + 0x2:
	case PSHTMP + 0x3:
	case PSHTMP + 0x4:
	case PSHTMP + 0x5:
	case PSHTMP + 0x6:
	case PSHTMP + 0x7:
	case PSHTMP + 0x8:
	case PSHTMP + 0x9:
	case PSHTMP + 0xa:
	case PSHTMP + 0xb:
	case PSHTMP + 0xc:
	case PSHTMP + 0xd:
	case PSHTMP + 0xe:
	case PSHTMP + 0xf:
	    trace_inst(meth, instruct_pointer, PSHTMP, oprand,
		       get_pointer(home, oprand + BLOCK_STACK), stack_pointer);
	    Push(get_pointer(home, oprand + BLOCK_STACK));
	    break;

	case PSHINT >> 4:
	    oprand = methodPointer[instruct_pointer++];
	    if (oprand > 127)
		oprand -= 256;
	    trace_inst(meth, instruct_pointer, opcode, oprand, NilPtr, stack_pointer);
	    Push(as_integer_object(oprand));
	    break;

	case PSHINT + 0x8:
	case PSHINT + 0x9:
	case PSHINT + 0xa:
	case PSHINT + 0xb:
	case PSHINT + 0xc:
	case PSHINT + 0xd:
	case PSHINT + 0xe:
	case PSHINT + 0xf:
	     oprand -= 16;

	case PSHINT + 0x0:
	case PSHINT + 0x1:
	case PSHINT + 0x2:
	case PSHINT + 0x3:
	case PSHINT + 0x4:
	case PSHINT + 0x5:
	case PSHINT + 0x6:
	case PSHINT + 0x7:
	    trace_inst(meth, instruct_pointer, opcode, oprand, NilPtr, stack_pointer);
	    Push(as_integer_object(oprand));
	    break;

	case STRINST >> 4:
	    oprand = methodPointer[instruct_pointer++];
	case STRINST + 0x0:
	case STRINST + 0x1:
	case STRINST + 0x2:
	case STRINST + 0x3:
	case STRINST + 0x4:
	case STRINST + 0x5:
	case STRINST + 0x6:
	case STRINST + 0x7:
	case STRINST + 0x8:
	case STRINST + 0x9:
	case STRINST + 0xa:
	case STRINST + 0xb:
	case STRINST + 0xc:
	case STRINST + 0xd:
	case STRINST + 0xe:
	case STRINST + 0xf:
	    trace_inst(meth, instruct_pointer, STRINST, oprand, TopStack(), 0);
	    Set_object(reciever, oprand, TopStack());
	    PopStack();
	    break;

	case STRTMP >> 4:
	    oprand = methodPointer[instruct_pointer++];
	case STRTMP + 0x0:
	case STRTMP + 0x1:
	case STRTMP + 0x2:
	case STRTMP + 0x3:
	case STRTMP + 0x4:
	case STRTMP + 0x5:
	case STRTMP + 0x6:
	case STRTMP + 0x7:
	case STRTMP + 0x8:
	case STRTMP + 0x9:
	case STRTMP + 0xa:
	case STRTMP + 0xb:
	case STRTMP + 0xc:
	case STRTMP + 0xd:
	case STRTMP + 0xe:
	case STRTMP + 0xf:
	    trace_inst(meth, instruct_pointer, STRTMP, oprand, TopStack(), 0);
	    Set_object(home, oprand + BLOCK_STACK, TopStack());
	    PopStack();
	    break;

	case JMPT >> 4:
	    oprand = methodPointer[instruct_pointer++];
	case JMPT + 0x0:
	case JMPT + 0x1:
	case JMPT + 0x2:
	case JMPT + 0x3:
	case JMPT + 0x4:
	case JMPT + 0x5:
	case JMPT + 0x6:
	case JMPT + 0x7:
	case JMPT + 0x8:
	case JMPT + 0x9:
	case JMPT + 0xa:
	case JMPT + 0xb:
	case JMPT + 0xc:
	case JMPT + 0xd:
	case JMPT + 0xe:
	case JMPT + 0xf:
	    value = TopStack();
	    if (oprand > 127)
		oprand -= 256;
	    trace_inst(meth, instruct_pointer, JMPT, oprand, value, 0);
	    if (value == TruePointer) {
		instruct_pointer += oprand;
	    } else if (value != FalsePointer) {
	        tstack = stack_pointer;
		SendError(MustBeBooleanSelector, &tstack);
	        stack_pointer = tstack;
		break;
	    }
	    PopStack();
	    break;

	case JMPF >> 4:
	    oprand = methodPointer[instruct_pointer++];
	case JMPF + 0x0:
	case JMPF + 0x1:
	case JMPF + 0x2:
	case JMPF + 0x3:
	case JMPF + 0x4:
	case JMPF + 0x5:
	case JMPF + 0x6:
	case JMPF + 0x7:
	case JMPF + 0x8:
	case JMPF + 0x9:
	case JMPF + 0xa:
	case JMPF + 0xb:
	case JMPF + 0xc:
	case JMPF + 0xd:
	case JMPF + 0xe:
	case JMPF + 0xf:
	    value = TopStack();
	    if (oprand > 127)
		oprand -= 256;
	    trace_inst(meth, instruct_pointer, JMPF, oprand, value, 0);
	    if (value == FalsePointer) {
		instruct_pointer += oprand;
	    } else if (value != TruePointer) {
	        tstack = stack_pointer;
		SendError(MustBeBooleanSelector, &tstack);
	        stack_pointer = tstack;
		break;
	    }
	    PopStack();
	    break;

	case JMP >> 4:
	    oprand = methodPointer[instruct_pointer++];
	case JMP + 0x0:
	case JMP + 0x1:
	case JMP + 0x2:
	case JMP + 0x3:
	case JMP + 0x4:
	case JMP + 0x5:
	case JMP + 0x6:
	case JMP + 0x7:
	case JMP + 0x8:
	case JMP + 0x9:
	case JMP + 0xa:
	case JMP + 0xb:
	case JMP + 0xc:
	case JMP + 0xd:
	case JMP + 0xe:
	case JMP + 0xf:
	    trace_inst(meth, instruct_pointer, JMP, oprand, NilPtr, 0);
	    if (oprand > 127)
		oprand -= 256;
	    if (oprand == 0)
		running = FALSE;
	    else
		instruct_pointer += oprand;
	    break;

	case SNDSUP:
	    oprand = methodPointer[instruct_pointer++];
	   /* Grab class */
	    argc = LiteralsOf(((int *) methodPointer)[METH_HEADER]);
	    if (FlagOf(((int *) methodPointer)[METH_HEADER]) == METH_EXTEND)
		argc--;
	    temp = Literal(argc - 1);
	   /* Next grap selector number */
	    argc = methodPointer[instruct_pointer++];
	    tstack = stack_pointer;
	    trace_inst(meth, instruct_pointer, SNDSUP, oprand, Literal(oprand),
		 argc);
	    if ((stack_pointer + argc) >= stack_top)  {
		SendError(InterpStackFault, &tstack);
	    } else
	        SendToClass(Literal(oprand), &tstack, argc, temp);
	    methodPointer = get_object_base(meth);
	    stack_pointer = tstack;
	    break;

	case SNDLIT >> 4:
	    oprand = methodPointer[instruct_pointer++];
	case SNDLIT + 0x0:
	case SNDLIT + 0x1:
	case SNDLIT + 0x2:
	case SNDLIT + 0x3:
	case SNDLIT + 0x4:
	case SNDLIT + 0x5:
	case SNDLIT + 0x6:
	case SNDLIT + 0x7:
	case SNDLIT + 0x8:
	case SNDLIT + 0x9:
	case SNDLIT + 0xa:
	case SNDLIT + 0xb:
	case SNDLIT + 0xc:
	case SNDLIT + 0xd:
	case SNDLIT + 0xe:
	case SNDLIT + 0xf:
	    argc = methodPointer[instruct_pointer++];
	    trace_inst(meth, instruct_pointer, SNDLIT, oprand, Literal(oprand), 
			argc);
	    tstack = stack_pointer;
	    if ((stack_pointer + argc) >= stack_top)  {
		dump_stack(Literal(oprand));
		SendError(InterpStackFault, &tstack);
	    } else
	        SendMethod(Literal(oprand), &tstack, argc);
	    methodPointer = get_object_base(meth);
	    stack_pointer = tstack;
	    break;

	case SNDSPC2 + 0x0:
	case SNDSPC2 + 0x1:
	case SNDSPC2 + 0x2:
	case SNDSPC2 + 0x3:
	case SNDSPC2 + 0x4:
	case SNDSPC2 + 0x5:
	case SNDSPC2 + 0x6:
	case SNDSPC2 + 0x7:
	case SNDSPC2 + 0x8:
	case SNDSPC2 + 0x9:
	case SNDSPC2 + 0xa:
	case SNDSPC2 + 0xb:
	case SNDSPC2 + 0xc:
	case SNDSPC2 + 0xd:
	case SNDSPC2 + 0xe:
	case SNDSPC2 + 0xf:
	    oprand += 16;
	case SNDSPC1 + 0x0:
	case SNDSPC1 + 0x1:
	case SNDSPC1 + 0x2:
	case SNDSPC1 + 0x3:
	case SNDSPC1 + 0x4:
	case SNDSPC1 + 0x5:
	case SNDSPC1 + 0x6:
	case SNDSPC1 + 0x7:
	case SNDSPC1 + 0x8:
	case SNDSPC1 + 0x9:
	case SNDSPC1 + 0xa:
	case SNDSPC1 + 0xb:
	case SNDSPC1 + 0xc:
	case SNDSPC1 + 0xd:
	case SNDSPC1 + 0xe:
	case SNDSPC1 + 0xf:
	    argc = methodPointer[instruct_pointer++];
	    trace_inst(meth, instruct_pointer, opcode, oprand,
		       get_pointer(SpecialSelectors, oprand), argc);
	    tstack = stack_pointer;
	    if ((stack_pointer + argc) >= stack_top)  {
		dump_stack(get_pointer(SpecialSelectors, oprand));
		SendError(InterpStackFault, &tstack);
	    } else
	       SendMethod(get_pointer(SpecialSelectors, oprand), &tstack, argc);
	    methodPointer = get_object_base(meth);
	    stack_pointer = tstack;
	    break;

	case RETTMP >> 4:
	    oprand = methodPointer[instruct_pointer++];
	case RETTMP + 0x0:
	case RETTMP + 0x1:
	case RETTMP + 0x2:
	case RETTMP + 0x3:
	case RETTMP + 0x4:
	case RETTMP + 0x5:
	case RETTMP + 0x6:
	case RETTMP + 0x7:
	case RETTMP + 0x8:
	case RETTMP + 0x9:
	case RETTMP + 0xa:
	case RETTMP + 0xb:
	case RETTMP + 0xc:
	case RETTMP + 0xd:
	case RETTMP + 0xe:
	case RETTMP + 0xf:
	    temp = get_pointer(home, oprand + BLOCK_STACK);
	    trace_inst(meth, instruct_pointer, opcode, oprand, temp, 0);
	   /* Something wrong if stack there is no sending object */
	    if (sender == NilPtr) {
		Push(current_context);
		Push(temp);
		tstack = stack_pointer;
		SendMethod(CannotReturnSelector, &tstack, 1);
		stack_pointer = tstack;
	    } else
		return_Object(temp, sender);
	    break;
	case RETSELF:
	    trace_inst(meth, instruct_pointer, opcode, oprand, reciever, 0);
	   /* Something wrong if stack there is no sending object */
	    if (sender == NilPtr) {
		Push(current_context);
		Push(reciever);
		tstack = stack_pointer;
		SendMethod(CannotReturnSelector, &tstack, 1);
		stack_pointer = tstack;
	    } else
		return_Object(reciever, sender);
	    break;

	case RETTOS:
	    temp = TopStack();
	    trace_inst(meth, instruct_pointer, opcode, oprand, temp, 0);
	    if (sender == NilPtr) {
		Push(current_context);
		Push(temp);
		tstack = stack_pointer;
		SendMethod(CannotReturnSelector, &tstack, 1);
		stack_pointer = tstack;
	    } else
		return_Object(temp, sender);
	    break;

	case RETTRUE:
	    trace_inst(meth, instruct_pointer, opcode, oprand, TruePointer, 0);
	    if (sender == NilPtr) {
		Push(current_context);
		Push(TruePointer);
		tstack = stack_pointer;
		SendMethod(CannotReturnSelector, &tstack, 1);
		stack_pointer = tstack;
	    } else
		return_Object(TruePointer, sender);
	    break;

	case RETFALS:
	    trace_inst(meth, instruct_pointer, opcode, oprand, FalsePointer, 0);
	    if (sender == NilPtr) {
		Push(current_context);
		Push(FalsePointer);
		tstack = stack_pointer;
		SendMethod(CannotReturnSelector, &tstack, 1);
		stack_pointer = tstack;
	    } else
		return_Object(FalsePointer, sender);
	    break;

	case RETNIL:
	    trace_inst(meth, instruct_pointer, opcode, oprand, NilPtr, 0);
	    if (sender == NilPtr) {
		Push(current_context);
		Push(NilPtr);
		tstack = stack_pointer;
		SendMethod(CannotReturnSelector, &tstack, 1);
		stack_pointer = tstack;
	    } else
		return_Object(NilPtr, sender);
	    break;

	case RETBLK:
	    temp = TopStack();
	    trace_inst(meth, instruct_pointer, opcode, oprand, temp, 0);
	    if (caller == NilPtr) {
		Push(current_context);
		Push(temp);
		tstack = stack_pointer;
		SendMethod(CannotReturnSelector, &tstack, 1);
		stack_pointer = tstack;
	    } else 
		return_Object(temp, caller);
	    break;

	case DUPTOS:
	    trace_inst(meth, instruct_pointer, opcode, oprand, TopStack(), stack_pointer);
	    Push(TopStack());
	    break;

	case POPSTK:
	    trace_inst(meth, instruct_pointer, opcode, oprand, NilPtr, 0);
	    PopStack();
	    break;

	case PSHVAR:
	    oprand = methodPointer[instruct_pointer++];
	    temp = Literal(oprand);
	    trace_inst(meth, instruct_pointer, opcode, oprand, get_pointer(temp, ASSOC_VALUE), stack_pointer);
	    Push(get_pointer(temp, ASSOC_VALUE));
	    break;

	case STRVAR:
	    oprand = methodPointer[instruct_pointer++];
	    temp = Literal(oprand);
	    trace_inst(meth, instruct_pointer, opcode, oprand, TopStack(), 0);
	    Set_object(temp, ASSOC_VALUE, TopStack());
	    PopStack();
	    break;

	case PSHSELF:
	    trace_inst(meth, instruct_pointer, opcode, oprand, reciever, stack_pointer);
	    Push(reciever);
	    break;

	case PSHNIL:
	    trace_inst(meth, instruct_pointer, opcode, oprand, NilPtr, stack_pointer);
	    Push(NilPtr);
	    break;

	case PSHTRUE:
	    trace_inst(meth, instruct_pointer, opcode, oprand, NilPtr, stack_pointer);
	    Push(TruePointer);
	    break;

	case PSHFALS:
	    trace_inst(meth, instruct_pointer, opcode, oprand, NilPtr, stack_pointer);
	    Push(FalsePointer);
	    break;

	case PSHCTX:
	    trace_inst(meth, instruct_pointer, opcode, oprand, NilPtr, stack_pointer);
	    Push(current_context);
	    break;


	}
    }
}

void
init_event(Event_queue queue)
{
	queue->rdptr = queue->wrptr = &queue->data[0];
	queue->top = &queue->data[sizeof(queue->data)/sizeof(Objptr)];
}

void
add_event(Event_queue queue, Objptr event)
{
	Objptr		*next = queue->wrptr + 1;

	/*
	 * Order is real important since we could get an event read
	 * during time we are writing an event.
	 */
	if (next != queue->rdptr) { 
	    if (next == queue->top) {
		next = &queue->data[0];
	    	if (next == queue->rdptr) 
		    return;
	    }
	    *queue->wrptr = event;
	    queue->wrptr = next;
	}
}

Objptr
nxt_event(Event_queue queue)
{
	Objptr		res;
#if 0
	char		buffer[1000];

	wsprintf(buffer, "Queue %x %x %x\n",
		queue->rdptr, queue->wrptr, (*queue->rdptr)/2);
	dump_string(buffer);
#endif
	/* Check if queue is empty */
	if(queue->rdptr == queue->wrptr)
	    return NilPtr;
	res = *queue->rdptr++;
	if(queue->rdptr == queue->top)
	    queue->rdptr = &queue->data[0];
	return res;
}
	
void
synchronusSignal(Objptr aSemaphore)
{
    int                 excess;

    if (isEmptyList(aSemaphore)) {
	excess = get_integer(aSemaphore, SEM_SIGNALS);
	Set_integer(aSemaphore, SEM_SIGNALS, excess + 1);
    } else
	resume(removeFirstLinkOf(aSemaphore));
}

void
checkProcessSwitch()
{
	
    /* inline of next_event */

    /* While there are events to read */
    while(asyncsigs.rdptr != asyncsigs.wrptr) {
        synchronusSignal(*asyncsigs.rdptr++);
        if(asyncsigs.rdptr == asyncsigs.top)
            asyncsigs.rdptr = &asyncsigs.data[0];
    }

    if (newProcessWaiting) {
	Objptr              sched;

	newProcessWaiting = 0;
	sched = schedulerPointer;
	Set_object(get_pointer(sched, SCHED_INDEX),
		   PROC_SUSPEND, current_context);
	Set_object(sched, SCHED_INDEX, newProcess);
	current_context = get_pointer(newProcess, PROC_SUSPEND);
    }

}

Objptr
removeFirstLinkOf(Objptr aList)
{
    Objptr              first, last;

    first = get_pointer(aList, LINK_FIRST);
    last = get_pointer(aList, LINK_LAST);
    object_incr_ref(first);
    if (first == last) {
	Set_object(aList, LINK_FIRST, NilPtr);
	Set_object(aList, LINK_LAST, NilPtr);
    } else
	Set_object(aList, LINK_FIRST, get_pointer(first, LINK_NEXT));
    Set_object(first, LINK_NEXT, NilPtr);
    return first;
}

void
addLinkLast(Objptr aList, Objptr aLink)
{
    if (isEmptyList(aList))
	Set_object(aList, LINK_FIRST, aLink);
    else
	Set_object(get_pointer(aList, LINK_LAST), LINK_NEXT, aLink);
    Set_object(aList, LINK_LAST, aLink);
    object_decr_ref(aLink);
}

Objptr
wakeHighestPriority()
{
    Objptr              sched_list, list;
    int                 priority;

    sched_list = get_pointer(schedulerPointer, SCHED_LIST);
    priority = length_of(sched_list);
    while (isEmptyList(list = get_pointer(sched_list, --priority))) ;
    return removeFirstLinkOf(list);
}

void
resume(Objptr aProcess)
{
    Objptr              active = activeProcess;
    int                 priority = get_integer(active, PROC_PRIO);
    int                 newPri = get_integer(aProcess, PROC_PRIO);

    if (newPri >= priority) {
	object_incr_ref(active);
	sleep(active);
	transferTo(aProcess);
    } else
	sleep(aProcess);
}

void
wait(Objptr aSemaphore)
{
    int                 excess;

    excess = get_integer(aSemaphore, SEM_SIGNALS);
    if (excess > 0)
	Set_integer(aSemaphore, SEM_SIGNALS, excess - 1);
    else {
	Objptr		suspProc;

	suspProc = get_pointer(schedulerPointer, SCHED_INDEX);
	object_incr_ref(suspProc);
	addLinkLast(aSemaphore, suspProc);
	suspendActive;
    }
}

void
signal_console(Objptr aLink)
{
    Objptr	first;

    first = get_pointer(aLink, LINK_FIRST);
    if (first != NilPtr)
        resume(removeFirstLinkOf(aLink));
}

void
wait_console(Objptr aLink)
{
    Objptr		suspProc;

    suspProc = get_pointer(schedulerPointer, SCHED_INDEX);
    object_incr_ref(suspProc);
    addLinkLast(aLink, suspProc);
    suspendActive;
}
