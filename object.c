/*
 * Smalltalk interpreter: Object memory system.
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
 * $Log: object.c,v $
 * Revision 1.10 2020/07/12 16:00:00  rich
 * Support for 64 bit compiler.
 * No longer store pointers in class word.
 * Store offset into region.
 * Coverity cleanup.
 *
 * Revision 1.9  2001/08/29 20:16:35  rich
 * Moved region definition from object.h.
 *
 * Revision 1.8  2001/08/18 16:17:01  rich
 * Moved error routines to system.h
 *
 * Revision 1.7  2001/07/31 14:09:48  rich
 * Fixed to compile under new cygwin
 * Made sure compile without INLINE_OBJECT_MEM works correctly.
 * Call flushMethod whenever we remove a CompiledMethod object.
 * Flush method cache after a reclaim.
 *
 * Revision 1.6  2001/01/13 15:53:01  rich
 * Increases growsize to 512.
 * Commented out some debuging code.
 * Don't compact a region that is less then 10% free.
 * Check files after we free objects, to close files that were freed.
 *
 * Revision 1.5  2000/08/19 17:40:15  rich
 * Make sure bytes are returned unsigned.
 *
 * Revision 1.4  2000/03/08 01:36:19  rich
 * Dump stack on Set out of bounds error.
 *
 * Revision 1.3  2000/02/01 18:09:57  rich
 * Increased size of root objects.
 * reclaimSpace now global since it should be called after image load.
 *
 * Revision 1.2  2000/01/03 16:23:22  rich
 * Moved object pointer out to a new structure to reduce access cost.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */


#include <stdint.h>
#include "smalltalk.h"
#include "object.h"
#include "smallobjs.h"
#include "dump.h"
#include "interp.h"
#include "fileio.h"
#include "system.h"

/*
 * Placed at begining of each region. Used to track free space within
 * the region.
 */
typedef struct _region {
    struct _region     *next;			/* Pointer to next region */
    unsigned int        freespace;		/* Space available */
    unsigned int        totalspace;		/* Size of region */
    unsigned char      *base;			/* Pointer to first word */
    unsigned char      *limit;			/* Pointer to last word */
    unsigned int        freeptrs[ALLOCSIZE + 1]; /* Index into region */
} region           , *Region;

int                 growsize = 512;		/* Region grow rate */
Region              regions = NULL;		/* Memory regions */
Region              curregion = NULL;		/* Pointer to current region */
Otentry             otable = NULL;		/* Pointer to object info */
Objhdr		   *objmem = NULL;		/* Pointer to objects */
unsigned int       *olist = NULL;               /* Holds list of free objects */
unsigned int        freeobj;			/* Next free object pointer */
int                 otsize;			/* Size of object table */
int		    noreclaim = TRUE;		/* Don't allow reclaimes */
    

Objptr              rootObjects[ROOTSIZE];
static objhdr       nilhdr;

#define wordsize(x)  (((x) + (sizeof(int) - 1)) & ~(sizeof(int) - 1))
#define freebin(x)   (((x) < (ALLOCSIZE * sizeof(Objptr)))? \
	    		((x) / sizeof(Objptr)):ALLOCSIZE)

static INLINE Objptr new_object_pointer(int, int, int, Objhdr);
static INLINE void  free_object_pointer(Objptr);
static INLINE void  add_to_free(Objhdr);
static Objhdr       allocate_chunk(int);
static Objhdr       attempt_to_allocate_incurrent(int);
static Objhdr       attempt_to_allocate(int);
static int          new_region(int);
static void         compact_region();
static INLINE int   last_pointer_of(Objptr);
static void         mark_all_other_objects(Objptr);
static INLINE int   decr_ref_count(Objptr);

#ifndef INLINE_OBJECT_MEM
/*
 * Testing functions.
 * Convert to INLINEs after working.
 */

/* Is op a object */
INLINE int
is_object(Objptr op)
{
    return (op & 1) == 0;
}

/* Is op a integer */
INLINE int
is_integer(Objptr op)
{
    return (op & 1) == 1;
}

INLINE int
notFree(Objptr op)
{
    return !otable[op / 2].free;
}

/* Check if object is indexable */
INLINE int
is_indexable(Objptr op)
{
    return otable[op / 2].indexable;
}

INLINE int
is_byte(Objptr op)
{
    return otable[op / 2].byte;
}

INLINE int
is_word(Objptr op)
{
    return !otable[op / 2].ptrs;
}

/* Convert value to object */
INLINE              Objptr
as_object(int value)
{
    return (value & (~1));
}

