/*
 * Smalltalk interpreter: Main byte code interpriter.
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

#define	GetStack(off)	get_pointer(current_context, \
					*stack_pointer + (args - (off)))
#define AdjustStack(size, value) { \
		 int i; \
		 for(i = (size); i > 0; i--) \
		     Set_object(current_context, (*stack_pointer)++, NilPtr); \
		 Set_object(current_context, --(*stack_pointer), (value)); \
		 return TRUE; \
		 }

/* Add support for largeinteger */
#define IsInteger(op, value) \
	if (!is_integer((op))) \
		break; \
	(value) = as_integer((op));

#define IntValue(op, off, value) { \
 		  Objptr	_temp_ = get_pointer((op), (off)); \
		  IsInteger(_temp_, (value)); \
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

#define PushInteger(value, args) \
	    if (canbe_integer((value))) \
		AdjustStack((args), as_integer_object((value)));

#define PushFloat(expr, args) {newFloat((expr)); AdjustStack((args), res); }

#define PushBoolean(expr, args) \
	 { res = ((expr))? TruePointer: FalsePointer; AdjustStack((args), res);}

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
 * Convert a string into a string object.
 */
Objptr
MakeString(char *str)
{
    Objptr              value;
    int                 i;

    value = create_new_object(StringClass, strlen(str));
    for (i = fixed_size(value); *str != '\0'; set_byte(value, i++, *str++)) ;
    return value;
}

/*
 * Convert a string object into a C string.
 */
char               *
Cstring(Objptr op)
{
    char               *str;
    int                 size;
    int                 base;
    int                 i;

    if (!is_byte(op))
	return NULL;

    base = fixed_size(op);
    size = length_of(op);

    if ((str = (char *) malloc(size + 1)) == NULL)
	return NULL;
    for (i = 0; i < size; i++)
	str[i] = get_byte(op, i + base);
    str[i] = '\0';
    return str;
}

/*
 * Force a snapshot.
 */
int
doSnapShot(Objptr op)
{
    char               *name;
    int                 ret;

   /* Make sure we can have valid argument */
    if ((name = Cstring(op)) == NULL)
	return FALSE;

   /* Do the work */
    ret = save_image(name, NULL);

    free(name);
    return ret;
}

/*
 * Convert a string into a Symbol.
 */
Objptr
internString(char *str)
{
    unsigned int        hash;
    char               *ptr;
    Objptr              link;
    Objptr              value;
    int                 size;
    int                 base;
    int                 symbase;
    int                 i;

   /* Compute a hash value */
    for (hash = 0, ptr = str; *ptr != '\0';
		 hash = 0x0fffffff & ((hash << 2) + (0xff & *ptr++))) ;

    symbase = fixed_size(SymbolTable) / sizeof(Objptr);

   /* Find first link in symboltable. */
    size = length_of(SymbolTable);
    hash = hash % size;
    link = get_pointer(SymbolTable, hash + symbase);
    size = strlen(str);

   /* Follow change, comparing strings */
    while (link != NilPtr) {
	value = get_pointer(link, SYM_VALUE);
       /* Check if length matches */
	if (size == length_of(value)) {
	    base = fixed_size(value);
	    for (i = 0; i < size; i++)
		if (str[i] != get_byte(value, i + base))
		    break;
	   /* If current byte is zero, we matched */
	    if (str[i] == '\0')
		return link;
	}
	link = get_pointer(link, LINK_NEXT);
    }

   /* Create a new entry */
    link = create_new_object(SymLinkClass, 0);
    value = get_pointer(SymbolTable, hash + symbase);
    Set_object(link, LINK_NEXT, value);
    Set_object(SymbolTable, hash + symbase, link);
    Set_object(link, SYM_VALUE, MakeString(str));
    return link;
}

/*
 * Add a selector into a identity dictionary.
 */
