
/*
 * Smalltalk interpreter: Initialize basic Known and builtin objects.
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
#include <malloc.h>
#include <memory.h>
#endif
#ifdef _WIN32
#include <stddef.h>
#include <windows.h>
#include <math.h>

#define malloc(x)	GlobalAlloc(GMEM_FIXED, x)
#define free(x)		GlobalFree(x)
#endif

#include "smalltalk.h"
#include "object.h"
#include "smallobjs.h"
#include "interp.h"
#include "primitive.h"
#include "fileio.h"
#include "lex.h"
#include "dump.h"
#include "symbols.h"
#include "parse.h"

struct _class_template {
	    Objptr              object;
	    int                 flags;
	    int                 size;
	    Objptr              superclass;
	    char               *name;
	    char               *instvars;
	} class_template[] = {
    /* Order is important for reference counting. */
    { ClassClass, CLASS_PTRS, CLASS_SIZE, BehaviorClass, "Class",
	    "superclass subclasses methoddict flags"
	    " name vars comment category classvars pool"
    },
    { BehaviorClass, CLASS_PTRS, CLASS_NAME + 1, ObjectClass, "Behavior",
	    "superclass subclasses methoddict flags"
    },
    { MetaClass, CLASS_PTRS, META_INSTCLASS + 1, ClassClass, "MetaClass",
	    "superclass subclasses methoddict flags"
	    " name vars comment category classvars pool instanceClass"
    },
    { ObjectClass, 0, 0, NilPtr, "Object", NULL },
    { StringClass, CLASS_BYTE | CLASS_INDEX, 0, ObjectClass, "String", NULL },
    { ArrayClass, CLASS_PTRS | CLASS_INDEX, 0, ObjectClass, "Array", NULL },
    { MethodContextClass, CLASS_PTRS | CLASS_INDEX, BLOCK_STACK,
	    ObjectClass, "MethodContext",
	    "sender ip sp method unused reciever argcount"
    },
    { BlockContextClass, CLASS_PTRS | CLASS_INDEX,
	    BLOCK_STACK, ObjectClass, "BlockContext",
	    "caller ip sp home iip unused argcount"
    },
    { PointClass, 0, 2, ObjectClass, "Point", "x y" },
    { MessageClass, 0, MESSAGE_SIZE, ObjectClass, "Message", "args selector" },
    { CharacterClass, 0, 1, ObjectClass, "Character", "value" },
    { FloatClass, 0, 4, ObjectClass, "Float", NULL },
    { UndefinedClass, 0, 0, ObjectClass, "Undefined", NULL },
    { TrueClass, 0, 0, BooleanClass, "True", NULL },
    { FalseClass, 0, 0, BooleanClass, "False", NULL },
    { LinkClass, CLASS_PTRS, 1, ObjectClass, "Link", "next" },
    { SymLinkClass, CLASS_PTRS, 2, LinkClass, "Symbol", "next value" },
    { BooleanClass, 0, 0, ObjectClass, "Boolean", NULL },
    { CompiledMethodClass, CLASS_INDEX, 2, ObjectClass, "CompiledMethod",
	    "description header"
    },
    { MethodInfoClass, CLASS_PTRS, 3, ObjectClass, "MethodInfo",
	    "sourceFile sourcePos category"
    },
    { IdentityDictionaryClass, CLASS_PTRS | CLASS_INDEX, 2, DictionaryClass,
	    "IdentityDictionary", "tally values"
    },
    { DictionaryClass, CLASS_PTRS | CLASS_INDEX, 1, SSetClass, "Dictionary",
	    "tally"
    },
    { AssociationClass, CLASS_PTRS, 2, ObjectClass, "Association",
		 "key value" },
    { SSetClass, CLASS_PTRS | CLASS_INDEX, 1, ObjectClass, "Set", "tally" },
    { SmallIntegerClass, 0, 0, ObjectClass, "SmallInteger", NULL }
};

char               *specialSelector[32] =
{
    "+", "-", "<", ">", "<=", ">=", "=", "~=", "*",
    "/", "\\", "@", "bitShift:", "\\\\", "bitAnd:", "bitOr:", "at:",
    "at:put:", "size", "next", "nextPut:", "atEnd", "==", "class",
    "blockCopy:",
    "value", "value:", "do:", "new", "new:", "x", "y"};

struct _prims {
     Objptr		class;
     char		*selector;
     int		args;
     int		primnum;
     char		*cat;
} prims[] = {
    { ClassClass, "comment:", 1, primitiveClassComment, "accessing"},
    { ClassClass, "methodsFor:", 1, primitiveMethodsFor, "creating"}
};

void fileinMethods(Objptr);

/*
 * Initialize the classes from template.
 */
static void
create_classes()
{
    int                 i;
    Objptr              op;
    struct _class_template *ct;

    for (i = 0; i < (sizeof(class_template) / sizeof(struct _class_template));

	 i++) {
	ct = &class_template[i];
	op = ct->object;
	create_object(op, CLASS_PTRS, ClassClass, CLASS_SIZE * sizeof(Objptr));
	Set_integer(op, CLASS_FLAGS, (ct->size * 8) + (ct->flags / 2));
    }
}