/* Convert object to integer */
INLINE int
as_oop(Objptr op)
{
    return op | 1;
}

/* Conversion Functions. */

/* Get integer value of object */
INLINE int
as_integer(int value)
{
    return value >> 1;
}

/* Return integer as a object */
INLINE              Objptr
as_integer_object(int value)
{
    return (value << 1) | 1;
}

/* Accessing Functions. */

INLINE              Objhdr
get_object_pointer(Objptr op)
{
    return objmem[op / 2];
}

INLINE unsigned char    *
get_object_base(Objptr op)
{
    return (unsigned char *) (get_object_pointer(op) + 1);
}

INLINE int
get_object_refcnt(Objptr op)
{
    return otable[op / 2].refcnt;
}

INLINE void
set_object_refcnt(Objptr op, int cnt)
{
    otable[op / 2].refcnt = cnt;
}

INLINE void
set_object_pointer(Objptr op, Objhdr addr)
{
    objmem[op / 2] = addr;
}

/* Get value in object */
INLINE              Objptr
get_pointer(Objptr op, int offset)
{
    return ((Objptr *) get_object_base(op))[offset];
}

INLINE void
set_pointer(Objptr op, int offset, int value)
{
    ((Objptr *) get_object_base(op))[offset] = value;
}

/* Return value of object, but convert it to a native integer. */
INLINE int
get_integer(Objptr op, int offset)
{
    return as_integer(((Objptr *) get_object_base(op))[offset]);
}

INLINE int
get_word(Objptr op, int offset)
{
    return ((int *) get_object_base(op))[offset];
}

INLINE int
set_word(Objptr op, int offset, int value)
{
    return ((int *) get_object_base(op))[offset] = value;
}

INLINE int
get_byte(Objptr op, int offset)
{
    return 0xff & (((char *) get_object_base(op))[offset]);
}

INLINE int
set_byte(Objptr op, int offset, char value)
{
    return ((char *) get_object_base(op))[offset] = value;
}

/* Get class of object */
INLINE              Objptr
class_of(Objptr op)
{
    if (is_object(op) && !notFree(op)) {
	error("Attempt to get class of free object");
    }
    return is_object(op)? get_object_pointer(op)->oclass :
				SmallIntegerClass;
}

/* Size of an object in bytes. */
INLINE unsigned int
size_of(Objptr op)
{
    return get_object_pointer(op)->size;
}

/*
 * Return fixed size of object in bytes.
 */

INLINE unsigned int
fixed_size(Objptr op)
{
    Objptr              class = class_of(op);
    int                 size;

    size = (class == NilPtr) ? 0 : (get_integer(class, CLASS_FLAGS)/ 8);
    return sizeof(Objptr) * size;
}

/* Reference Counting. */
INLINE void
object_incr_ref(Objptr op)
{
    if (is_object(op)) {
	int                 ncnt;

	if ((ncnt = get_object_refcnt(op)) != MAXREFCNT)
	    set_object_refcnt(op, ncnt + 1);
    }
}

INLINE void
object_decr_ref(Objptr op)
{
    if (is_object(op)) {
	int                 ncnt;

       /* Don't change objects at max count */
	if ((ncnt = get_object_refcnt(op)) != MAXREFCNT) {
	    set_object_refcnt(op, ncnt - 1);
	   /* If count is zero, remove object */
	    if (ncnt == 1) 
		free_all_other_objects(op);
	}
    }
}
#endif

/* Creation. */

/*
 * Create a new object of class class and size additional words.
 */
Objptr
create_new_object(Objptr nclass, int size)
{
    Objhdr              new_ptr;
    Objptr              new_obj;
    Objptr              obj_flag;
    char               *addr;
    int                 allocsize;
    int                 fixed_size;
    int                 ptrs;
    int                 indexable;
    int                 byte;

   /* Get type of object */
    obj_flag = get_pointer(nclass, CLASS_FLAGS);
    ptrs = (obj_flag & CLASS_PTRS) != 0;
    byte = (obj_flag & CLASS_BYTE) != 0;
    indexable = (obj_flag & CLASS_INDEX) != 0;
   /* Need to inline this since otherwise we get size of Class */
    fixed_size = (obj_flag >> 4) * sizeof(Objptr);

   /* Don't create a non indexable object larger than it's fixed size */
    if ((!indexable) && size > 0) 
	return NilPtr;

   /* Compute size of object */
    if (!byte)
	size *= sizeof(Objptr);

   /* Round allocation size to objptr boundry */
    allocsize = wordsize(size);

   /* Add on fixed class size */
    allocsize += fixed_size;

   /* Try to grab space for object */
    if ((new_ptr = allocate_chunk(allocsize)) == NULL) 
	return NilPtr;

   /* Now get a new pointer */
    if ((new_obj = new_object_pointer(ptrs, indexable, byte, new_ptr))
	== NilPtr) {
	add_to_free(new_ptr);
	return NilPtr;
    }

   /* Initialize object */
    addr = (char *) (new_ptr + 1);
    memset(addr, 0, allocsize);
    new_ptr->oclass = nclass;
    new_ptr->size = size + fixed_size;
    object_incr_ref(nclass);
    return new_obj;
}

