/*
 * Smalltalk interpreter: Main byte code interpriter.
 *
 * $Log: primitive.c,v $
 * Revision 1.3  2000/03/02 00:30:52  rich
 * Moved functions to manipulate smalltalk system to smallobjs.c
 * Localize stack_pointer in primitive(), improved preformace.
 *
 * Revision 1.2  2000/02/01 18:10:00  rich
 * Added code to display stack trace on error.
 * Added support for CompiledMethod class.
 * Added support for CharStream class.
 * Fixed error in Divide and Div primitives.
 * Fixed NextPut and Next primititives.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#ifndef lint
static char        *rcsid =
	"$Id: primitive.c,v 1.3 2000/03/02 00:30:52 rich Exp rich $";

#endif

/* System stuff */
#ifdef unix
#include <stdio.h>
#include <unistd.h>
#include <math.h>
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

#include "image.h"
#include "object.h"
#include "smallobjs.h"
#include "interp.h"
#include "primitive.h"
#include "fileio.h"
#include "dump.h"

#define	GetStack(off)	((off > args) ? NilPtr:  \
				 get_pointer(current_context, \
					stack_pointer + (args - (off))))

/* Add support for largeinteger */
#define IsInteger(op, value) \
	if (!is_integer((op))) \
		break; \
	(value) = as_integer((op));

#define IntValue(op, off, value) { \
 		  Objptr	_temp_ = get_pointer((op), (off)); \
		  IsInteger(_temp_, (value)); \
		  }

#define ReturnInteger(value) { \
	    Objptr  _temp_ = (value); \
	    if (canbe_integer(_temp_)) { \
		res = as_integer_object(_temp_); \
		success = TRUE; \
	    } \
	    }

#define CheckIndex(array, index) { \
	int _temp_ = length_of(array); \
	if (_temp_ < 0 || index < 0 || index > _temp_) \
		break;  \
	}

#define IsFloat(x)	(class_of((x)) == FloatClass)
#define floatValue(x)	(*((double *)get_object_base((x))))
#define newFloat(x)	res = create_new_object(FloatClass, 0); \
			*((double *)get_object_base(res))=(x);


#define ReturnFloat(expr) {newFloat((expr)); success = TRUE; }

#define ReturnBoolean(expr) \
	 { res = ((expr))? TruePointer: FalsePointer; success = TRUE; }

#define ReturnChar(expr) { \
	    int _temp_  = (expr); \
	    if (_temp_ < 0 || _temp_ > 255) \
		break; \
	    res = get_pointer(CharacterTable, \
		     _temp_ + (fixed_size(CharacterTable) / sizeof(Objptr))); \
	    success = TRUE; \
	}

#define IsChar(x)	(class_of((x)) == CharacterClass)
#define charValue(x)    (get_pointer((x), CHARVALUE))

#define ReturnValidObject(expr) { res = (expr); success = res != NilPtr; }

#define ReturnObject(expr) { res = (expr); success = TRUE; }

Objptr		compClass;
Objptr		compCatagory;

int
arrayAt(Objptr array, int index, Objptr * value)
{
    int                 temp = length_of(array);
    int                 base = fixed_size(array);

    index--;
    if (temp < 0 || index < 0 || index > temp)
	return FALSE;

    if (is_byte(array))
	*value = as_integer_object(get_byte(array, index + base));
    else if (is_word(array)) {
	temp = get_word(array, index + (base / sizeof(Objptr)));
	if (canbe_integer(temp))
	    *value = as_integer_object(temp);
	else
	    return FALSE;	/* Handle later */
    } else
	*value = get_pointer(array, index + (base / sizeof(Objptr)));
    return TRUE;
}