void
AddSelectorToIDictionary(Objptr dict, Objptr select, Objptr value)
{
    int                 length = length_of(dict);
    int                 index; 
    int                 wrapAround = 0;
    int                 newDict;
    int                 tally = 0;
    Objptr              key;

    index = as_integer(select) % (length - 1);
    while (1) {
	key = get_pointer(dict, index + DICT_KEY);

	if (key == NilPtr) {
	   /* Save value */
	    Set_object(dict, index + DICT_KEY, select);
	    Set_object(get_pointer(dict, DICT_VALUES),
		       index, value);
	    tally = get_integer(dict, DICT_TALLY) + 1;
	    Set_integer(dict, DICT_TALLY, tally);
	    return;
	}
	if (key == select) {
	   /* Set this value */
	    Set_object(get_pointer(dict, DICT_VALUES),
		       index, value);
	    return;
	}
	if (++index == length) {
	    if (wrapAround++)
		break;
	    index = 0;
	}
    }
   /* Get here not found and no empty spots. Grow dictionary */
    newDict = create_new_object(IdentityDictionaryClass, length + 32);
    rootObjects[TEMP0] = newDict;		/* Save till done */
    Set_object(newDict, DICT_VALUES,
	       create_new_object(ArrayClass, length + 32));
    index =  as_integer(select) % (length + 31);
    Set_object(newDict, index + DICT_KEY, select);
    Set_object(get_pointer(newDict, DICT_VALUES), index, value);
    tally = 1;
    for (index = 0; index < length; index++) {
	int index2;

	select = get_pointer(dict, index + DICT_KEY);
	if (select == NilPtr)
	    continue;
	value = get_pointer(get_pointer(dict, DICT_VALUES), index);
	index2 = as_integer(select) % (length + 31);
	wrapAround = 0;
	while (1) {
	    key = get_pointer(newDict, index2 + DICT_KEY);

	    if (key == NilPtr) {
	       /* Save value */
		Set_object(newDict, index2 + DICT_KEY, select);
		Set_object(get_pointer(newDict, DICT_VALUES),
			   index2, value);
		tally++;
		break;
	    }
	    if (key == select) {
	       /* Set this value */
		Set_object(get_pointer(newDict, DICT_VALUES),
			   index2, value);
		break;
	    }
	    if (++index2 == (length + 32)) {
		if (wrapAround++)
		    break;
		index2 = 0;
	    }
	}
    }
    Set_integer(newDict, DICT_TALLY, tally);
    swapPointers(newDict, dict);
    rootObjects[TEMP0] = NilPtr;		/* Done */
    object_decr_ref(newDict);
}

/*
 * Find an object in a identity dictionary.
 */
Objptr
FindSelectorInIDictionary(Objptr dict, Objptr selector)
{
    int                 length = length_of(dict);
    int                 index = as_integer(selector) % (length - 1);
    int                 wrapAround = 0;
    Objptr		key;

    while (1) {
	key = get_pointer(dict, index + DICT_KEY);

	if (key == NilPtr)
	    break;
	if (key == selector)
	    return get_pointer(get_pointer(dict, DICT_VALUES), index);
	if (++index == length) {
	    if (wrapAround++)
		break;
	    index = 0;
	}
    }
    return NilPtr;
}
/*
 * Create a new identity dictionary.
 */
Objptr
new_IDictionary()
{
    int                 newDict;

    newDict = create_new_object(IdentityDictionaryClass, 32);
    rootObjects[TEMP0] = newDict;
    Set_object(newDict, DICT_VALUES, create_new_object(ArrayClass, 32));
    Set_integer(newDict, DICT_TALLY, 0);
    rootObjects[TEMP0] = NilPtr;
    return (newDict);
}

/*
 * Add a association to a dictionary.
 */