/*
 * Install a new object.
 */
int                *
create_object(Objptr op, int flags, Objptr nclass, int size)
{
    Objhdr              new_ptr;
    char               *addr;
    int                 allocsize;

   /* Round to integer size */
    allocsize = wordsize(size);

   /* Try to grab space for object */
    if ((new_ptr = attempt_to_allocate(allocsize)) == NULL) {
	new_region(allocsize);
	if ((new_ptr = attempt_to_allocate(allocsize)) == NULL) {
	    dump_string("Out of space");
	    return NULL;
	}
    }
   /* Now get a new pointer */
    op /= 2;
    if ((otable[op].free) != 1) {
	add_to_free(new_ptr);
        dump_string("Object already exists");
	return NULL;
    }
    objmem[op] = new_ptr;
    otable[op].refcnt = 0;
    otable[op].free = 0;
    otable[op].ptrs = (flags & CLASS_PTRS) != 0;
    otable[op].indexable = (flags & CLASS_INDEX) != 0;
    otable[op].byte = (flags & CLASS_BYTE) != 0;

   /* Initialize object */
    addr = (char *) (new_ptr + 1);
    memset(addr, 0, allocsize);
    new_ptr->oclass = nclass;
    new_ptr->size = size;
    object_incr_ref(nclass);		/* Reference count Class */
    return (int *) (new_ptr + 1);
}

/*
 * After we reload an image, we need to rebuild free list and compute
 * new reference counts.
 */
void
rebuild_free()
{
    unsigned int        i;

    freeobj = NilPtr;
   /* Add all free objects into free list */
    for (i = otsize - 1; i > 0; i--) {
	if (otable[i].free) {
	    olist[i] = freeobj;
	    freeobj = i;
	}
    }

}

/*
 * Create a new object table. (number is in units of 1k).
 */
int
new_objectable(int number)
{
    int                 i;
    Otentry             ptr;
    Objhdr	       *optr;

   /* Free any existing objects */
    if (otable != NULL)
	free(otable);
    if (objmem != NULL)
	free(objmem);
    if (olist != NULL)
	free(olist);

    while (regions != NULL) {
	Region              reg = regions->next;

	free(regions);
	regions = reg;
    }

    otsize = number * 1024;
    if ((otable = (Otentry) malloc(sizeof(otentry) * otsize)) == NULL)
	return FALSE;

    if ((objmem = (Objhdr *) malloc(sizeof(Objhdr) * otsize)) == NULL) {
	free(otable);
	otable = NULL;
	return FALSE;
    }

    if ((olist = (unsigned int *) malloc(sizeof(Objptr) * otsize)) == NULL) {
        free(objmem);
	free(otable);
        objmem = NULL;
	otable = NULL;
	return FALSE;
    }

   /* Clear and free all objects. */
    for (i = otsize - 1, ptr = &otable[i], optr = &objmem[i];
	 i > ((int) NilPtr);
	 i--, ptr--, optr--) {
	*optr = &nilhdr;
	ptr->refcnt = 0;
	ptr->free = 1;
	ptr->ptrs = 0;
	ptr->indexable = 0;
	ptr->byte = 0;
        olist[i] = 0;
    }

   /* Intialize the null object. */
    objmem[((int) NilPtr) / 2] = &nilhdr;
    otable[((int) NilPtr) / 2].refcnt = MAXREFCNT;
    otable[((int) NilPtr) / 2].free = 0;
    otable[((int) NilPtr) / 2].indexable = 0;
    otable[((int) NilPtr) / 2].byte = 0;
    otable[((int) NilPtr) / 2].ptrs = 0;

    nilhdr.oclass = UndefinedClass;	/* For now */
    nilhdr.size = 0;

    for (i = 0; i < (sizeof(rootObjects) / sizeof(Objptr)); i++)
	rootObjects[i] = NilPtr;

    new_region(growsize);
    return TRUE;
}