/*
 * Fill in rest of class data.
 */
static void
name_classes()
{
    int                 i;
    Objptr              op;
    Objptr              name;
    Objptr		assoc;
    Objptr		meta;
    struct _class_template *ct;

    /* Finish initializing classes */
    for (i=0; i<(sizeof(class_template)/sizeof(struct _class_template)); i++) {
	ct = &class_template[i];
	op = ct->object;
	name = MakeString(ct->name);
	Set_object(op, CLASS_NAME, name);
	assoc = create_association(internString(ct->name), op);
	if (ct->instvars != NULL)
	    Set_object(op, CLASS_VARS, MakeString(ct->instvars));
	else
	    Set_object(op, CLASS_VARS, MakeString(""));
	Set_object(op, SUPERCLASS, ct->superclass);

	/* Make metaclass to follow class */
	meta = create_new_object(MetaClass, 0);
	Set_integer(meta, CLASS_FLAGS, (ct->size * 8) + (ct->flags / 2));
	Set_object(meta, CLASS_NAME, name);
	Set_object(meta, META_INSTCLASS, op);
	Set_integer(meta, CLASS_FLAGS, (CLASS_SIZE * 8) + (CLASS_PTRS / 2));

	/* Point class class to new meta */
	set_class_of(op, meta);
	AddSelectorToDictionary(SmalltalkPointer, assoc);
    }

    /* Fix up MetaClass's superclasses */
    for (i=0; i<(sizeof(class_template)/sizeof(struct _class_template)); i++) {
	ct = &class_template[i];
	op = ct->object;
	Set_object(class_of(op), SUPERCLASS, class_of(ct->superclass));
    }

    /* Lastly fix Objects Metaclass's superClass to Class */
    Set_object(class_of(ObjectClass), SUPERCLASS, ClassClass);
}

/*
 * Install object into symbol table.
 */
void
makeSymbol(Objptr op, char *str)
{
    int                 hash;
    char               *ptr;
    int                 size;
    int                 symbase;

   /* Compute a hash value */
    for (hash = 0, ptr = str; *ptr != '\0';
		 hash = 0x0fffffff & ((hash << 2) + (0xff & *ptr++))) ;

    symbase = fixed_size(SymbolTable) / sizeof(Objptr);

   /* Find first link in symboltable. */
    size = length_of(SymbolTable);
    hash = hash % size;

   /* Create a new entry */
    Set_object(op, SYM_VALUE, MakeString(str));
    Set_object(op, LINK_NEXT, get_pointer(SymbolTable, hash + symbase));
    Set_object(SymbolTable, hash + symbase, op);
}

/*
 * Load Bootstrap primitive methods into system.
 */
void
loadPrimitives()
{
    int			i;
    Objptr		method;

    for (i = 0; i < (sizeof(prims) / sizeof(struct _prims)); i++) {
        method = create_new_object(CompiledMethodClass, 1);
        /* Build header */
        Set_object(method, METH_HEADER,
		 as_oop(METH_EXTEND | (METH_NUMLITS & (1<<1))));
        Set_object(method, METH_LITSTART,
		 as_oop((EMETH_PRIM & (prims[i].primnum << 1)) |
			(EMETH_ARGS & (prims[i].args << 16))));

        /* Add it to class */
        AddSelectorToClass(prims[i].class, prims[i].selector,
		internString(prims[i].cat), method, 0);
    }
}

/*
 * Load initial bootstrap objects into object memory.
 */
