
/*
 * Smalltalk interpreter: Object memory system.
 *
 * $Log: object.c,v $
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

#ifndef lint
static char        *rcsid =
	"$Id: object.c,v 1.3 2000/02/01 18:09:57 rich Exp rich $";

#endif

/* System stuff */
#ifdef unix
#include <stdio.h>
#include <unistd.h>
#include <malloc.h>
#endif

#ifdef _WIN32
#include <stddef.h>
#include <windows.h>

#define malloc(x)	GlobalAlloc(GMEM_FIXED, x)
#define free(x)		GlobalFree(x)
#endif

#include "object.h"
#include "smallobjs.h"
#include "dump.h"
#include "fileio.h"

int                 growsize = 64;		/* Region grow rate */
Region              regions = NULL;		/* Memory regions */
Region              curregion = NULL;		/* Pointer to current region */
Otentry             otable = NULL;		/* Pointer to object info */
Objhdr		   *objmem = NULL;		/* Pointer to objects */
Objptr              freeobj;			/* Next free object pointer */
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

/* Creation. */

/*
 * Create a new object of class class and size additional words.
 */
Objptr
create_new_object(Objptr class, int size)
{
    Objhdr              new_ptr;
    Objptr              new_obj;
    Objptr              obj_flag;
    int                *addr;
    int                 allocsize;
    int                 i;
    int                 ptrs;
    int                 indexable;
    int                 byte;

   /* Get type of object */
    obj_flag = get_pointer(class, CLASS_FLAGS);
    ptrs = (obj_flag & CLASS_PTRS) != 0;
    byte = (obj_flag & CLASS_BYTE) != 0;
    indexable = (obj_flag & CLASS_INDEX) != 0;
   /* Need to inline this since otherwise we get size of Class */
    i = (obj_flag / 16) * sizeof(Objptr);

   /* Don't create a non indexable object larger than it's fixed size */
    if ((!indexable) && size > 0) 
	return NilPtr;

   /* Compute size of object */
    if (!byte)
	size *= sizeof(Objptr);

   /* Round allocation size to objptr boundry */
    allocsize = wordsize(size);

   /* Add on fixed class size */
    allocsize += i;

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
    new_ptr->u.class = class;
    new_ptr->size = size + i;
    object_incr_ref(class);
    addr = (int *) (new_ptr + 1);
    for (allocsize /= sizeof(int); allocsize > 0; allocsize--)
	*addr++ = 0;
    return new_obj;
}

/*
 * Install a new object.
 */
int                *
create_object(Objptr op, int flags, Objptr class, int size)
{
    Objhdr              new_ptr;
    int                *addr;
    int                 allocsize;

   /* Round to integer size */
    allocsize = wordsize(size);

   /* Add on fixed class size */

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
    new_ptr->u.class = class;
    new_ptr->size = size;
    addr = (int *) (new_ptr + 1);
    object_incr_ref(class);		/* Reference count Class */
    for (allocsize /= sizeof(int); allocsize > 0; allocsize--)
	*addr++ = 0;

    return (int *) (new_ptr + 1);
}

/*
 * After we reload an image, we need to rebuild free list and compute
 * new reference counts.
 */