/* Assignment */
void
Set_object(Objptr op, int offset, Objptr newvalue)
{
    if ((unsigned int)offset > (size_of(op)/sizeof(Objptr)) || offset < 0) {
	extern void dump_stack(Objptr);

	dump_stack(NilPtr);
	error("Out of bounds set");
    }
    object_incr_ref(newvalue);
    object_decr_ref(get_pointer(op, offset));
    set_pointer(op, offset, newvalue);
}

/* Set object at offset to a integer value */
void
Set_integer(Objptr op, int offset, int value)
{
    if ((unsigned int)offset > (size_of(op)/sizeof(Objptr)) || offset < 0) {
	extern void dump_stack(Objptr);

	dump_stack(NilPtr);
	error("Out of bounds set");
    }
    object_decr_ref(get_pointer(op, offset));
    set_pointer(op, offset, as_integer_object(value));
}

/* Set class of object */
void
set_class_of(Objptr op, Objptr newClass)
{
    if (is_object(op)) {
	object_incr_ref(newClass);
	object_decr_ref(class_of(op));
	get_object_pointer(op)->oclass = newClass;
    }
}

/* Can integer be held in object pointer */
INLINE int
canbe_integer(int value)
{
    int                 temp = value << 1; /* So as not to be optimized out. */

    return (value == (temp >> 1));
}


/*
 * Return number of index slots in a object.
 */
INLINE int
length_of(Objptr op)
{
    int                 size;

    if (is_indexable(op) == 0)
	return -1;
    size = size_of(op) - fixed_size(op);
    if (is_byte(op) == 0)
	size /= sizeof(Objptr);
    return size;
}

/*
 * Swap meanings of objects.
 */
int
swapPointers(Objptr first, Objptr second)
{
    Objhdr              old_ptr;
    Otentry             fp, sp;
    int                 ptrs;
    int                 indexable;
    int                 byte;

    if (!is_object(first) || !is_object(second))
	return FALSE;
    fp = &otable[first / 2];
    sp = &otable[second / 2];
    old_ptr = objmem[first / 2];
    indexable = fp->indexable;
    byte = fp->byte;
    ptrs = fp->ptrs;
    objmem[first / 2] = objmem[second / 2];
    fp->indexable = sp->indexable;
    fp->byte = sp->byte;
    fp->ptrs = sp->ptrs;
    objmem[second / 2] = old_ptr;
    sp->indexable = indexable;
    sp->byte = byte;
    sp->ptrs = ptrs;
    return TRUE;
}

/*
 * Return the first instance of a object of class class.
 */
Objptr
initialInstance(Objptr class)
{
    int                 i;
    Otentry             ptr;

    for (i = 0, ptr = &otable[i]; i < otsize; i++, ptr++) {
	if (ptr->free == 0 && objmem[i]->oclass == class)
	    return (i * 2);
    }
    return NilPtr;
}

/*
 * Return the next instance of a object with same class as current object.
 */
Objptr
nextInstance(Objptr op)
{
    int                 i = op / 2;
    Objptr              class;

    if (op == NilPtr || !is_object(op))
	return NilPtr;
    class = objmem[i]->oclass;
    for (i++; i < otsize; i++) {
	if (otable[i].free == 0 && objmem[i]->oclass == class)
	    return (i * 2);
    }
    return NilPtr;
}

/*
 * Return next used object.
 */
int                *
next_object(Objptr * op, int *flags, Objptr * class, int *size)
{
    int                 i;
    Otentry             ptr;

    if (!is_object(*op)) 
	return NULL;
    i = (*op / 2) + 1;
    ptr = &otable[i];
    for (; i < otsize; i++, ptr++) {
	if (!ptr->free) {
	    *flags = (ptr->ptrs) ? CLASS_PTRS : 0;
	    *flags |= (ptr->indexable) ? CLASS_INDEX : 0;
	    *flags |= (ptr->byte) ? CLASS_BYTE : 0;
	    *class = objmem[i]->oclass;
	    *size = objmem[i]->size;
	    *op = i * 2;
	    return (int *) (objmem[i] + 1);
	}
    }
    return NULL;
}

/*
 * Object memory information.
 */

/*
 * Return number of free Object pointers.
 */
Objptr
freeOops()
{
    int                 i;
    int                 count = 0;
    Otentry             ptr;

    for (i = 0, ptr = &otable[i]; i < otsize; i++, ptr++) {
	if (ptr->free)
	    count++;
    }
    return as_integer_object(count);
}

/*
 * Return number of object pointers in use.
 */
Objptr
usedOops()
{
    int                 i;
    int                 count = 0;
    Otentry             ptr;

    for (i = 0, ptr = &otable[i]; i < otsize; i++, ptr++) {
	if (!ptr->free)
	    count++;
    }
    return as_integer_object(count);
}