void
smallinit()
{
    Objptr              temp;
    int                 i;

    noreclaim = TRUE;		/* Don't allow a reclaim until done */

   /*
    * Initialize kernel known classes and objects, these object's can't
    *be moved without recompiling the system.
    */
    create_classes();
    create_object(FalsePointer, 0, FalseClass, 0);
    create_object(TruePointer, 0, TrueClass, 0);
    create_object(SchedulerAssociationPointer, 0, NilPtr, 4 * sizeof(Objptr));
    create_object(DoesNotUnderstandSelector, 0, SymLinkClass,
		  2 * sizeof(Objptr));
    create_object(CannotReturnSelector, 0, SymLinkClass, 2 * sizeof(Objptr));
    create_object(MustBeBooleanSelector, 0, SymLinkClass, 2 * sizeof(Objptr));
    create_object(UnknownClassVar, 0, SymLinkClass, 2 * sizeof(Objptr));
    create_object(SpecialSelectors, CLASS_PTRS | CLASS_INDEX, ArrayClass,
		  32 * sizeof(Objptr));
    create_object(CharacterTable, CLASS_PTRS | CLASS_INDEX, ArrayClass,
		  256 * sizeof(Objptr));
    create_object(SymbolTable, CLASS_PTRS | CLASS_INDEX, ArrayClass,
		  SYMBOL_SIZE * sizeof(Objptr));

    create_object(SmalltalkPointer, CLASS_PTRS | CLASS_INDEX,
		  DictionaryClass, (32 + 1) * sizeof(Objptr));
    Set_integer(SmalltalkPointer, DICT_TALLY, 0);

   /* Load known objects that can never be removed */
    rootObjects[SMALLTLK] = SmalltalkPointer;
    rootObjects[SYMTAB] = SymbolTable;
    rootObjects[CHARTAB] = CharacterTable;
    rootObjects[OBJECT] = ObjectClass;
    rootObjects[SPECSEL] = SpecialSelectors;
    rootObjects[TRUEOBJ] = TruePointer;
    rootObjects[FALSEOBJ] = FalsePointer;
    rootObjects[SELECT0] = DoesNotUnderstandSelector;
    rootObjects[SELECT1] = CannotReturnSelector;
    rootObjects[SELECT2] = MustBeBooleanSelector;
    rootObjects[SELECT3] = UnknownClassVar;

   /* Rebuild free list */
    rebuild_free();

   /* Fill in class names */
    name_classes();

    makeSymbol(DoesNotUnderstandSelector, "doesNotUnderstand:");
    makeSymbol(CannotReturnSelector, "cannotReturn");
    makeSymbol(MustBeBooleanSelector, "mustBeBoolean");
    makeSymbol(UnknownClassVar, "unknownClassVar");
   /* Build Character table */
    for (i = 0; i < 256; i++) {
	temp = create_new_object(CharacterClass, 0);
	Set_integer(temp, CHARVALUE, i);
	Set_object(CharacterTable, i, temp);
    }

   /* Add known objects to symbol table */
    AddSelectorToDictionary(SmalltalkPointer,
	create_association(internString("true"), TruePointer));
    AddSelectorToDictionary(SmalltalkPointer,
	create_association(internString("false"), FalsePointer));
    AddSelectorToDictionary(SmalltalkPointer,
	create_association(internString("nil"), NilPtr));
    AddSelectorToDictionary(SmalltalkPointer,
	create_association(internString("Smalltalk"), SmalltalkPointer));
    AddSelectorToDictionary(SmalltalkPointer,
	create_association(internString("SpecialSelectors"), SpecialSelectors));
    AddSelectorToDictionary(SmalltalkPointer,
	create_association(internString("Processor"),
				 SchedulerAssociationPointer));
    AddSelectorToDictionary(SmalltalkPointer,
	create_association(internString("sourceFiles"),
				 create_new_object(ArrayClass, 4)));
    AddSelectorToDictionary(SmalltalkPointer,
	create_association(internString("charsymbols"), CharacterTable));

    for (i = 0; i < 32; i++)
	if (specialSelector[i] != NULL)
	    Set_object(SpecialSelectors, i,
		       internString(specialSelector[i]));
    loadPrimitives();
    noreclaim = FALSE;		/* Ok, safe now to free unused junk */
}

void
parsefile(char *str)
{
    Objptr              fp;
    Objptr		meth;
    Objptr		newContext;
    int			header;
    int			stacksize;
    char               *ptr;
    int			filein = FALSE;

    if ((fp = new_file(str, "r")) == NilPtr)
	return;

    ptr = get_chunk(fp);
    while ((ptr != NULL)) {
	if (*ptr != '\0') {
	    dump_string(ptr);
            meth = CompileForExecute(ptr);

            header = get_pointer(meth, METH_HEADER);
            stacksize = StackOf(header) + TempsOf(header);

            /* Initialize a new method. */
            newContext = create_new_object(MethodContextClass, stacksize);
	    object_incr_ref(newContext);
    	    rootObjects[CURCONT] = newContext;
            Set_object(newContext, BLOCK_SENDER, newContext);
            Set_integer(newContext, BLOCK_IP, 
	    	sizeof(Objptr) *(LiteralsOf(header) + METH_LITSTART));
            Set_integer(newContext, BLOCK_SP,
            	size_of(newContext) / sizeof(Objptr));
            Set_object(newContext, BLOCK_METHOD, meth);
            Set_integer(newContext, BLOCK_IIP, 0);
            Set_object(newContext, BLOCK_REC, fp);
            Set_integer(newContext, BLOCK_ARGCNT, 0);
            current_context = newContext;
            newContextFlag = 1;
	    rootObjects[TEMP1] = NilPtr;
            interp();
	    /* Break cycle */
            Set_object(newContext, BLOCK_SENDER, NilPtr);
	    object_decr_ref(newContext);
	    if (filein) 
		fileinMethods(fp);
	} else
	    free(ptr);
	filein = peek_for(fp, '!');
	ptr = get_chunk(fp);
    }
    close_buffer(fp);
}

void
fileinMethods(Objptr fp)
{
    char	*ptr;
    int		position;

    position = get_pointer(fp, FILEPOS);
    ptr = get_chunk(fp);
    while ((ptr != NULL)) {
	if (*ptr != '\0') {
	    dump_string(ptr);
	    CompileForClass(ptr, compClass, compCatagory, position);
	} else {
	    free(ptr);
            break;
	}
        position = get_pointer(fp, FILEPOS);
	ptr = get_chunk(fp);
    }
}