void
AddSelectorToDictionary(Objptr dict, Objptr assoc)
{
    int                 length = length_of(dict);
    int                 index;
    int                 wrapAround = 0;
    int                 newDict;
    int                 tally = 0;
    Objptr              key;
    Objptr		select;
    Objptr		value;

    /* Get key */
    select = get_pointer(assoc, ASSOC_KEY);
    index = as_integer(select) % (length - 1);
    while (1) {
	key = get_pointer(dict, index + DICT_VALUES);

	if (key == NilPtr) {
	   /* Save value */
	    Set_object(dict, index + DICT_VALUES, assoc);
	    tally = get_integer(dict, DICT_TALLY) + 1;
	    Set_integer(dict, DICT_TALLY, tally);
	    return;
	}

	/* Check Key */
	value = get_pointer(key, ASSOC_KEY);
	if (value == select) {
	   /* Set this value */
	    Set_object(key, ASSOC_VALUE, get_pointer(assoc, ASSOC_VALUE));
	    return;
	}
	if (++index == length) {
	    if (wrapAround++)
		break;
	    index = 0;
	}
    }
   /* Get here not found and no empty spots. Grow dictionary */
    newDict = create_new_object(DictionaryClass, length + 32);
    rootObjects[TEMP0] = newDict;
    index = as_integer(select) % (length + 31);
    Set_object(newDict, index + DICT_VALUES, assoc);
    tally = 1;
    for (index = 0; index < length; index++) {
	int index2;

	assoc = get_pointer(dict, index + DICT_VALUES);
	if (assoc == NilPtr)
	    continue;
	select = get_pointer(assoc, ASSOC_KEY);
	index2 = as_integer(select) % (length + 31); 
	wrapAround = 0;
	while (1) {
	    key = get_pointer(newDict, index2 + DICT_VALUES);

	    if (key == NilPtr) {
	       /* Save value */
		Set_object(newDict, index2 + DICT_VALUES, assoc);
	        tally++;
		break;
	    }
	    value = get_pointer(key, ASSOC_KEY);
	    if (value == select) {
	       /* Set this value */
	        Set_object(key, ASSOC_VALUE, get_pointer(assoc, ASSOC_VALUE));
	        break;
	    }
	    if (++index2 == (length + 32)) {
		if (wrapAround++)
		    break;
		index2 = 0;
	    }
	}
    }
    Set_integer(newDict, DICT_TALLY, tally);
    swapPointers(newDict, dict);
    rootObjects[TEMP0] = NilPtr;
    object_decr_ref(newDict);
}

/*
 * Find a association to a dictionary.
 */
Objptr
FindSelectorInDictionary(Objptr dict, Objptr select)
{
    int                 length = length_of(dict);
    int                 index;
    int                 wrapAround = 0;
    Objptr              key;
    Objptr		value;

    index = as_integer(select) % (length - 1);
    while (1) {
	key = get_pointer(dict, index + DICT_VALUES);

	if (key == NilPtr) 
	    break;

	/* Check Key */
	value = get_pointer(key, ASSOC_KEY);
	if (value == select) {
	    return key;
	}
	if (++index == length) {
	    if (wrapAround++)
		break;
	    index = 0;
	}
    }
    return NilPtr;
}

/*
 * Create a new assocition.
 */
Objptr
create_association(Objptr key, Objptr value)
{
    Objptr		assoc;

    assoc = create_new_object(AssociationClass, 0);
    Set_object(assoc, ASSOC_KEY, key);
    Set_object(assoc, ASSOC_VALUE, value);
    return assoc;
}

/*
 * Create a new identity dictionary.
 */
Objptr
new_Dictionary()
{
    int                 newDict;

    newDict = create_new_object(DictionaryClass, 32);
    Set_integer(newDict, DICT_TALLY, 0);
    return (newDict);
}

/*
 * Add a key to a set.
 */
void
AddSelectorToSet(Objptr set, Objptr select)
{
    int                 length = length_of(set);
    int                 index;
    int                 wrapAround = 0;
    int                 newSet;
    int                 tally = 0;
    Objptr              key;

    /* Get key */
    index = as_integer(select) % (length - 1);
    while (1) {
	key = get_pointer(set, index + DICT_VALUES);

	if (key == NilPtr) {
	   /* Save value */
	    Set_object(set, index + DICT_VALUES, select);
	    tally = get_integer(set, DICT_TALLY) + 1;
	    Set_integer(set, DICT_TALLY, tally);
	    return;
	}

	/* Check Key */
	if (key == select) {
	   /* Already there */
	    return;
	}
	if (++index == length) {
	    if (wrapAround++)
		break;
	    index = 0;
	}
    }
   /* Get here not found and no empty spots. Grow set */
    newSet = create_new_object(SSetClass, length + 32);
    rootObjects[TEMP0] = newSet;
    index = as_integer(select) % (length + 31);
    Set_object(newSet, index + DICT_VALUES, select);
    tally = 1;
    for (index = 0; index < length; index++) {
	int  index2;

	select = get_pointer(set, index + DICT_VALUES);
	if (select == NilPtr)
	    continue;
	index2 = as_integer(select) % (length + 31);
	wrapAround = 0;
	while (1) {
	    key = get_pointer(newSet, index2 + DICT_VALUES);

	    if (key == NilPtr) {
	       /* Save value */
		Set_object(newSet, index2 + DICT_VALUES, select);
		tally++;
		break;
	    }
	    if (key == select) {
	       /* Duplicate? */
	        break;
	    }
	    if (++index2 == (length + 32)) {
		if (wrapAround++)
		    break;
		index2 = 0;
	    }
	}
    }
    Set_integer(newSet, DICT_TALLY, tally);
    swapPointers(newSet, set);
    rootObjects[TEMP0] = NilPtr;
    object_decr_ref(newSet);
}