/*
 * Return amount of memory used by object space.
 */
Objptr
coreUsed()
{
    Region              reg;
    int                 space = 0;

    for (reg = regions; reg != NULL; reg = reg->next)
	space += reg->totalspace;

    return as_integer_object(space);
}

/*
 * Return amount of memory unused in object space.
 */
Objptr
freeSpace()
{
    Region              reg;
    int                 space = 0;

    for (reg = regions; reg != NULL; reg = reg->next)
	space += reg->freespace;

    return as_integer_object(space);
}


/*
 * Private Object memory functions.
 */

/*
 * Return pointer to a new object, this does not create space.
 */
static INLINE       Objptr
new_object_pointer(int ptrs, int indexable, int byte, Objhdr addr)
{
    Objptr          new_ptr = (Objptr)freeobj;

    if (new_ptr != NilPtr) {
	freeobj = olist[new_ptr];
	objmem[new_ptr] = addr;
	otable[new_ptr].refcnt = 0;
	otable[new_ptr].free = 0;
	otable[new_ptr].ptrs = ptrs;
	otable[new_ptr].indexable = indexable;
	otable[new_ptr].byte = byte;
    }
    return new_ptr * 2;
}

/*
 * Put object pointer back on free list.
 */
static INLINE void
free_object_pointer(Objptr op)
{
   /* Make sure it is a object an not NilObject */
    if (is_object(op) && op != 0 && notFree(op)) {
    	Otentry      optr;

	/* If we are about to free a compiled method, flush it out of cache */
	if (class_of(op) == CompiledMethodClass)
	    flushMethod(op);

	op /= 2;
    	optr = &otable[op];			/* Convert to index */
	add_to_free(objmem[op]);		/* Free space used by object */
	olist[op] = freeobj;		        /* Append to free list */
	freeobj = op;
	optr->refcnt = 0;
	optr->free = 1;
	optr->ptrs = 0;
	optr->indexable = 0;
	optr->byte = 0;
    }
}

/*
 * Free space used by object.
 */
static INLINE void
add_to_free(Objhdr optr)
{
    int                 lp;
    Region              r;

    optr->size = wordsize(optr->size); /* Make sure size is rounded correctly */
    lp = freebin(optr->size);
    optr->size += sizeof(objhdr);
    for (r = regions; r != NULL; r = r->next) {
	if ((unsigned char *)optr >= r->base &&
                  (unsigned char *)optr < r->limit) {
            optr->oclass = r->freeptrs[lp];
            r->freeptrs[lp] = ((unsigned char *)optr) - ((unsigned char *)r);
            r->freespace += optr->size;
	    return;
	}
    }
    error("Chunk lost");
}

/*
 * Allocate a new chunk of memory.
 */
static              Objhdr
allocate_chunk(int size)
{
    Objhdr              new_ptr;

    if ((new_ptr = attempt_to_allocate(size)) == NULL) {
	reclaimSpace();
	if ((new_ptr = attempt_to_allocate(size)) == NULL) {
	    new_region(size);
	    new_ptr = attempt_to_allocate(size);
	}
    }
    return new_ptr;
}

/*
 * Try to allocate object in current region.
 */
static              Objhdr
attempt_to_allocate_incurrent(int size)
{
    int                 lp, left;
    Objhdr              obj;
    Objhdr              prior;
    unsigned char      *reg;
    unsigned int        head;

    if (curregion == NULL)
	curregion = regions;

    if (curregion == NULL)
	return NULL;

   reg = (unsigned char *)curregion;
   /* See if below size of large object */
    if ((lp = freebin(size)) < ALLOCSIZE) {
       /* Try small object list first */
	if ((head = curregion->freeptrs[lp]) != 0) {
	   /* Exact match found, remove it from list */
            obj = (Objhdr)&reg[head];
	    curregion->freeptrs[lp] = obj->oclass;
	    curregion->freespace -= obj->size;

	    /* Fix current new object up */
	    obj->oclass = 0;
            obj->size -= sizeof(objhdr);
	    return obj;
	}
    }
   /* Did not find it, pull off large object list */
    prior = NULL;
    head = curregion->freeptrs[ALLOCSIZE];
    while (head != 0) {
        obj = (Objhdr)&reg[head];
	left = obj->size - (size + (int)sizeof(objhdr));
       /* Check for exact match */
	if (left == 0) {
	    /* Remove from free list */
	    if (prior == NULL)
		curregion->freeptrs[ALLOCSIZE] = obj->oclass;
	    else
		prior->oclass = obj->oclass;
	   /* Update amount of space avail for use */
	    curregion->freespace -= obj->size;

	    /* Fix current new object up */
	    obj->oclass = 0;
            obj->size -= sizeof(objhdr);
	    return obj;
	}
       /* Can we split this into two? */
       /* Must be able to hold at least object with no instance variables */
	if (left >= (int)sizeof(objhdr)) {
            unsigned int   next;
	    Objhdr         other;

	    /* Remove from free list */
	    if (prior == NULL)
		curregion->freeptrs[ALLOCSIZE] = obj->oclass;
	    else
		prior->oclass = obj->oclass;

	    /* Append left over chunk to correct list */
	    lp = freebin(left - sizeof(objhdr));

	    /* Build new free element at end of current chunk */
            next = head + size + sizeof(objhdr);
	    other = (Objhdr) (&reg[next]);
	    other->size = left;

            /* Link into current list */
	    other->oclass = curregion->freeptrs[lp];
            curregion->freeptrs[lp] = next;
	
	    /* Update amount of space availaible */
	    curregion->freespace -= size + sizeof(objhdr);

	    /* Fix current new object up */
	    obj->oclass = 0;
            obj->size = size;
	    return obj;
	}
        prior = obj;
        head = obj->oclass;
    }
    return NULL;
}

