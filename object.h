
/*
 * Smalltalk interpreter: Object memory system.
 *
 * $Id: object.h,v 1.7 2001/08/29 20:16:35 rich Exp rich $
 *
 * $Log: object.h,v $
 * Revision 1.7  2001/08/29 20:16:35  rich
 * Moved region definition to object.c
 *
 * Revision 1.6  2001/08/18 16:17:01  rich
 * Added new rootObjects for graphics system.
 *
 * Revision 1.5  2001/07/31 14:09:48  rich
 * Converted object_incr_ref and object_decr_ref to macros.
 *
 * Revision 1.4  2000/08/19 17:40:30  rich
 * Make sure bytes are returned unsigned.
 *
 * Revision 1.3  2000/02/01 18:09:58  rich
 * Increased size of root objects.
 *
 * Revision 1.2  2000/01/03 16:23:22  rich
 * Moved object pointer out to a new structure to reduce access cost.
 *
 * Revision 1.1  1999/09/02 15:57:59  rich
 * Initial revision
 *
 *
 */

#define	MAXREFCNT 0x0fffffff	/* Max number of references to a object */
#define ALLOCSIZE 16		/* Number of allocation bins in a region. */

#define FALSE	0
#define TRUE 	1
#ifndef INLINE
#define INLINE
#endif

/* Root object indexies */
#define	CURCONT		0	/* Current context */
#define NEWPROC		1	/* New process */
#define SMALLTLK	2	/* Smalltalk dictionary */
#define SYMTAB		3	/* Symbol table */
#define CHARTAB		4	/* Character table */
#define OBJECT		5
#define SPECSEL		6	/* Specail selectors table */
#define TRUEOBJ		7	/* True */
#define FALSEOBJ	8	/* False */
#define SELECT0		9	/* Common errors message methods */
#define SELECT1		10
#define SELECT2		11
#define SELECT3		12
#define SELECT4		13
#define TEMP0		14	/* Temporaries used by compiler */
#define TEMP1		15
#define TEMP2		16
#define TEMP3		17
#define METHFOR0	18	/* Temporaries used during base loading */
#define METHFOR1	19
#define ERRORSEL	20
#define TICKSEMA	21	/* Semaphore to send timer ticks too */
#define DISPOBJ		22	/* Display object */
#define INPUTSEMA	23	/* Semaphore to signal when input is ready */
#define CURSOBJ		24	/* Current cursor object */
#define CONSOLELIST	25	/* Suspended console linked list */
#define ROOTSIZE	26

typedef unsigned int Objptr;

/*
 * Information placed at head of object to indicate clase and size.
 */
typedef struct _objhdr {
    unsigned int            size;	/* Size of object */
    union {				/* Second word */
	Objptr              class;	/* Class of in use object */
	struct _objhdr     *next;	/* Next free object in chain */
    } u;
} objhdr           , *Objhdr;

typedef struct _otentry {
    unsigned int        refcnt:28;		/* Reference count */
    unsigned int        indexable:1;		/* Object is indexable */
    unsigned int        byte:1;			/* Object is bytes */
    unsigned int        free:1;			/* Object is free */
    unsigned int        ptrs:1;			/* Object has pointers */
} otentry          , *Otentry;

extern Objptr       rootObjects[ROOTSIZE];
extern int          otsize;
extern int          growsize;
extern Otentry      otable;			/* Array of object info */
extern Objhdr	   *objmem;			/* Pointer to objects */
extern int	    noreclaim;

/* object.c */
Objptr              create_new_object(Objptr, int);
int                 new_objectable(int);
void                Set_object(Objptr, int, Objptr);
void                Set_integer(Objptr, int, int);
int                 canbe_integer(int);
int                 length_of(Objptr);
void                set_class_of(Objptr, Objptr);
int                 swapPointers(Objptr, Objptr);
Objptr              initialInstance(Objptr);
Objptr              nextInstance(Objptr);
Objptr              freeOops();
Objptr              usedOops();
Objptr              coreUsed();
Objptr              freeSpace();
int                *create_object(Objptr, int, Objptr, int);
void                rebuild_free();
int                *next_object(Objptr *, int *, Objptr *, int *);
void		    free_all_other_objects(Objptr);
void		    reclaimSpace();


#ifdef INLINE_OBJECT_MEM