/*
 * Find a key in a set.
 */
Objptr
FindSelectorInSet(Objptr set, Objptr select)
{
    int                 length = length_of(set);
    int                 index;
    int                 wrapAround = 0;
    Objptr              key;

    index = as_integer(select) % (length - 1);
    while (1) {
	key = get_pointer(set, index + DICT_VALUES);

	if (key == NilPtr) 
	    break;

	/* Check Key */
	if (key == select) {
	    return TruePointer;
	}
	if (++index == length) {
	    if (wrapAround++)
		break;
	    index = 0;
	}
    }
    return FalsePointer;
}

/*
 * Create a new set.
 */
Objptr
new_Set()
{
    int                 newSet;

    newSet = create_new_object(SSetClass, 32);
    Set_integer(newSet, DICT_TALLY, 0);
    return (newSet);
}

/*
 * Process a primitive function.
 */
int
primitive(int primnum, Objptr reciever, Objptr newClass, int args,
	  int *stack_pointer)
{
    Objptr              argument;
    Objptr              res;
    Objptr              otemp;
    int                 iarg;
    int                 result;
    int                 temp;
    int                 index;

   /* Grab first argument if there is one */
    if (args >= 1)
	argument = GetStack(1);
    else
	argument = NilPtr;

    switch (primnum) {
    case primitiveAdd:
	if (is_integer(reciever) && is_integer(argument)) {
	    result = as_integer(reciever) + as_integer(argument);
	    PushInteger(result, 2);
	}
	break;

    case primitiveSub:
	if (is_integer(reciever) && is_integer(argument)) {
	    result = as_integer(reciever) - as_integer(argument);
	    PushInteger(result, 2);
	}
	break;

    case primitiveMult:
	if (is_integer(reciever) && is_integer(argument)) {
	    result = as_integer(reciever) * as_integer(argument);
	    PushInteger(result, 2);
	}
	break;

    case primitiveDivide:
	if (is_integer(reciever) && is_integer(argument)) {
	    if ((temp = as_integer(argument)) == 0)
		break;
	    result = as_integer(reciever) / temp;
	    PushInteger(result, 2);
	}
	break;

    case primitiveMod:
	if (is_integer(reciever) && is_integer(argument)) {
	    if ((temp = as_integer(argument)) == 0)
		break;
	    result = as_integer(reciever) % temp;
	    PushInteger(result, 2);
	}
	break;

    case primitiveDiv:
	if (is_integer(reciever) && is_integer(argument)) {
	    iarg = as_integer(argument);
	    temp = as_integer(reciever);
	    if (iarg == 0 || (temp % iarg) == 0)
		break;
	    result = temp / iarg;
	    PushInteger(result, 2);
	}
	break;

    case primitiveBitAnd:
	if (is_integer(reciever) && is_integer(argument)) {
	    result = as_integer(reciever) % as_integer(argument);
	    PushInteger(result, 2);
	}
	break;

    case primitiveBitOr:
	if (is_integer(reciever) && is_integer(argument)) {
	    result = as_integer(reciever) | as_integer(argument);
	    PushInteger(result, 2);
	}
	break;

    case primitiveBitXor:
	if (is_integer(reciever) && is_integer(argument)) {
	    result = as_integer(reciever) ^ as_integer(argument);
	    PushInteger(result, 2);
	}
	break;

    case primitiveBitShift:
	if (is_integer(reciever) && is_integer(argument)) {
	    iarg = as_integer(argument);
	    temp = as_integer(reciever);
	    result = (iarg < 0) ? (temp >> (-iarg)) : (temp << iarg);
	    PushInteger(result, 2);
	}
	break;

    case primitiveEqual:
	if (is_integer(reciever) && is_integer(argument))
	    PushBoolean((as_integer(reciever) == as_integer(argument)), 2);
	break;

    case primitiveNotEqual:
	if (is_integer(reciever) && is_integer(argument))
	    PushBoolean((as_integer(reciever) != as_integer(argument)), 2);
	break;

    case primitiveLess:
	if (is_integer(reciever) && is_integer(argument))
	    PushBoolean((as_integer(reciever) < as_integer(argument)), 2);
	break;

    case primitiveGreater:
	if (is_integer(reciever) && is_integer(argument))
	    PushBoolean((as_integer(reciever) > as_integer(argument)), 2);
	break;

    case primitiveLessEqual:
	if (is_integer(reciever) && is_integer(argument))
	    PushBoolean((as_integer(reciever) <= as_integer(argument)), 2);
	break;

    case primitiveGreaterEqual:
	if (is_integer(reciever) && is_integer(argument))
	    PushBoolean((as_integer(reciever) >= as_integer(argument)), 2);
	break;

    case primitiveMakePoint:
	if (is_integer(reciever) && is_integer(argument)) {
	    result = create_new_object(PointClass, 0);
	    Set_object(result, XINDEX, reciever);
	    Set_object(result, YINDEX, argument);
	    AdjustStack(2, result);
	}
	break;

    case primitiveAsFloat:
	if (is_integer(reciever))
	    PushFloat((float) as_integer(reciever), 1);
	break;

    case primitiveFloatAdd:
	if (IsFloat(reciever) && IsFloat(argument))
	    PushFloat(floatValue(reciever) + floatValue(argument), 2);
	break;

    case primitiveFloatSub:
	if (IsFloat(reciever) && IsFloat(argument))
	    PushFloat(floatValue(reciever) - floatValue(argument), 2);
	break;

    case primitiveFloatMult:
	if (IsFloat(reciever) && IsFloat(argument))
	    PushFloat(floatValue(reciever) * floatValue(argument), 2);
	break;

    case primitiveFloatDivide:
	if (IsFloat(reciever) && IsFloat(argument))
	    PushFloat(floatValue(reciever) / floatValue(argument), 2);
	break;
    case primitiveFloatEqual:
	if (IsFloat(reciever) && IsFloat(argument))
	    PushBoolean((floatValue(reciever) == floatValue(argument)), 2);
	break;

    case primitiveFloatNotEqual:
	if (IsFloat(reciever) && IsFloat(argument))
	    PushBoolean((floatValue(reciever) != floatValue(argument)), 2);
	break;

    case primitiveFloatLess:
	if (IsFloat(reciever) && IsFloat(argument))
	    PushBoolean((floatValue(reciever) < floatValue(argument)), 2);
	break;

    case primitiveFloatGreater:
	if (IsFloat(reciever) && IsFloat(argument))
	    PushBoolean((floatValue(reciever) > floatValue(argument)), 2);
	break;

    case primitiveFloatLessEqual:
	if (IsFloat(reciever) && IsFloat(argument))
	    PushBoolean((floatValue(reciever) <= floatValue(argument)), 2);
	break;

    case primitiveFloatGreaterEqual:
	if (IsFloat(reciever) && IsFloat(argument))
	    PushBoolean((floatValue(reciever) >= floatValue(argument)), 2);
	break;

    case primitiveFloatTruncate:
	if (IsFloat(reciever)) {
	    result = (long) floatValue(reciever);
	    PushInteger(result, 1);
	}
	break;

    case primitiveFloatFractionPart:
	if (IsFloat(reciever)) {
	    double              fvalue = floatValue(reciever);
	    double              fdummy;

	    if (fvalue < 0.0)
		fvalue = -fvalue;
	    PushFloat(modf(floatValue(reciever), &fdummy), 1);
	}
	break;

    case primitiveFloatExponent:
	if (IsFloat(reciever)) {
	    double              fvalue = floatValue(reciever);

	    if (fvalue == 0.0)
		result = 1;
	    else
		frexp(fvalue, &result);
	    PushInteger(result, 1);
	}
	break;

    case primitiveFloatTimesTwoPower:
	if (IsFloat(reciever) && is_integer(argument))
	    PushFloat(ldexp(floatValue(reciever), as_integer(argument)), 2);
	break;

    case primitiveFloatExp:
	if (IsFloat(reciever))
	    PushFloat(exp(floatValue(reciever)), 1);
	break;

    case primitiveFloatLn:
	if (IsFloat(reciever))
	    PushFloat(log(floatValue(reciever)), 1);
	break;

    case primitiveFloatPow:
	if (IsFloat(reciever) && IsFloat(argument))
	    PushFloat(pow(floatValue(reciever), floatValue(argument)), 2);
	break;

    case primitiveFloatSqrt:
	if (IsFloat(reciever))
	    PushFloat(sqrt(floatValue(reciever)), 1);
	break;

    case primitiveFloatCeil:
	if (IsFloat(reciever))
	    PushFloat(exp(floatValue(reciever)), 1);
	break;

    case primitiveFloatFloor:
	if (IsFloat(reciever))
	    PushFloat(exp(floatValue(reciever)), 1);
	break;

    case primitiveFloatSin:
	if (IsFloat(reciever))
	    PushFloat(sin(floatValue(reciever)), 1);
	break;

    case primitiveFloatCos:
	if (IsFloat(reciever))
	    PushFloat(cos(floatValue(reciever)), 1);
	break;

    case primitiveFloatTan:
	if (IsFloat(reciever))
	    PushFloat(tan(floatValue(reciever)), 1);
	break;

    case primitiveFloatASin:
	if (IsFloat(reciever))
	    PushFloat(asin(floatValue(reciever)), 1);
	break;

    case primitiveFloatACos:
	if (IsFloat(reciever))
	    PushFloat(acos(floatValue(reciever)), 1);
	break;

    case primitiveFloatATan:
	if (IsFloat(reciever))
	    PushFloat(atan(floatValue(reciever)), 1);
	break;

    case primitiveAt:
	IsInteger(argument, index);
	if (arrayAt(reciever, index, &res))
	    AdjustStack(2, res);
	break;

    case primitivePutAt:
	IsInteger(argument, index);
	res = GetStack(2);
	if (arrayPutAt(reciever, index, res))
	    AdjustStack(3, res);
	break;

    case primitiveSize:
	temp = length_of(reciever);
	if (temp >= 0)
	    AdjustStack(1, as_integer_object(temp));
	break;

    case primitiveStringAt:
	IsInteger(argument, index);
	if (arrayAt(reciever, index, &res) && is_integer(res))
	    AdjustStack(2, get_pointer(CharacterTable, as_integer(res)
		       + (fixed_size(CharacterTable) / sizeof(Objptr))));
	break;

    case primitiveStringAtPut:
	IsInteger(argument, index);
	res = GetStack(2);
	if (arrayPutAt(reciever, index, get_pointer(res, CHARVALUE)))
	    AdjustStack(3, res);
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
	if (res == StringClass) {
	    if (!is_integer(res))
		break;
	    res = get_pointer(CharacterTable, as_integer(res)
			+ (fixed_size(CharacterTable) / sizeof(Objptr)));
	}
	Set_integer(reciever, STREAMINDEX, index);
	AdjustStack(1, res);

    case primitiveNextPut:
	res = get_pointer(reciever, STREAMARRAY);
	IntValue(reciever, STREAMINDEX, index);
	IntValue(reciever, STREAMWRITEL, temp);
	index++;
	otemp = class_of(res);
	if (otemp != ArrayClass || otemp != StringClass)
	    break;
	if (otemp == StringClass)
	    argument = get_pointer(argument, CHARVALUE);
	if (index > temp || !arrayPutAt(res, index, argument))
	    break;
	Set_integer(reciever, STREAMINDEX, index);
	AdjustStack(2, argument);

    case primitiveAtEnd:
	argument = get_pointer(reciever, STREAMARRAY);
	IntValue(reciever, STREAMINDEX, index);
	IntValue(reciever, STREAMREADL, iarg);
	if (!is_indexable(argument) || index < 0)
	    break;
	temp = length_of(argument);
	res = class_of(argument);
	if (temp < 0 || res != ArrayClass || res != StringClass)
	    break;
	AdjustStack(1, (index >= temp || index >= iarg) ?
		    TruePointer : FalsePointer);

    case primitiveObjectAt:
	IsInteger(argument, index);
	temp = get_pointer(reciever, METH_HEADER);
	if (index > 0 && index <= LiteralsOf(temp))
	    AdjustStack(2, get_pointer(reciever, (index - 1) + METH_HEADER));
	break;

    case primitiveObjectAtPut:
	IsInteger(argument, index);
	temp = get_pointer(reciever, METH_HEADER);
	if (index > 0 && index <= LiteralsOf(temp)) {
	    res = GetStack(2);
	    Set_object(reciever, (index - 1) + METH_HEADER, res);
	    AdjustStack(3, res);
	}
	break;

    case primitiveNew:
	AdjustStack(1, create_new_object(reciever, 0));
	break;

    case primitiveNewWithArg:
	IsInteger(argument, temp);
	AdjustStack(2, create_new_object(reciever, temp));
	break;

    case primitiveBecome:
	if (swapPointers(reciever, argument))
	    AdjustStack(2, reciever);
	break;

    case primitiveInstVarAt:
	IsInteger(argument, index);
	if (index > 0 && index <= (fixed_size(reciever) / sizeof(Objptr)))
	    AdjustStack(2, get_pointer(reciever, index - 1));
	break;

    case primitiveInstVarPutAt:
	IsInteger(argument, index);
	if (index > 0 && index <= (fixed_size(reciever) / sizeof(Objptr))) {
	    res = GetStack(2);
	    Set_object(reciever, index - 1, res);
	    AdjustStack(3, res);
	}
	break;

    case primitiveAsOop:
	if (is_object(reciever))
	    AdjustStack(1, as_oop(reciever));
	break;

    case primitiveAsObject:
	if (is_integer(reciever)) {
	    res = as_object(reciever);
	    if (notFree(res))
		AdjustStack(1, res);
	}
	break;

    case primitiveSomeInstance:
	AdjustStack(1, initialInstance(reciever));
	break;

    case primitiveNextInstance:
	AdjustStack(1, nextInstance(reciever));
	break;

    case primitiveNewMethod:
	res = GetStack(2);
	IsInteger(res, temp);
       /* Round size to multiple of object pointer size */
	temp += sizeof(Objptr) - 1;
	temp /= sizeof(Objptr);
       /* Add on number of literals and one word for header */
	temp += 1 + LiteralsOf(argument);
	if ((res = create_new_object(reciever, temp)) != NilPtr) {
	    set_pointer(res, METH_HEADER, argument);
	    AdjustStack(3, res);
	}
	break;

    case primitiveValue:
       /* Check correct number of arguments */
	IntValue(reciever, BLOCK_ARGCNT, temp);
	if (args != temp)
	    break;

	index = size_of(reciever) / sizeof(Objptr);

       /* Copy argument to stack of block */
	for (; args > 0; args--) {
	    otemp = get_pointer(current_context, *stack_pointer);
	    Set_object(reciever, --index, otemp);
	    Set_object(current_context, (*stack_pointer)++, NilPtr);
	}

       /* Remove the block from top of stack too */
        Set_object(current_context, (*stack_pointer)++, NilPtr);

       /* Set new block context registers */
	Set_integer(reciever, BLOCK_SP, index);
	Set_object(reciever, BLOCK_IP, get_pointer(reciever, BLOCK_IIP));
	Set_object(reciever, BLOCK_CALLER, current_context);

       /* Switch to context */
	current_context = reciever;
	newContextFlag = 1;
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
	Set_object(current_context, (*stack_pointer)++, NilPtr);
	Set_object(current_context, (*stack_pointer)++, NilPtr);

       /* Switch to context */
	current_context = reciever;
	newContextFlag = 1;
	return TRUE;

    case primitivePreform:
	/* Redo for new stack order */
	object_incr_ref(reciever);
	args--;
	object_incr_ref(argument);
	Set_object(current_context, (*stack_pointer)++, NilPtr);
	Set_object(current_context, (*stack_pointer)++, NilPtr);
	Set_object(current_context, (*stack_pointer)++, NilPtr);
	AdjustStack(2, reciever);
	object_decr_ref(reciever);
	SendMethod(argument, stack_pointer, args);
	object_decr_ref(argument);
	return TRUE;

    case primitivePreformWithArgs:
	/* Redo for new stack order */
	object_incr_ref(reciever);
	object_incr_ref(argument);
	res = GetStack(2);
	object_incr_ref(res);
	args = length_of(argument);
	for (temp = args; temp >= 0; temp++)
	    Set_object(current_context, --(*stack_pointer),
		       get_pointer(res, temp));
	Set_object(current_context, --(*stack_pointer), reciever);
	object_decr_ref(res);
	object_decr_ref(reciever);
	SendMethod(argument, stack_pointer, args);
	object_decr_ref(argument);
	return TRUE;

    case primitiveEquivalence:
	AdjustStack(2, (reciever == argument) ? TruePointer : FalsePointer);
	break;

    case primitiveClass:
	AdjustStack(1, class_of(reciever));
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
	    AdjustStack(1, NilPtr);
	    suspendActive;
	}
	break;

    case primitiveCoreUsed:
	AdjustStack(1, coreUsed());
	return TRUE;

    case primitiveFreeCore:
	AdjustStack(1, freeSpace());
	return TRUE;

    case primitiveOopsLeft:
	AdjustStack(1, freeOops());
	return TRUE;

    case primitiveQuit:
	running = FALSE;
	return TRUE;

    case primitiveSnapShot:
       /*
        * Fix stack so we save a false pointer onto stack.
        * This is what the saved image will see.
        */
	Set_object(current_context, *stack_pointer, FalsePointer);

       /* Do Snapshot, if we fail, let primitive fail handle problem */
	if (doSnapShot(reciever)) {
	    PushBoolean(TRUE, 1);	/* Now return a TRUE to running system */
	} else
	    return FALSE;
	break;

    case primitiveFileOpen:
	open_buffer(reciever);
	return TRUE;

    case primitiveFileClose:
	close_buffer(reciever);
	return TRUE;

    case primitiveFileNext:
	if (read_buffer(reciever, &temp))
	    AdjustStack(2, get_pointer(CharacterTable, as_integer(temp))
			+ (fixed_size(CharacterTable) / sizeof(Objptr)));
	break;

    case primitiveFileNextPut:
	if (write_buffer(reciever, as_integer(temp)))
	    AdjustStack(2, temp);
	break;

    case primitiveFileGet:
	/* Load second arguemnt with contents of file */
	break;

    case primitiveFilePut:
	/* Save second argument to file */
	break;

    case primitiveFileSize:
	AdjustStack(1, as_integer_object(size_buffer(reciever)));
	break;

    case primitiveFileDir:
	/* Create a array of files in directory of argument */
	break;

    case primitiveInternString:
	{
	    char               *str;

	    str = Cstring(reciever);
	    temp = internString(str);
	    free(str);
	    AdjustStack(1, temp);
	}
	break;

    case primitiveClassComment:
	Set_object(reciever, CLASS_COMMENT, argument);
	AdjustStack(1, argument);
	break;

    case primitiveMethodsFor:
	rootObjects[METHFOR0] = compClass = reciever;
	rootObjects[METHFOR1] = compCatagory = argument;
	AdjustStack(1, reciever);
	break;

    case primitiveError:
	{
	    char               *str;

	    str = Cstring(argument);
	    error(str);
	    free(str);
	    AdjustStack(2, NilPtr);
	}
	break;

    case primitiveDumpObject:
	dump_object(reciever);
	AdjustStack(1, reciever);
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

    default:
    }
    return FALSE;
}