/*
 * Create a new region for a object of a given size.
 * Object header size has already been added to size.
 */
static int
new_region(int size)
{
    Region              new_reg;
    int                 i;
    Objhdr              ptr;

   /* Round to growsize bytes */
    if ((size = (size / (growsize * 1024))) == 0)
	size = 1;
    size *= growsize * 1024;
    size += sizeof(objhdr);  /* At least one Object */

   /* Allocate space */
    if ((new_reg = (Region) malloc(size + sizeof(region))) == NULL)
	return FALSE;

   /* Fill in header */
    new_reg->freespace = size;
    new_reg->totalspace = new_reg->freespace;
    new_reg->base = (sizeof(region) + ((unsigned char *) new_reg));
    new_reg->limit = new_reg->base + size;
    for (i = 0; i < ALLOCSIZE; i++)
	new_reg->freeptrs[i] = 0;

   /* Create one big object */
    ptr = (Objhdr) new_reg->base;
    ptr->size = new_reg->freespace;
    ptr->oclass = 0;

    new_reg->freeptrs[ALLOCSIZE] = sizeof(region);

   /* Add to head of region list */
    new_reg->next = regions;
    regions = new_reg;
    curregion = new_reg;
 
#ifdef DUMP_OBJMEM
    {
        char		buffer[100];
        sprintf(buffer, "New Region %d bytes", size);
        dump_objstring(buffer);
    };
#endif
    return TRUE;
}

/*
 * Attempt to allocate a object.
 */
static              Objhdr
attempt_to_allocate(int size)
{
    Objhdr              new_ptr;
    int                 compactflag;

   /* Try straight allocation */
    if ((new_ptr = attempt_to_allocate_incurrent(size)) != NULL)
	return new_ptr;

   /* Scan regions looking for space */
    compactflag = FALSE;
    for (curregion = regions; curregion != NULL; curregion = curregion->next) {
       /* Try to allocate from region */
	if ((new_ptr = attempt_to_allocate_incurrent(size)) != NULL)
	    return new_ptr;
       /* Would we get enough if we compacted? 
          Don't bother compacting a region that has less than 10% free */
	if (curregion->freespace > (size + sizeof(objhdr)) &&
	    (curregion->totalspace / 10) < curregion->freespace)
	    compactflag = TRUE;
    }

   /* If compation will not help, return now */
    if (!compactflag)
	return NULL;

   /* Scan regions again */
    for (curregion = regions; curregion != NULL; curregion = curregion->next) {
       /* Would we get enough if we compacted? 
          Don't bother compacting a region that has less than 10% free */
	if (curregion->freespace > (size + sizeof(objhdr)) &&
	    (curregion->totalspace / 10) < curregion->freespace)
	    compact_region();
       /* Try again */
	if ((new_ptr = attempt_to_allocate_incurrent(size)) != NULL)
	    return new_ptr;
    }

    return NULL;
}

/*
 * Compat free space in a region into on big hunk.
 */