/* Is op a object */
#define is_object(op)  (((op) & 1) == 0)
/* Is op a integer */
#define is_integer(op) (((op) & 1) == 1)

#define notFree(op)  (!otable[(op) / 2].free)

/* Check if object is indexable */
#define is_indexable(op) (otable[(op) / 2].indexable)

#define is_byte(op) (otable[(op) / 2].byte)

#define is_word(op) (!otable[(op) / 2].ptrs)

/* Convert value to object */
#define as_object(value) ((value) & (~1))

/* Convert object to integer */
#define as_oop(op) ((op) | 1)

/* Conversion Functions. */

/* Get integer value of object */
#define as_integer(value) ((int)((unsigned int)value) >> 1)

/* Return integer as a object */
#define as_integer_object(value) ((((unsigned int)value) << 1) | 1)

/* Accessing Functions. */

#define get_object_pointer(op) (objmem[(op) / 2])

#define get_object_base(op) ((char *)(get_object_pointer(op) + 1))

#define get_object_refcnt(op) (otable[(op) / 2].refcnt)

#define set_object_pointer(op, addr) (objmem[(op) / 2] = (addr))

#define set_object_refcnt(op,  cnt)  (otable[(op) / 2].refcnt = (cnt))

/* Get value in object */
#define get_pointer(op, offset) (((Objptr *) get_object_base(op))[offset])

#define set_pointer(op, offset, value) \
	 (((Objptr *) get_object_base(op))[(offset)] = (value))

/* Return value of object, but convert it to a native integer. */
#define get_integer(op,  offset) \
		(as_integer(((Objptr *) get_object_base(op))[offset]))

#define get_word(op, offset) (((int *) get_object_base(op))[offset])

#define set_word(op, offset, value) \
			(((int *) get_object_base(op))[offset] = (value))

#define get_byte(op, offset) (0xff&(((char *) get_object_base(op))[offset]))

#define set_byte(op, offset, value) \
	    (((char *) get_object_base(op))[offset] = (value))

/* Get class of object */
#define class_of(op)  \
    ((is_object(op)) ? (get_object_pointer(op)->u.class) : (SmallIntegerClass))

/* Size of an object in bytes. */
#define size_of(op) (get_object_pointer(op)->size)

/*
 * Return fixed size of object in bytes.
 */

#define fixed_size(op) \
    ((class_of(op) == NilPtr)? 0: \
	 (sizeof(Objptr) * (get_integer(class_of(op), CLASS_FLAGS) / 8)))


#define object_incr_ref(op) \
    if (is_object(op)) { \
	int ncnt; \
        if ((ncnt = get_object_refcnt(op)) != MAXREFCNT) \
            set_object_refcnt(op, ncnt + 1); \
    } 

#define object_decr_ref(op) \
    if (is_object(op)) { \
	int ncnt; \
       /* Don't change objects at max count */ \
        if ((ncnt = get_object_refcnt(op)) != MAXREFCNT) { \
           /* If count is zero, remove object */ \
            if (ncnt == 1) \
                free_all_other_objects(op); \
            set_object_refcnt(op, ncnt - 1); \
        } \
    } 

#else

/*
 * Definitions if not done as macros.
 */
int                 is_object(Objptr);
int                 is_integer(Objptr);
int                 is_indexable(Objptr);
int                 is_byte(Objptr);
int                 is_word(Objptr);
int                 notFree(Objptr);
Objptr              as_object(int);
int                 as_oop(Objptr);
int                 as_integer(int);
Objptr              as_integer_object(int);
Objhdr              get_object_pointer(Objptr);
int                 get_word(Objptr, int);
int                 set_word(Objptr, int, int);
int                 get_byte(Objptr, int);
int                 set_byte(Objptr, int, char);
void                set_pointer(Objptr, int, int);
char               *get_object_base(Objptr);
int                 get_object_refcnt(Objptr);
void                set_object_pointer(Objptr, Objhdr);
void                set_object_refcnt(Objptr, int);
Objptr              class_of(Objptr);
int                 size_of(Objptr);
int                 fixed_size(Objptr);
int                 get_integer(Objptr, int);
Objptr              get_pointer(Objptr, int);
void                object_incr_ref(Objptr);
void                object_decr_ref(Objptr);
#endif