int 
arrayPutAt(Objptr array, int index, Objptr value)
{
    int                 temp = length_of(array);
    int                 base = fixed_size(array);

    index--;
    if (temp < 0 || index < 0 || index > temp)
	return FALSE;

    if (is_byte(array)) {
	if (!is_integer(value))
	    return FALSE;	/* Handle Later */
	set_byte(array, index + base, as_integer(value));
    } else if (is_word(array)) {
	if (!is_integer(value))
	    return FALSE;	/* Handle Later */
	temp = as_integer(value);
	set_word(array, index + (base / sizeof(Objptr)), temp);
    } else
	Set_object(array, index + (base / sizeof(Objptr)), value);
    return TRUE;
}


/*
 * Process a primitive function.
 */
int
primitive(int primnum, Objptr reciever, Objptr newClass, int args,
	  int *tstack)
{
    Objptr              argument;
    Objptr              res;
    Objptr              otemp;
    int                 iarg;
    int                 result;
    int                 temp;
    int                 index;
    char		*str;
    int			success = FALSE;
    int			stack_pointer = *tstack;
    int			stack_top = size_of(current_context) / sizeof(Objptr);

   /* Grab first argument if there is one */
    if (args >= 2)
	otemp = GetStack(2);
    else
	otemp = NilPtr;
    if (args >= 1)
	argument = GetStack(1);
    else
	argument = NilPtr;
    res = reciever;

    switch (primnum) {
    case primitiveAdd:
	IsInteger(reciever, temp);
	IsInteger(argument, iarg);
	ReturnInteger(temp + iarg);
	break;

    case primitiveSub:
	IsInteger(reciever, temp);
	IsInteger(argument, iarg);
	ReturnInteger(temp - iarg);
	break;

    case primitiveMult:
	IsInteger(reciever, temp);
	IsInteger(argument, iarg);
	ReturnInteger(temp * iarg);
	break;

    case primitiveDivide:
	IsInteger(reciever, temp);
	IsInteger(argument, iarg);
	if (iarg == 0 || (temp % iarg) != 0)
	   break;
	ReturnInteger(temp / iarg);
	break;

    case primitiveMod:
	IsInteger(reciever, temp);
	IsInteger(argument, iarg);
	if (iarg== 0)
	    break;
	ReturnInteger(temp % iarg);
	break;

    case primitiveDiv:
	IsInteger(reciever, temp);
	IsInteger(argument, iarg);
	if (iarg == 0)
	    break;
	ReturnInteger(temp / iarg);
	break;

    case primitiveBitAnd:
	IsInteger(reciever, temp);
	IsInteger(argument, iarg);
	ReturnInteger(temp & iarg);
	break;

    case primitiveBitOr:
	IsInteger(reciever, temp);
	IsInteger(argument, iarg);
	ReturnInteger(temp | iarg);
	break;

    case primitiveBitXor:
	IsInteger(reciever, temp);
	IsInteger(argument, iarg);
	ReturnInteger(temp ^ iarg);
	break;

    case primitiveBitShift:
	IsInteger(reciever, temp);
	IsInteger(argument, iarg);
	result = (iarg < 0) ? (temp >> (-iarg)) : (temp << iarg);
	ReturnInteger(result);
	break;

    case primitiveEqual:
	IsInteger(reciever, temp);
	IsInteger(argument, iarg);
	ReturnBoolean(temp == iarg);
	break;

    case primitiveNotEqual:
	IsInteger(reciever, temp);
	IsInteger(argument, iarg);
	ReturnBoolean(temp != iarg);
	break;

    case primitiveLess:
	IsInteger(reciever, temp);
	IsInteger(argument, iarg);
	ReturnBoolean(temp < iarg);
	break;

    case primitiveGreater:
	IsInteger(reciever, temp);
	IsInteger(argument, iarg);
	ReturnBoolean(temp > iarg);
	break;

    case primitiveLessEqual:
	IsInteger(reciever, temp);
	IsInteger(argument, iarg);
	ReturnBoolean(temp <= iarg);
	break;

    case primitiveGreaterEqual:
	IsInteger(reciever, temp);
	IsInteger(argument, iarg);
	ReturnBoolean(temp >= iarg);
	break;

    case primitiveMakePoint:
	res = create_new_object(PointClass, 0);
	Set_object(res, XINDEX, reciever);
	Set_object(res, YINDEX, argument);
	success = TRUE;
	break;

    case primitiveAsFloat:
	IsInteger(reciever, temp);
	ReturnFloat((float) temp);
	break;

    case primitiveFloatAdd:
	if (IsFloat(reciever) && IsFloat(argument))
	    ReturnFloat(floatValue(reciever) + floatValue(argument));
	break;

    case primitiveFloatSub:
	if (IsFloat(reciever) && IsFloat(argument))
	    ReturnFloat(floatValue(reciever) - floatValue(argument));
	break;

    case primitiveFloatMult:
	if (IsFloat(reciever) && IsFloat(argument))
	    ReturnFloat(floatValue(reciever) * floatValue(argument));
	break;

    case primitiveFloatDivide:
	if (IsFloat(reciever) && IsFloat(argument))
	    ReturnFloat(floatValue(reciever) / floatValue(argument));
	break;
    case primitiveFloatEqual:
	if (IsFloat(reciever) && IsFloat(argument))
	    ReturnBoolean((floatValue(reciever) == floatValue(argument)));
	break;

    case primitiveFloatNotEqual:
	if (IsFloat(reciever) && IsFloat(argument))
	    ReturnBoolean((floatValue(reciever) != floatValue(argument)));
	break;

    case primitiveFloatLess:
	if (IsFloat(reciever) && IsFloat(argument))
	    ReturnBoolean((floatValue(reciever) < floatValue(argument)));
	break;

    case primitiveFloatGreater:
	if (IsFloat(reciever) && IsFloat(argument))
	    ReturnBoolean((floatValue(reciever) > floatValue(argument)));
	break;

    case primitiveFloatLessEqual:
	if (IsFloat(reciever) && IsFloat(argument))
	    ReturnBoolean((floatValue(reciever) <= floatValue(argument)));
	break;

    case primitiveFloatGreaterEqual:
	if (IsFloat(reciever) && IsFloat(argument))
	    ReturnBoolean((floatValue(reciever) >= floatValue(argument)));
	break;

    case primitiveFloatTruncate:
	if (IsFloat(reciever)) {
	    result = (long) floatValue(reciever);
	    ReturnInteger(result);
	}
	break;

    case primitiveFloatFractionPart:
	if (IsFloat(reciever)) {
	    double              fvalue = floatValue(reciever);
	    double              fdummy;

	    if (fvalue < 0.0)
		fvalue = -fvalue;
	    ReturnFloat(modf(floatValue(reciever), &fdummy));
	}
	break;

    case primitiveFloatExponent:
	if (IsFloat(reciever)) {
	    double              fvalue = floatValue(reciever);

	    if (fvalue == 0.0)
		result = 1;
	    else
		frexp(fvalue, &result);
	    ReturnInteger(result);
	}
	break;

    case primitiveFloatTimesTwoPower:
	if (IsFloat(reciever) && is_integer(argument))
	    ReturnFloat(ldexp(floatValue(reciever), as_integer(argument)));
	break;

    case primitiveFloatExp:
	if (IsFloat(reciever))
	    ReturnFloat(exp(floatValue(reciever)));
	break;

    case primitiveFloatLn:
	if (IsFloat(reciever))
	    ReturnFloat(log(floatValue(reciever)));
	break;

    case primitiveFloatPow:
	if (IsFloat(reciever) && IsFloat(argument))
	    ReturnFloat(pow(floatValue(reciever), floatValue(argument)));
	break;

    case primitiveFloatSqrt:
	if (IsFloat(reciever))
	    ReturnFloat(sqrt(floatValue(reciever)));
	break;

    case primitiveFloatCeil:
	if (IsFloat(reciever))
	    ReturnFloat(exp(floatValue(reciever)));
	break;

    case primitiveFloatFloor:
	if (IsFloat(reciever))
	    ReturnFloat(exp(floatValue(reciever)));
	break;

    case primitiveFloatSin:
	if (IsFloat(reciever))
	    ReturnFloat(sin(floatValue(reciever)));
	break;

    case primitiveFloatCos:
	if (IsFloat(reciever))
	    ReturnFloat(cos(floatValue(reciever)));
	break;

    case primitiveFloatTan:
	if (IsFloat(reciever))
	    ReturnFloat(tan(floatValue(reciever)));
	break;

    case primitiveFloatASin:
	if (IsFloat(reciever))
	    ReturnFloat(asin(floatValue(reciever)));
	break;

    case primitiveFloatACos:
	if (IsFloat(reciever))
	    ReturnFloat(acos(floatValue(reciever)));
	break;

    case primitiveFloatATan:
	if (IsFloat(reciever))
	    ReturnFloat(atan(floatValue(reciever)));
	break;

    case primitiveAt:
	IsInteger(argument, index);
	success = arrayAt(reciever, index, &res);
	break;

    case primitivePutAt:
	IsInteger(argument, index);
	res = otemp;
	success = arrayPutAt(reciever, index, res); 
	break;

    case primitiveSize:
	ReturnInteger(length_of(reciever));
	break;

    case primitiveStringAt:
	IsInteger(argument, index); 
	if (arrayAt(reciever, index, &res) && is_integer(res)) 
	    ReturnChar(as_integer(res));
	break;

    case primitiveStringAtPut:
	IsInteger(argument, index);
	res = otemp;
	if (!IsChar(res))
	   break;
	success = arrayPutAt(reciever, index, charValue(res));
	break;

    case primitiveNext:
	argument = get_pointer(reciever, STREAMARRAY);
	IntValue(reciever, STREAMINDEX, index);
	IntValue(reciever, STREAMREADL, temp);
	index++;
	otemp = class_of(argument);
	if (otemp != ArrayClass || otemp != StringClass)
	    break;
	if (index > temp || !arrayAt(argument, index, &res))
	    break;
	if (otemp == StringClass) {
	    if (is_integer(res)) {
	        ReturnChar(as_integer(res));
	    } else
		break;
	}
	Set_integer(reciever, STREAMINDEX, index);
	success = TRUE;
	break;

    case primitiveNextPut:
	res = get_pointer(reciever, STREAMARRAY);
	IntValue(reciever, STREAMINDEX, index);
	IntValue(reciever, STREAMREADL, temp);
	IntValue(reciever, STREAMWRITEL, iarg);
	/* Check if room left in collection for insert */
	if (temp > iarg)
	   break;
	index++;
	otemp = class_of(res);
	if (otemp != ArrayClass || otemp != StringClass)
	    break;
	if (otemp == StringClass) {
	    if (IsChar(argument)) 
	         argument = charValue(argument);
	    else
		 break;
 	}
	if (!arrayPutAt(res, index, argument))
	    break;
	if (index > temp)
	   Set_integer(reciever, STREAMREADL, index - 1);
	Set_integer(reciever, STREAMINDEX, index);
	success = TRUE;
	break;

    case primitiveAtEnd:
	argument = get_pointer(reciever, STREAMARRAY);
	IntValue(reciever, STREAMINDEX, index);
	IntValue(reciever, STREAMREADL, iarg);
	ReturnBoolean(index > iarg);
	break;

    case primitiveObjectAt:
	IsInteger(argument, index);
	temp = get_pointer(reciever, METH_HEADER);
	index--;
	if (index >= 0 && index <= LiteralsOf(temp)) 
	    ReturnObject(get_pointer(reciever, index + METH_HEADER));
	break;

    case primitiveObjectAtPut:
	IsInteger(argument, index);
	temp = get_pointer(reciever, METH_HEADER);
	index--;
	if (index >= 0 && index <= LiteralsOf(temp)) {
	    Set_object(reciever, index + METH_HEADER, otemp);
	    ReturnObject(otemp);
	}
	break;

    case primitiveNew:
	ReturnValidObject(create_new_object(reciever, 0));
	break;

    case primitiveNewWithArg:
	IsInteger(argument, temp);
	if (temp < 0)
	   break;
	ReturnValidObject(create_new_object(reciever, temp));
	break;

    case primitiveBecome:
	if (swapPointers(reciever, argument))
	    success = TRUE;
	break;

    case primitiveInstVarAt:
	IsInteger(argument, index);
	if (index > 0 && index <= (fixed_size(reciever) / sizeof(Objptr))) 
	    ReturnObject(get_pointer(reciever, index - 1));
	break;

    case primitiveInstVarPutAt:
	IsInteger(argument, index);
	if (index > 0 && index <= (fixed_size(reciever) / sizeof(Objptr))) {
	    Set_object(reciever, index - 1, otemp);
	    ReturnObject(otemp);
	}
	break;

    case primitiveAsOop:
	if (is_object(reciever)) 
	    ReturnObject(as_oop(reciever))
	break;

    case primitiveAsObject:
	if (is_integer(reciever)) {
	    res = as_object(reciever);
	    if (notFree(res))
		success = TRUE;
	}
	break;

    case primitiveSomeInstance:
	ReturnObject(initialInstance(reciever));
	break;

    case primitiveNextInstance:
	ReturnObject(nextInstance(reciever));
	break;

    case primitiveNewMethod:
	IsInteger(argument, temp);
       /* Round size to multiple of object pointer size */
	temp = (temp + (sizeof(Objptr) - 1)) / sizeof(Objptr);
       /* Add on number of literals and one word for header */
	temp += LiteralsOf(otemp) + 1;
	if ((res = create_new_object(CompiledMethodClass, temp)) != NilPtr) {
	    set_pointer(res, METH_HEADER, otemp);
	    success = TRUE;
	}
	break;

    case primitiveByteCodes:
	temp = length_of(reciever);
	otemp = get_pointer(reciever, METH_HEADER);
	temp -= LiteralsOf(otemp) + 1;
	temp *= sizeof(Objptr);
	ReturnInteger(temp);
	break;

    case primitiveValue:
       /* Check correct number of arguments */
	IntValue(reciever, BLOCK_ARGCNT, temp);
	if (args != temp)
	    break;

	index = size_of(reciever) / sizeof(Objptr);

       /* Copy argument to stack of block */
	for (; args > 0; args--) {
	    otemp = TopStack();
	    Set_object(reciever, --index, otemp);
	    PopStack();
	}

       /* Remove the block from top of stack */
        PopStack();

       /* Set new block context registers */
	Set_integer(reciever, BLOCK_SP, index);
	Set_object(reciever, BLOCK_IP, get_pointer(reciever, BLOCK_IIP));
	Set_object(reciever, BLOCK_CALLER, current_context);

       /* Switch to context */
	current_context = reciever;
	newContextFlag = 1;
	*tstack = stack_pointer;
	return TRUE;

    case primitiveValueWithArgs:
       /* Check correct number of arguments */
	args = length_of(argument);
	IntValue(reciever, BLOCK_ARGCNT, temp);
	if (args != temp)
	    break;

	index = size_of(reciever) / sizeof(Objptr);
       /* Dump array onto block contexts stack */
	for (; args > 0; args--)
	    Set_object(current_context, --index, get_pointer(argument, args));

       /* Set new block context registers */
	Set_object(reciever, BLOCK_IP, get_pointer(reciever, BLOCK_IIP));
	Set_integer(reciever, BLOCK_SP, index);
	Set_object(reciever, BLOCK_CALLER, current_context);

       /* Remove arguments from stack */
	PopStack();
	PopStack();

       /* Switch to context */
	current_context = reciever;
	newContextFlag = 1;
	*tstack = stack_pointer;
	return TRUE;

    case primitivePreform:
	/* Redo for new stack order */
	args--;
	object_incr_ref(argument);
	for (temp = args; temp > 0; temp--) {
	   Set_object(current_context, stack_pointer + temp + 1,
		get_pointer(current_context, stack_pointer + temp));
	}
	PopStack();		/* Pop Last argument */
	*tstack = stack_pointer;	/* Do the call */
	SendMethod(argument, tstack, args);
	object_decr_ref(argument);
	return TRUE;

    case primitivePreformWithArgs:
	/* Redo for new stack order */
	object_incr_ref(argument);
	res = otemp;
	object_incr_ref(res);
	args = length_of(argument);
	PopStack();		/* Pop Array. */
	PopStack();		/* Pop selector. */
	for (temp = args; temp >= 0; temp--)
	    Push(get_pointer(res, temp));
	object_decr_ref(res);
	*tstack = stack_pointer;
	SendMethod(argument, tstack, args);
	object_decr_ref(argument);
	return TRUE;

    case primitiveEquivalence:
	ReturnBoolean(reciever == argument);
	break;

    case primitiveClass:
	ReturnObject(class_of(reciever));
	break;

    case primitiveSignal:
	synchronusSignal(reciever);
	return TRUE;

    case primitiveWait:
	wait(reciever);
	return TRUE;

    case primitiveResume:
	resume(reciever);
	return TRUE;

    case primitiveSuspend:
	if (reciever == activeProcess) {
	    suspendActive;
	    res = NilPtr;
	    success = TRUE;
	}
	break;

    case primitiveCoreUsed:
	ReturnObject(coreUsed());
	break;

    case primitiveFreeCore:
	ReturnObject(freeSpace());
	break;

    case primitiveOopsLeft:
	ReturnObject(freeOops());
	break;

    case primitiveQuit:
	running = FALSE;
	return TRUE;

    case primitiveSnapShot:
       /*
        * Fix stack so we save a false pointer onto stack.
        * This is what the saved image will see.
        */
	Set_object(current_context, stack_pointer, FalsePointer);

       /* Make sure we can have valid argument */
        if ((str = Cstring(argument)) == NULL)
	    break;

       /* Do Snapshot, if we fail, let primitive fail handle problem */
	if (save_image(str, NULL)) 
	    ReturnBoolean(TRUE); /* Now return a TRUE to running system */
        free(str);
	break;

    case primitiveFileOpen:
	ReturnBoolean (open_buffer(reciever));
	break;

    case primitiveFileClose:
	close_buffer(reciever);
	ReturnBoolean (TRUE);
	break;

    case primitiveFileNext:
	if (read_buffer(reciever, &temp)) 
	    ReturnChar(temp);
	break;

    case primitiveFileNextPut:
	if (!IsChar(argument))
	    break;
	if (write_buffer(reciever, as_integer(charValue(argument))))
	    success = TRUE;
	break;

    case primitiveFileGet:
	/* Load second arguemnt with contents of file */
	break;

    case primitiveFilePut:
	/* Save second argument to file */
	break;

    case primitiveFileSize:
	ReturnInteger(size_buffer(reciever));
	break;

    case primitiveFileDir:
	/* Create a array of files in directory of argument */
	break;

    case primitiveInternString:
	str = Cstring(reciever);
	ReturnObject(internString(str));
	free(str);
	break;

    case primitiveClassComment:
	Set_object(reciever, CLASS_COMMENT, argument);
	success = TRUE;
	break;

    case primitiveMethodsFor:
	str = Cstring(argument);
	argument = internString(str);
	free(str);
	rootObjects[METHFOR0] = compClass = reciever;
	rootObjects[METHFOR1] = compCatagory = argument;
 	success = TRUE;
	break;

    case primitiveError:
        dump_stack(reciever);
	str = Cstring(argument);
	error(str);
	free(str);
	success = TRUE;

    case primitiveDumpObject:
	dump_object(reciever);
	success = TRUE;
	break;

    case primitiveTimeWordsInto:
	/* Creates and initializes a new time object */
	break;

    case primitiveTickWordsInto:
	/* Creates new time object with miliseconds since booting */
	break;

    case primitiveSignalAtTick:
	/* Signals semaphore reciever when millisecond clock is greater
           then or equal to second argument */
	break;

    case primitiveStackTrace:
	/* Print out a stack trace */
	dump_stack(reciever);
	break;

    case primitiveEvaluate:
	/* Evalutate a CompiledMethod. */
        otemp = get_pointer(reciever, METH_HEADER);
        index = TempsOf(otemp);
        temp = LiteralsOf(otemp);

       /* Check type of method */
        switch (FlagOf(otemp)) {
        case METH_RETURN:
	     ReturnObject(get_pointer(reciever, temp));
	     break;
        case METH_SETINST:
	     break;
        case METH_EXTEND:
	    index = PrimitiveOf(get_pointer(reciever, temp + METH_HEADER));
	    if (index > 0 &&
	        primitive(index, reciever, newClass, 0, tstack)) {
		success = TRUE;
		break;
	    }
        default:
	    index += StackOf(otemp);
             /* Initialize a new method. */
            res = create_new_object(MethodContextClass, index);
            Set_object(res, BLOCK_SENDER, current_context);
            Set_integer(res, BLOCK_IP, sizeof(Objptr) * (temp + METH_LITSTART));
            Set_integer(res, BLOCK_SP, size_of(res) / sizeof(Objptr));
            Set_object(res, BLOCK_METHOD, reciever);
            Set_integer(res, BLOCK_IIP, 0);
            Set_object(res, BLOCK_REC, reciever);
            Set_integer(res, BLOCK_ARGCNT, 0);
    
           /* Switch to context */
	    current_context = res;
	    newContextFlag = 1;
	    return TRUE;
        }
	break;

     case primitiveFillBuffer:
	IsInteger(argument, index);
	IsInteger(otemp, temp);
	if ((str = fill_buffer(index, temp)) != NULL) {
    	    ReturnObject(MakeString(str));
	    free(str);
	}
 	break;

     case primitiveFlushBuffer:
	IsInteger(argument, index);
	if ((str = Cstring(otemp)) == NULL)
	   break;
        if(flush_buffer(index, str))
	   success = TRUE;
        free(str);
	break;

    case primitiveByteAt:
	IsInteger(argument, index);
	temp = get_pointer(reciever, METH_HEADER);
	temp = (LiteralsOf(temp) * sizeof(Objptr));
	index--;
	if (index >= 0 &&
		 index < ((length_of(reciever) * sizeof(Objptr)) - temp)) {
	    temp += fixed_size(reciever);
	    ReturnInteger(get_byte(reciever, index + temp));
	}
	break;

    case primitiveByteAtPut:
	IsInteger(argument, index);
	IsInteger(otemp, iarg);
	temp = get_pointer(reciever, METH_HEADER);
	temp = (LiteralsOf(temp) * sizeof(Objptr));
	index--;
	if (index >= 0 &&
		 index <= (1 + (length_of(reciever) * sizeof(Objptr)) - temp)) {
	    temp += fixed_size(reciever);
	    res = otemp;
	    set_byte(reciever, index + temp, iarg);
	    success = TRUE;
	}
	break;
    default:
    }
    if (success) {
	 int i; 
	 object_incr_ref(res);
	 for(i = args; i >= 0; i--) 
	     PopStack();
	 Push(res);
	 object_decr_ref(res);
	 *tstack = stack_pointer;
	 return TRUE; 
    }
    return success;
}