static void
compact_region()
{
    unsigned char      *lowWater, *r;
    unsigned int        wsize;
    unsigned int        next;
    unsigned int        ptr;
    unsigned int       *src, *dst;
    int                 op, lp;
    Objptr              oclass;

   /* No point in compating if there is no free space */
    if (curregion->freespace == 0)
	return;

   /* 
    * Find lowest free area, also clear out freelist.
    * Flag all free areas with a class of -1.
    */
    r = (unsigned char *)curregion;
    lowWater = curregion->limit;
    for (lp = 0; lp <= ALLOCSIZE; lp++) {
	ptr = curregion->freeptrs[lp];
	while (ptr != 0) {
	    if (&r[ptr] < lowWater)
		lowWater = &r[ptr];
	    next = ((Objhdr)&r[ptr])->oclass;
	    ((Objhdr)&r[ptr])->oclass = -1;
	    ptr = next;
	}
	curregion->freeptrs[lp] = 0;
    }

    src = (unsigned int *)lowWater;
    while (src < (unsigned int *)curregion->limit) {
	if (((Objhdr) src)->oclass == -1) {
	     src += (((Objhdr) src)->size) / sizeof(unsigned int);
        } else {
	     src += (wordsize(((Objhdr) src)->size) + sizeof(objhdr)) / sizeof(unsigned int);
        }
    }

   /* Reverse all pointers in range to store size in location */
    for (op = 0; op < otsize; op++) {
	if (otable[op].free == 0) {
	    unsigned char *o = (unsigned char *)objmem[op];
	    if (o >= lowWater && o < curregion->limit) {
	       /*
	        * Put object number into class field, and squirel away
	        * class in free list.
	        */
		olist[op] = objmem[op]->oclass;
		objmem[op]->oclass = op;
	    }
	}
    }

   /* Move all objects to head of region */
    src = dst = (unsigned int *)lowWater;
    while (src < (unsigned int *)curregion->limit) {
       /* Check if free or allocated object. */
	if (((Objhdr) src)->oclass == -1) {
	    /* Free area, skip it */
	    src += (((Objhdr) src)->size) / sizeof(unsigned int);
	} else {
	   /* Rebuild object */
	    op = ((Objhdr) src)->oclass;
	    oclass = olist[op];
            wsize = wordsize(((Objhdr) src)->size);

	    if (((unsigned char *)src + wsize) > curregion->limit)
		error("Compact out of range");
	    objmem[op] = (Objhdr) dst;	/* Where it will land */

            /* Rebuild header */
            *dst++ = *src++;
            *dst++ = oclass;
            src++;

	   /* Round size */
	    wsize = wsize / sizeof(unsigned int);

	   /* Copy rest of object */
	    for (; wsize > 0; wsize--)
		*dst++ = *src++;
	}
    }

   /* Adjust free list */
    ((Objhdr) dst)->size = curregion->limit - (unsigned char *)dst;
    ((Objhdr) dst)->oclass = 0;
    lp = freebin(((Objhdr) dst)->size - sizeof(objhdr));
    curregion->freeptrs[lp] = ((unsigned char *)dst) - r;
}

/*
 * Return the last pointer of a object.
 */
static int
last_pointer_of(Objptr op)
{
    int                 size;

   /* If object has pointers return all of it */
    if (!is_word(op))
	size = size_of(op) / sizeof(Objptr);

   /* Check if compiled method */
    else {
	size = fixed_size(op) / sizeof(Objptr);
	if (class_of(op) == CompiledMethodClass)
	    size += LiteralsOf(get_pointer(op, METH_HEADER));
    }
    return size;
}

/*
 * Helper for reclaim space.
 * Mark all object accessable from a given object.
 */
static void
mark_all_other_objects(Objptr op)
{
    Objptr              prior, next, current;
    int                 offset;

    prior = (Objptr) -1;		/* Flag to indicate done */
    current = op;
    offset = last_pointer_of(op) + 2;
    while (TRUE) {
       /* Go backward until we hit size field. */
	if (--offset >= 1) {
	    next = get_pointer(current, offset - 2);
	   /* If it is an object and we have not seen it */
	   /* Look into it */
	    if (is_object(next) && get_object_refcnt(next) == 0) {
	       /* Process object */
		set_object_refcnt(next, 1);

	       /* Push current onto stack */
		set_pointer(current, offset - 2, prior);
		set_object_refcnt(current, offset);

	       /* Reload work pointers */
		prior = current;
		current = next;
		offset = last_pointer_of(current) + 2;
	    }
	} else {
	   /* Done with object, do action */
	    set_object_refcnt(current, 1);
	   /* Check if at root of tree */
	    if (prior == (Objptr) -1)
		return;
	   /* Otherwise pop object stack */
	    next = current;
	    current = prior;
	   /* Reload work pointers */
	    offset = get_object_refcnt(current);

	   /* Reverse pointers */
	    prior = get_pointer(current, offset - 2);
	    set_pointer(current, offset - 2, next);
	}
    }
}