void
rebuild_free()
{
    int                 i;

    freeobj = NilPtr;
   /* Add all free objects into free list */
    for (i = otsize - 1; i > 0; i--) {
	if (otable[i].free) {
	    objmem[i] = (Objhdr) freeobj;
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

    while (regions != NULL) {
	Region              reg = regions->next;

	free(regions);
	regions = reg;
    }

    otsize = number * 1024;
    if ((otable = (Otentry) malloc(sizeof(otentry) * otsize)) == NULL)
	return FALSE;

    if ((objmem = (Objhdr *) malloc(sizeof(Objhdr) * otsize)) == NULL) {
	otable = NULL;
	free(otable);
	return FALSE;
    }

    freeobj = NilPtr;
   /* Clear and free all objects. */
    for (i = otsize - 1, ptr = &otable[i], optr = &objmem[i];
	 i > ((int) NilPtr);
	 i--, ptr--, optr--) {
	*optr = (Objhdr) freeobj;
	ptr->refcnt = 0;
	ptr->free = 1;
	ptr->ptrs = 0;
	ptr->indexable = 0;
	ptr->byte = 0;
	freeobj = i;
    }

   /* Intialize the null object. */
    objmem[(int) NilPtr] = &nilhdr;
    otable[(int) NilPtr].refcnt = MAXREFCNT;
    otable[(int) NilPtr].free = 0;
    otable[(int) NilPtr].indexable = 0;
    otable[(int) NilPtr].byte = 0;
    otable[(int) NilPtr].ptrs = 0;

    nilhdr.u.class = UndefinedClass;	/* For now */
    nilhdr.size = 0;

    for (i = 0; i < (sizeof(rootObjects) / sizeof(Objptr)); i++)
	rootObjects[i] = NilPtr;

    new_region(growsize);
    return TRUE;
}

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
    return (value << 1) + 1;
}

/* Accessing Functions. */

INLINE              Objhdr
get_object_pointer(Objptr op)
{
    return objmem[op / 2];
}

INLINE char        *
get_object_base(Objptr op)
{
    return (char *) (get_object_pointer(op) + 1);
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

INLINE void
set_object_refcnt(Objptr op, int cnt)
{
    otable[op / 2].refcnt = cnt;
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
    return ((char *) get_object_base(op))[offset];
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
    return is_object(op)? get_object_pointer(op)->u.class :
				SmallIntegerClass;
}

/* Size of an object in bytes. */
INLINE int
size_of(Objptr op)
{
    return get_object_pointer(op)->size;
}

/*
 * Return fixed size of object in bytes.
 */

INLINE int
fixed_size(Objptr op)
{
    Objptr              class = class_of(op);
    int                 size;

    size = (class == NilPtr) ? 0 : (get_integer(class, CLASS_FLAGS)/ 16);
    return sizeof(Objptr) * size;
}


#if 0
/* Reference Counting. */
INLINE void
object_incr_ref(Objptr op)
{
    if (is_object(op)) {
	int                 ncnt = get_object_refcnt(op);

	if (ncnt != MAXREFCNT)
	    set_object_refcnt(op, ncnt + 1);
    }
}

INLINE void
object_decr_ref(Objptr op)
{
    if (is_object(op)) {
	int                 ncnt = get_object_refcnt(op);

       /* Don't change objects at max count */
	if (ncnt != MAXREFCNT) {
	    set_object_refcnt(op, ncnt - 1);
	   /* If count is zero, remove object */
	    if (ncnt == 1) {
		free_all_other_objects(op);
	    }
	}
    }
}
#endif
#endif

/* Assignment */
void
Set_object(Objptr op, int offset, Objptr newvalue)
{
    if (offset > (size_of(op)/sizeof(Objptr)) || offset < 0) {
	void dump_stack(Objptr);

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
    if (offset > (size_of(op)/sizeof(Objptr)) || offset < 0) {
	void dump_stack(Objptr);

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
	get_object_pointer(op)->u.class = newClass;
    }
}

/* Can integer be held in object pointer */
INLINE int
canbe_integer(int value)
{
    int                 temp = value << 1;	/* So as not to be optimized out. */

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
	if (ptr->free == 0 && objmem[i]->u.class == class)
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
    class = objmem[i]->u.class;
    for (i++; i < otsize; i++) {
	if (otable[i].free == 0 && objmem[i]->u.class == class)
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
    Objhdr              optr;

    if (!is_object(*op)) 
	return NULL;
    i = (*op / 2) + 1;
    ptr = &otable[i];
    for (; i < otsize; i++, ptr++) {
	if (!ptr->free) {
	    *flags = (ptr->ptrs) ? CLASS_PTRS : 0;
	    *flags |= (ptr->indexable) ? CLASS_INDEX : 0;
	    *flags |= (ptr->byte) ? CLASS_BYTE : 0;
	    optr = objmem[i];
	    *class = objmem[i]->u.class;
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
    Objptr              new_ptr = freeobj;

    if (new_ptr != NilPtr) {
	freeobj = (Objptr) objmem[new_ptr];
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

	op /= 2;
    	optr = &otable[op];			/* Convert to index */
	add_to_free(objmem[op]);		/* Free space used by object */
	objmem[op] = (Objhdr) freeobj;		/* Append to free list */
	optr->refcnt = 0;
	optr->free = 1;
	optr->ptrs = 0;
	optr->indexable = 0;
	optr->byte = 0;
	freeobj = op;
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
    int                 size;

    size = wordsize(optr->size);
    optr->size = size;		/* Make sure size is rounded correctly */
    lp = freebin(size);
    for (r = regions; r != NULL; r = r->next)
	if (optr >= r->base && optr <= r->limit) {
	    optr->u.next = r->freeptrs[lp];
	    r->freeptrs[lp] = optr;
            r->freespace += size + sizeof(objhdr);
	    return;
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
    Objhdr              prior;
    Objhdr              cur;

    if (curregion == NULL)
	curregion = regions;

    if (curregion == NULL)
	return NULL;

   /* See if below size of large object */
    if ((lp = freebin(size)) < ALLOCSIZE) {
       /* Try small object list first */
	if ((cur = curregion->freeptrs[lp]) != NULL) {
	   /* Exact match found, remove it from list */
	    curregion->freeptrs[lp] = cur->u.next;
	    curregion->freespace -= size + sizeof(objhdr);
	    cur->u.next = NULL;
	    return cur;
	}
    }
   /* Did not find it, pull off large object list */
    prior = NULL;
    for (cur = curregion->freeptrs[ALLOCSIZE]; cur != NULL; cur = cur->u.next) {
	left = cur->size - size;
       /* Check for exact match */
	if (left == 0) {
	    /* Remove from free list */
	    if (prior == NULL)
		curregion->freeptrs[ALLOCSIZE] = cur->u.next;
	    else
		prior->u.next = cur->u.next;
	   /* Update amount of space avail for use */
	    curregion->freespace -= size + sizeof(objhdr);
	    cur->u.next = NULL;
	    return cur;
	}
       /* Can we split this object */
	if (left >= (int)(sizeof(objhdr))) {
	    Objhdr              other;

	    /* Remove from free list */
	    if (prior == NULL)
		curregion->freeptrs[ALLOCSIZE] = cur->u.next;
	    else
		prior->u.next = cur->u.next;

	    /* Build new free element at end of current chunk */
	    other = (Objhdr) (((char *) (cur + 1)) + size);
	    other->size = left - sizeof(objhdr);

	    /* Append to correct list */
	    lp = freebin(other->size);
	    other->u.next = curregion->freeptrs[lp];
	    curregion->freeptrs[lp] = other;
	
	    /* Update amount of space availaible */
	    curregion->freespace -= size + sizeof(objhdr);

	    /* Fix current junk up */
	    cur->size = size;
	    cur->u.next = NULL;
	    return cur;
	}
	prior = cur;
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
    size += sizeof(region) + sizeof(objhdr);

   /* Allocate space */
    if ((new_reg = (Region) malloc(size)) == NULL)
	return FALSE;

   /* Fill in header */
    new_reg->freespace = size - sizeof(region);
    new_reg->totalspace = new_reg->freespace;
    new_reg->base = (Objhdr) (sizeof(region) + ((char *) new_reg));
    new_reg->limit = (Objhdr) (((char *) new_reg->base) + new_reg->freespace);
    for (i = 0; i < ALLOCSIZE; i++)
	new_reg->freeptrs[i] = NULL;

   /* Create one big object */
    ptr = (Objhdr) new_reg->base;
    ptr->size = new_reg->freespace - sizeof(objhdr);
    ptr->u.next = NULL;

    new_reg->freeptrs[ALLOCSIZE] = ptr;

   /* Add to head of region list */
    new_reg->next = regions;
    regions = new_reg;
    curregion = new_reg;
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
       /* Would we get enough if we compacted? */
	if (curregion->freespace > (size + sizeof(objhdr)))
	    compactflag = TRUE;
    }

   /* If compation will not help, return now */
    if (!compactflag)
	return NULL;

   /* Scan regions again */
    for (curregion = regions; curregion != NULL; curregion = curregion->next) {
       /* Would we get enough if we compacted? */
	if (curregion->freespace > (size + sizeof(objhdr)))
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
    Objhdr              lowWater, highWater;
    int                 i, size;
    Objhdr              next;
    Objhdr              ptr;
    int                *src, *dst;

   /* No point in compating if there is no free space */
    if (curregion->freespace == 0)
	return;

    dump_objstring("Compacting");

   /* 
    * Find lowest free area, also clear out freelist.
    * Flag all free areas with a class of -1.
    */
    lowWater = curregion->limit;
    for (i = 0; i <= ALLOCSIZE; i++) {
	ptr = curregion->freeptrs[i];
	while (ptr != NULL) {
	    if (ptr < lowWater)
		lowWater = ptr;
	    next = ptr->u.next;
	    ptr->u.class = -1;
	    ptr = next;
	}
	curregion->freeptrs[i] = NULL;
    }

   /* Reverse all pointers in range to store size in location */
    highWater = curregion->limit;
    for (i = 0; i < otsize; i++) {
	if (otable[i].free == 0) {
	    ptr = objmem[i];
	    if (ptr > lowWater && ptr < highWater) {
	       /*
	        * Put object number into size field, and squirel away
	        * size in objects address pointer.
	        */
		objmem[i] = (Objhdr) ptr->size;
		ptr->size = i;
	    }
	}
    }

   /* Move all objects to head of region */
    src = dst = (int *) lowWater;
    while (src < (int *) highWater) {
       /* Check if free or allocated object. */
	if (((Objhdr) src)->u.class == -1) {
	    /* Free area, skip it */
	    src += (sizeof(objhdr) + ((Objhdr) src)->size) / sizeof(int);
	} else {
	   /* Rebuild object */
	    i = (int) (((Objhdr) src)->size);
	    size = (int) objmem[i];


	    if ((src + (wordsize(size)/sizeof(int))) > (int *)highWater)
		error("Compact out of range");
	    objmem[i] = (Objhdr) dst;	/* Where it will land */

	   /* Build new header */
	    ((Objhdr) dst)->size = size;
	    ((Objhdr) dst)->u.class = ((Objhdr) src)->u.class;
	    src++;		/* Skip  over object header */
	    src++;
	    dst++;
	    dst++;
	   /* Round size */
	    size = wordsize(size) / sizeof(int);

	   /* Copy rest of object */
	    for (; size > 0; size--)
		*dst++ = *src++;
	}
    }

   /* Adjust free list */
    ((Objhdr) dst)->size = (int)((char *)curregion->limit - (char *)dst)
			 - sizeof(objhdr);
    ((Objhdr) dst)->u.next = 0;
    i = freebin(((Objhdr) dst)->size);
    curregion->freeptrs[i] = (Objhdr) dst;
    dump_objstring("Compacting done"); 
}

/*
 * Return the last pointer of a object.
 */
static INLINE int
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
 * Attempt to reclaim inaccessable objects.
 */
void
reclaimSpace()
{
    int                 i, j;
    int                 cnt;
    Objptr		op;

    if (noreclaim)
	return;

    dump_objstring("Reclaim"); 
   /* zero all object reference counts */
    for (i = 1; i < otsize; i++)
	set_object_refcnt(i * 2, 0);

   /* go through list of known objects */
    for (i = 0; i < (sizeof(rootObjects) / sizeof(Objptr)); i++) {
	op = rootObjects[i];
	if (op != NilPtr && notFree(op) && get_object_refcnt(op) == 0) {
	    set_object_refcnt(op, 1);
	    mark_all_other_objects(op);
	}
    }

   /* Free all unreferenced objects now */
    for (i = 1; i < otsize; i++) {
	if ((cnt = get_object_refcnt(i*2)) == 0)
	    free_object_pointer(i*2);
	else {
	    set_object_refcnt(i*2, cnt - 1);
	    j = last_pointer_of(i*2) + 2;
	    while( --j >= 1)
		object_incr_ref(get_pointer(i*2, j - 2));
	}
    }
   /* go through list of known objects */
    for (i = 0; i < (sizeof(rootObjects) / sizeof(Objptr)); i++)
	if (rootObjects[i] != NilPtr)
	    object_incr_ref(rootObjects[i]);

   /* Make sure null never gets freed */
    set_object_refcnt(NilPtr, MAXREFCNT);

   /* Set current region, any region as good as any other now */
    curregion = regions;
}
