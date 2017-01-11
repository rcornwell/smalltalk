/*
 * Smalltalk interpreter: Objects known to the interpreter.
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
 * $Id: smallobjs.h,v 1.7 2001/08/29 20:16:35 rich Exp rich $
 *
 * $Log: smallobjs.h,v $
 * Revision 1.7  2001/08/29 20:16:35  rich
 * Added cursor support.
 *
 * Revision 1.6  2001/08/18 16:17:02  rich
 * Added support for LargeInteger and graphics system.
 *
 * Revision 1.5  2001/07/31 14:09:49  rich
 * Added Magnitude, Number and Integer classes.
 *
 * Revision 1.4  2001/01/07 15:14:02  rich
 * Changed location of flags.
 *
 * Revision 1.3  2000/02/02 00:33:34  rich
 * Moved assit functions from primitive.c to here.
 *
 * Revision 1.2  2000/02/01 18:10:03  rich
 * Added stack checking.
 * Added method categories dictionary to Class.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#define NilPtr			((Objptr)0)
#define FalsePointer		((Objptr)2)
#define TruePointer		((Objptr)4)
/* Class ProcessSchedule */
#define SchedulerAssociationPointer ((Objptr)6)
#define SCHED_LIST		0
#define SCHED_INDEX		1

#define DoesNotUnderstandSelector ((Objptr)8)
#define CannotReturnSelector	((Objptr)10)
#define MustBeBooleanSelector	((Objptr)12)
#define UnknownClassVar		((Objptr)14)
#define InterpStackFault	((Objptr)16)
#define SpecialSelectors	((Objptr)18)
#define CharacterTable		((Objptr)20)
#define SmalltalkPointer	((Objptr)22)

/* Size of initial array into symbol table */
#define SymbolTable		((Objptr)24)
#define SYMBOL_SIZE		1024

/* Class Behavoir */
#define BehaviorClass		((Objptr)26)
#define SUPERCLASS		0	/* Superclass of object */
#define SUBCLASSES		1	/* Subclasses of this object */
#define METHOD_DICT		2	/* Methods dictionary */
#define CLASS_FLAGS		3	/* Flags */

/* Class Class */
#define ClassClass		((Objptr)28)
#define CLASS_NAME		4	/* Name of class */
#define CLASS_VARS		5	/* Instance variable list */
#define CLASS_COMMENT		6	/* Comment string of class */
#define CLASS_CAT		7	/* Class catagory string */
#define CLASS_DICT 		8	/* Class variable list */
#define CLASS_POOL		9	/* Class Pool vairables */
#define CLASS_METHCAT		10	/* Dictionary of method categories */

/* Flags for class flags field */
#define CLASS_PTRS		2	/* Object has pointers */
#define CLASS_BYTE		4	/* Object is byte indexable */
#define CLASS_INDEX		8	/* Object is indexable */

#define CLASS_SIZE		11	/* Size of Class */

/* Class Metaclass */
#define MetaClass		((Objptr)30)
#define META_INSTCLASS		11

/* Simple built in classes */
#define ObjectClass		((Objptr)32)
#define UndefinedClass		((Objptr)34)
#define BooleanClass		((Objptr)36)
#define TrueClass		((Objptr)38)
#define FalseClass		((Objptr)40)
#define MagnitudeClass		((Objptr)42)
#define NumberClass		((Objptr)44)
#define IntegerClass		((Objptr)46)
#define SmallIntegerClass	((Objptr)48)
#define FloatClass		((Objptr)50)
#define LargePosIntegerClass	((Objptr)52)
#define LargeNegIntegerClass	((Objptr)54)

/* Class MethodContext */
#define MethodContextClass	((Objptr)56)
#define BLOCK_SENDER		0	/* Who Sent message */
#define BLOCK_IP		1	/* Current Instruct pointer */
#define BLOCK_SP		2	/* Current Stack Pointer */
#define BLOCK_METHOD		3	/* Method Pointer */
#define BLOCK_UNUSED		4	/* Not used in methods */
#define BLOCK_REC		5	/* Object Method (self) */
#define BLOCK_ARGCNT		6	/* Number of arguments */
#define BLOCK_STACK		7	/* Start of stack */

#define BlockContextClass	((Objptr)58)
#define BLOCK_CALLER		0	/* Who called context */
#define BLOCK_HOME		3	/* Home for block context */
#define BLOCK_IIP		4	/* Initial Instruction Pointer */
#define BLOCK_NOTUSED		5	/* Reciever in methodContext */

/* Class CompiledMethod */
#define CompiledMethodClass	((Objptr)60)
#define METH_DESCRIPTION	0
#define METH_HEADER		1
#define METH_LITSTART		2
#define METH_NUMLITS		0x000001FE
#define METH_NUMTEMPS		0x0001FE00
#define METH_STACKSIZE		0x07FE0000
#define METH_FLAG		0x78000000
#define METH_RETURN		0x68000000
#define METH_SETINST		0x70000000
#define METH_EXTEND		0x78000000
#define EMETH_PRIM		0x000003FE
#define EMETH_ARGS		0x01FE0000