/*
 * Decrease refrence count, but don't free object.
 */
static INLINE int
decr_ref_count(Objptr op)
{
    int                 cnt;

    if ((cnt = get_object_refcnt(op)) != MAXREFCNT)
	set_object_refcnt(op, cnt - 1);
    return cnt == 1;
}

/*
 * Helper for freeing objects.
 * Free all object accessable from this object.
 */
void
free_all_other_objects(Objptr op)
{
    Objptr              prior, next, current;
    int                 offset;

    prior = (Objptr) -1;
    current = op;
    offset = last_pointer_of(op) + 2;
    while (TRUE) {
       /* Go backward until we hit size field. */
	if (--offset >= 1) {
	    next = get_pointer(current, offset - 2);
	   /* Make sure it is not already freed */
	    if (is_object(next) && !notFree(next)) {
		void dump_stack(Objptr);

		dump_stack(NilPtr);
		error("Attempt to reclaim free object");
	    }
		
	   /* If it is an object and we have not seen it */
	   /* Look into it */
	    if (is_object(next) && decr_ref_count(next)) {
	       /* Push current onto stack */
		set_pointer(current, offset - 2, prior);
		set_object_refcnt(current, offset);

	       /* Reload work pointers */
		prior = current;
		current = next;
		offset = last_pointer_of(current) + 2;
	    }
	} else {
	   /* Done with object, do action */
	    free_object_pointer(current);
	   /* Check if at root of tree */
	    if (prior == (Objptr) -1)
		return;
	   /* Otherwise pop object stack */
	   /* next = current; */
	    current = prior;
	   /* Reload work pointers */
	    offset = get_object_refcnt(current);

	   /* Reverse pointers */
	    prior = get_pointer(current, offset - 2);
	    set_pointer(current, offset - 2, NilPtr);
	}
    }
}

/*
 * Attempt to reclaim inaccessable objects.
 */
void
reclaimSpace()
{
    int                 i, j;
    int                 cnt;
    Objptr		op;
#ifdef DUMP_OBJMEM
    int			before = 0, after = 0;
    int			total = 0;
#endif
    Region              best_reg;

    if (noreclaim)
	return;

#ifdef DUMP_OBJMEM
   /* Sum up free space. */
    for (curregion = regions; curregion != NULL; curregion = curregion->next) {
	total += curregion->totalspace;
	before += curregion->freespace;
    }
#endif

   /* zero all object reference counts */
    for (i = 1; i < otsize; i++)
	set_object_refcnt(i * 2, 0);

   /* go through list of known objects */
    for (i = 0; i < (sizeof(rootObjects) / sizeof(Objptr)); i++) {
	op = rootObjects[i];
	if (op != NilPtr && notFree(op)) {
	    set_object_refcnt(op, MAXREFCNT);
	    mark_all_other_objects(op);
	}
    }

   /* Check if any of freed objects are a file */
    check_files();

   /* Since we might have freed some things, init the method cache */
    flushCache(NilPtr);

   /* Free all unreferenced objects now */
    for (i = 1; i < otsize; i++) {
	if ((cnt = get_object_refcnt(i*2)) == 0) 
	    free_object_pointer(i*2);
	else if (notFree(i*2)) {
	    set_object_refcnt(i*2, cnt - 1);
	    j = last_pointer_of(i*2) + 2;
	    while( --j >= 1)
		object_incr_ref(get_pointer(i*2, j - 2));
	}
    }

   /* go through list of known objects */
    for (i = 0; i < (sizeof(rootObjects) / sizeof(Objptr)); i++) {
	if (rootObjects[i] != NilPtr)
	    object_incr_ref(rootObjects[i]);
    }

   /* Make sure null never gets freed */
    set_object_refcnt(NilPtr, MAXREFCNT);

   /* Sum up free space. and compact the regions for most free space */
    best_reg = regions;
    for (curregion = regions; curregion != NULL; curregion = curregion->next) {
#ifdef DUMP_OBJMEM
	after += curregion->freespace;
#endif
	if ((curregion->totalspace / 5) < curregion->freespace)
		compact_region();
	if (best_reg->freespace < curregion->freespace)
		best_reg = curregion;
    }

   /* Set current region, use region with most free space */
    curregion = best_reg;

#ifdef DUMP_OBJMEM
    {
        char		buffer[100];
        sprintf(buffer, "Reclaim ran %d total, before %d after %d freed %d",
		total, before, after, after - before);
        dump_objstring(buffer); 
    };
#endif
}
