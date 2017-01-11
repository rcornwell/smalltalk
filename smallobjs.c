/*
 * Smalltalk smallobjs: Routines for modifying smalltalk objects.
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
 * $Log: smallobjs.c,v $
 * Revision 1.2  2001/07/31 14:09:49  rich
 * Fixed to compile under new cygwin.
 *
 * Revision 1.1  2001/07/28 01:54:16  rich
 * Initial revision
 *
 *
 *
 */

#ifndef lint
static char        *rcsid =
	"$Id: smallobjs.c,v 1.2 2001/07/31 14:09:49 rich Exp $";

#endif

#include "smalltalk.h"
#include "object.h"
#include "smallobjs.h"
#include "interp.h"
#include "fileio.h"
#include "dump.h"

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
 * Find the selector for an object in a identity dictionary.
 */
Objptr
FindKeyInIDictionary(Objptr dict, Objptr key)
{
    int                 length = length_of(dict);
    int                 index;
    Objptr		values;


    values = get_pointer(dict, DICT_VALUES);
    for (index = 0; index < length; index++) {
	if (key == get_pointer(values, index))
	    return get_pointer(dict, index + DICT_KEY);
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