/* Accessing method header */
#define LiteralsOf(hdr)		(((hdr) & METH_NUMLITS)>>1)
#define TempsOf(hdr)		(((hdr) & METH_NUMTEMPS)>>9)
#define StackOf(hdr)		(((hdr) & METH_STACKSIZE)>>17)
#define FlagOf(hdr)		((hdr) & METH_FLAG)
#define ArgsOf(hdr)		(((hdr) & METH_FLAG)>>27)
#define EArgsOf(ehdr)		(((ehdr) & EMETH_ARGS)>>17)
#define PrimitiveOf(ehdr)	(((ehdr) & EMETH_PRIM)>>1)

/* Class MethodInfoClass */
#define MethodInfoClass		((Objptr)62)
#define METHINFO_SOURCE		0
#define METHINFO_POS		1
#define METHINFO_CAT		2

/* Class Point */
#define PointClass		((Objptr)64)
#define XINDEX			0
#define YINDEX			1

/* Class Message */
#define MessageClass		((Objptr)66)
#define MESSAGE_ARGS		0
#define MESSAGE_SELECT		1
#define MESSAGE_SIZE		2

/* Class CharacterValue */
#define CharacterClass		((Objptr)68)
#define CHARVALUE		0

/* Class Link */
#define LinkClass		((Objptr)70)
#define LINK_NEXT		0

/* Class SymLink */
#define SymLinkClass		((Objptr)72)
#define SYM_VALUE		1

/* Array classes */
#define StringClass		((Objptr)74)
#define ArrayClass		((Objptr)76)

/* Collection classes */
#define SSetClass		((Objptr)78)
#define DictionaryClass		((Objptr)80)
#define IdentityDictionaryClass	((Objptr)82)
/* Class Dictionary */
#define DICT_TALLY		0
#define DICT_VALUES		1
#define DICT_KEY		2

/* Class LinkedList */
#define LINK_FIRST		0
#define LINK_LAST		1

/* Class Semaphore (Subclass of Linked List) */
#define SEM_SIGNALS		2

/* Class Process */
#define PROC_SUSPEND		1
#define PROC_PRIO		2


/* Class Association */
#define AssociationClass	((Objptr)84)
#define ASSOC_KEY		0
#define ASSOC_VALUE		1


/* Class Stream */
#define STREAMARRAY		0
#define STREAMINDEX		1
#define STREAMREADL		2
#define STREAMWRITEL		3


/* Class Filename */
#define FileClass		((Objptr)86)
#define FILENAME		0
#define FILEMODE		1
#define FILEPOS			2

/* BitBlt Class */
#define DEST_FORM		0
#define SRC_FORM		1
#define HALF_FORM		2
#define COMB_RULE		3
#define DEST_X			4
#define DEST_Y			5
#define DEST_WIDTH		6
#define DEST_HEIGHT		7
#define CLIP_X			8
#define CLIP_Y			9
#define CLIP_WIDTH		10
#define CLIP_HEIGHT		11
#define SRC_X			12
#define SRC_Y			13

/* Class CharacterScanner */
#define CHAR_TEXT		14
#define CHAR_TEXT_POS		15
#define CHAR_XTABLE		16
#define CHAR_STOPX		17
#define CHAR_EXCEPT		18
#define CHAR_PRINTING		19
#define CHAR_ENDRUNCODE		20

/* Form Class */
#define FORM_WIDTH		0		/* DisplayObject */
#define FORM_HEIGHT		1		/* DisplayObject */
#define FORM_OFFSET		2		/* DisplayObject */
#define FORM_BITMAP		3		/* Form */
#define FORM_MASK		4		/* OpaqueForm */

/* Event types */
#define	EVENT_TIMER		0		/* Sent to tick_semaphore */
#define	EVENT_CHAR		1
#define	EVENT_MOUSEPOS		2
#define	EVENT_MOUSEBUT		3
#define	EVENT_RESIZE		4

Objptr              MakeString(char *);
char               *Cstring(Objptr);
Objptr              internString(char *);
void                AddSelectorToIDictionary(Objptr, Objptr, Objptr);
Objptr              FindSelectorInIDictionary(Objptr, Objptr);
Objptr              FindKeyInIDictionary(Objptr, Objptr);
Objptr              new_IDictionary();
void                AddSelectorToDictionary(Objptr, Objptr);
Objptr              FindSelectorInDictionary(Objptr, Objptr);
Objptr              create_association(Objptr, Objptr);
Objptr              new_Dictionary();
void                AddSelectorToSet(Objptr, Objptr);
Objptr              FindSelectorInSet(Objptr, Objptr);
Objptr              new_Set();

